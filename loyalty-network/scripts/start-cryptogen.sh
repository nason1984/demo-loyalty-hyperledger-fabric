#!/bin/bash

# ===================================================================================
# Script triển khai mạng Hyperledger Fabric - CRYPTOGEN VERSION
# Sử dụng cryptogen thay vì fabric-ca để tránh lỗi MSP mismatch
# ===================================================================================

set -e

# --- Màu sắc cho output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Biến toàn cục ---
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$BASE_DIR/config"
DOCKER_DIR="$BASE_DIR/docker"
NETWORK_DIR="$BASE_DIR/network"
ORGANIZATIONS_DIR="$NETWORK_DIR/organizations"
CHANNEL_ARTIFACTS_DIR="$NETWORK_DIR/channel-artifacts"
SYSTEM_GENESIS_DIR="$NETWORK_DIR/system-genesis-block"
COMPOSE_FILE="$DOCKER_DIR/docker-compose-cryptogen.yaml"
CHANNEL_NAME="loyaltychannel"

# THÊM CÁC BIẾN SAU:
CRYPTO_CONFIG_DIR="$CONFIG_DIR"
CRYPTO_CONFIG_FILE="$CONFIG_DIR/crypto-config.yaml"
CONFIGTX_FILE="$CONFIG_DIR/configtx.yaml"

# ===================================================================================
# Kiểm tra các file cấu hình
# ===================================================================================
echo -e "${YELLOW}Debug paths:${NC}"
echo "BASE_DIR: $BASE_DIR"
echo "CONFIG_DIR: $CONFIG_DIR"
echo "CRYPTO_CONFIG_DIR: $CRYPTO_CONFIG_DIR"
echo "CRYPTO_CONFIG_FILE: $CRYPTO_CONFIG_FILE"
echo "File exists: $(ls -la "$CRYPTO_CONFIG_FILE" 2>/dev/null || echo "NOT FOUND")"

# ===================================================================================
# FUNCTIONS
# ===================================================================================

function clearNetwork() {
  echo -e "${YELLOW}🔥 Dừng và dọn dẹp mạng...${NC}"
  
  # Dừng tất cả containers
  if [ -f "$COMPOSE_FILE" ]; then
    docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans 2>/dev/null || true
  fi
  
  # Xóa containers thủ công nếu cần
  docker rm -f $(docker ps -aq --filter "name=orderer.loyalty.com|peer0.bank.loyalty.com|peer1.bank.loyalty.com|cli|couchdb0|couchdb1" 2>/dev/null) 2>/dev/null || true
  
  # Xóa networks cũ
  docker network rm loyalty_network 2>/dev/null || true
  docker network rm loyalty-net 2>/dev/null || true
  docker network rm loyalty-cryptogen 2>/dev/null || true
  
  # Xóa volumes
  docker volume rm $(docker volume ls -q --filter "name=orderer.loyalty.com|peer0.bank.loyalty.com|peer1.bank.loyalty.com" 2>/dev/null) 2>/dev/null || true
  
  # Xóa thư mục network
  sudo rm -rf "$NETWORK_DIR" 2>/dev/null || true
  sleep 2
  
  echo -e "${GREEN}✅ Đã dọn dẹp hoàn toàn.${NC}"
}

function createDirectoryStructure() {
  echo -e "${BLUE}📁 Tạo cấu trúc thư mục...${NC}"
  
  mkdir -p "$ORGANIZATIONS_DIR"
  mkdir -p "$CHANNEL_ARTIFACTS_DIR"
  mkdir -p "$SYSTEM_GENESIS_DIR"
  
  echo -e "${GREEN}✅ Cấu trúc thư mục đã được tạo${NC}"
}

function generateCryptoMaterial() {
  echo -e "${BLUE}🔐 Tạo crypto material bằng cryptogen...${NC}"
  
  # Sử dụng absolute path thay vì cd
  cryptogen generate \
    --config="$CRYPTO_CONFIG_DIR/crypto-config.yaml" \
    --output="$ORGANIZATIONS_DIR"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Crypto material đã được tạo thành công${NC}"
  else
    echo -e "${RED}❌ Không thể tạo crypto material${NC}"
    echo -e "${YELLOW}Kiểm tra file config: $CRYPTO_CONFIG_DIR/crypto-config.yaml${NC}"
    exit 1
  fi
  
  # Copy admin certificates vào organization MSP
  echo -e "${YELLOW}📋 Copy admin certificates...${NC}"
  
  # Copy BankOrg admin cert
  cp "$ORGANIZATIONS_DIR/peerOrganizations/bank.loyalty.com/users/Admin@bank.loyalty.com/msp/signcerts/"* \
     "$ORGANIZATIONS_DIR/peerOrganizations/bank.loyalty.com/msp/admincerts/"
  
  # Copy OrdererOrg admin cert
  mkdir -p "$ORGANIZATIONS_DIR/ordererOrganizations/loyalty.com/msp/admincerts"
  cp "$ORGANIZATIONS_DIR/ordererOrganizations/loyalty.com/users/Admin@loyalty.com/msp/signcerts/"* \
     "$ORGANIZATIONS_DIR/ordererOrganizations/loyalty.com/msp/admincerts/"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Admin certificates đã được copy${NC}"
  else
    echo -e "${RED}❌ Không thể copy admin certificates${NC}"
    exit 1
  fi
}

function generateChannelArtifacts() {
  echo -e "${BLUE}📦 Tạo channel artifacts...${NC}"
  
  # Tạo genesis block
  echo -e "${YELLOW}Tạo genesis block...${NC}"
  configtxgen \
    -profile LoyaltyGenesisProfile \
    -channelID system-channel \
    -outputBlock "$SYSTEM_GENESIS_DIR/genesis.block" \
    -configPath "$CONFIG_DIR"
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Không thể tạo genesis block${NC}"
    exit 1
  fi
  
  # Tạo channel transaction
  echo -e "${YELLOW}Tạo channel transaction...${NC}"
  configtxgen \
    -profile LoyaltyChannelProfile \
    -outputCreateChannelTx "$CHANNEL_ARTIFACTS_DIR/${CHANNEL_NAME}.tx" \
    -channelID "$CHANNEL_NAME" \
    -configPath "$CONFIG_DIR"
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Không thể tạo channel transaction${NC}"
    exit 1
  fi
  
  # Tạo anchor peer update
  echo -e "${YELLOW}Tạo anchor peer update...${NC}"
  configtxgen \
    -profile LoyaltyChannelProfile \
    -outputAnchorPeersUpdate "$CHANNEL_ARTIFACTS_DIR/BankOrgMSPanchors.tx" \
    -channelID "$CHANNEL_NAME" \
    -asOrg BankOrg \
    -configPath "$CONFIG_DIR"
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Không thể tạo anchor peer update${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✅ Channel artifacts đã được tạo thành công${NC}"
}

function waitForContainers() {
  echo -e "${YELLOW}⏳ Chờ containers khởi động...${NC}"
  
  local containers=("orderer.loyalty.com" "peer0.bank.loyalty.com" "peer1.bank.loyalty.com" "cli")
  
  for container in "${containers[@]}"; do
    echo -e "${YELLOW}Kiểm tra $container...${NC}"
    
    # Đợi container running và healthy
    for i in {1..60}; do
      if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
        echo -e "${GREEN}✅ $container đang chạy${NC}"
        
        # Đợi thêm để container sẵn sàng
        if [[ "$container" == *"peer"* ]]; then
          echo -e "${YELLOW}Đợi $container sẵn sàng...${NC}"
          sleep 10
        fi
        break
      fi
      echo -n "."
      sleep 3
    done
    
    # Kiểm tra logs cho lỗi
    echo -e "${YELLOW}Kiểm tra logs của $container...${NC}"
    local error_logs=$(docker logs "$container" 2>&1 | grep -i "error\|fatal\|panic" | tail -3)
    if [ -n "$error_logs" ]; then
      echo -e "${RED}❌ $container có lỗi:${NC}"
      echo "$error_logs"
    else
      echo -e "${GREEN}✅ $container logs OK${NC}"
    fi
  done
  
  # Kiểm tra port bằng docker exec và netstat (nếu có)
  echo -e "${YELLOW}Kiểm tra ports...${NC}"
  docker exec peer0.bank.loyalty.com netstat -ln | grep :7051 || echo "Port 7051 không được lắng nghe"
  docker exec orderer.loyalty.com netstat -ln | grep :7050 || echo "Port 7050 không được lắng nghe"
}

function startNetwork() {
  echo -e "${BLUE}🚀 Khởi động mạng...${NC}"
  
  # Khởi động tất cả services cùng lúc
  docker compose -f "$COMPOSE_FILE" up -d
  
  echo -e "${YELLOW}Đợi 60s cho tất cả containers khởi động hoàn toàn...${NC}"
  sleep 60
  
  # Kiểm tra trạng thái containers
  echo -e "${YELLOW}Kiểm tra trạng thái containers...${NC}"
  docker ps --filter "name=orderer.loyalty.com|peer0.bank.loyalty.com|peer1.bank.loyalty.com|cli"
  
  # Kiểm tra logs containers
  local containers=("orderer.loyalty.com" "peer0.bank.loyalty.com" "peer1.bank.loyalty.com")
  for container in "${containers[@]}"; do
    if ! docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
      echo -e "${RED}❌ $container không chạy. Logs:${NC}"
      docker logs "$container" 2>&1 | tail -10
    else
      echo -e "${GREEN}✅ $container đang chạy${NC}"
      # Kiểm tra có lỗi gì trong logs không
      local errors=$(docker logs "$container" 2>&1 | grep -i "fatal\|panic" | tail -3)
      if [ -n "$errors" ]; then
        echo -e "${YELLOW}⚠️ $container có cảnh báo:${NC}"
        echo "$errors"
      fi
    fi
  done
  
  echo -e "${GREEN}✅ Quá trình khởi động hoàn tất${NC}"
}

function createAndJoinChannel() {
  echo -e "${BLUE}🔗 Tạo và tham gia channel...${NC}"
  
  # Tạo channel
  echo -e "${YELLOW}Tạo channel '$CHANNEL_NAME'...${NC}"
  docker exec cli peer channel create \
    -o orderer.loyalty.com:7050 \
    -c "$CHANNEL_NAME" \
    -f "/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.tx" \
    --outputBlock "/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block" \
    --tls \
    --cafile "/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/loyalty.com/orderers/orderer.loyalty.com/tls/ca.crt"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Channel '$CHANNEL_NAME' đã được tạo thành công${NC}"
  else
    echo -e "${RED}❌ Không thể tạo channel${NC}"
    exit 1
  fi
  
  # Join peer0 vào channel
  echo -e "${YELLOW}Tham gia peer0.bank.loyalty.com vào channel...${NC}"
  docker exec \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bank.loyalty.com/users/Admin@bank.loyalty.com/msp \
    -e CORE_PEER_ADDRESS=peer0.bank.loyalty.com:7051 \
    -e CORE_PEER_LOCALMSPID=BankOrgMSP \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bank.loyalty.com/peers/peer0.bank.loyalty.com/tls/ca.crt \
    cli peer channel join \
    -b "/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block" \
    --tls \
    --cafile "/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/loyalty.com/orderers/orderer.loyalty.com/tls/ca.crt"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ peer0.bank.loyalty.com đã tham gia channel thành công${NC}"
  else
    echo -e "${RED}❌ peer0.bank.loyalty.com không thể tham gia channel${NC}"
    exit 1
  fi
  
  # Join peer1 vào channel
  echo -e "${YELLOW}Tham gia peer1.bank.loyalty.com vào channel...${NC}"
  docker exec \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bank.loyalty.com/users/Admin@bank.loyalty.com/msp \
    -e CORE_PEER_ADDRESS=peer1.bank.loyalty.com:8051 \
    -e CORE_PEER_LOCALMSPID=BankOrgMSP \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bank.loyalty.com/peers/peer1.bank.loyalty.com/tls/ca.crt \
    cli peer channel join \
    -b "/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block" \
    --tls \
    --cafile "/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/loyalty.com/orderers/orderer.loyalty.com/tls/ca.crt"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ peer1.bank.loyalty.com đã tham gia channel thành công${NC}"
  else
    echo -e "${RED}❌ peer1.bank.loyalty.com không thể tham gia channel${NC}"
    exit 1
  fi
  
  # Update anchor peers
  echo -e "${YELLOW}Cập nhật anchor peers...${NC}"
  docker exec \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bank.loyalty.com/users/Admin@bank.loyalty.com/msp \
    -e CORE_PEER_ADDRESS=peer0.bank.loyalty.com:7051 \
    -e CORE_PEER_LOCALMSPID=BankOrgMSP \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bank.loyalty.com/peers/peer0.bank.loyalty.com/tls/ca.crt \
    cli peer channel update \
    -o orderer.loyalty.com:7050 \
    -c "$CHANNEL_NAME" \
    -f "/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/BankOrgMSPanchors.tx" \
    --tls \
    --cafile "/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/loyalty.com/orderers/orderer.loyalty.com/tls/ca.crt"
  
  echo -e "${GREEN}✅ Anchor peers đã được cập nhật${NC}"
  echo -e "${GREEN}🎉 Mạng đã được khởi động thành công!${NC}"
}

function deployNetwork() {
  echo -e "${BLUE}🚀 Bắt đầu triển khai mạng Hyperledger Fabric (CRYPTOGEN)...${NC}"
  
  # 1. Tạo cấu trúc thư mục
  createDirectoryStructure
  
  # 2. Tạo crypto material với cryptogen
  generateCryptoMaterial
  
  # 3. Generate channel artifacts
  generateChannelArtifacts
  
  # 4. Start network
  startNetwork
  
  # 5. Create and join channel
  createAndJoinChannel
  
  echo -e "${GREEN}🎉🎉🎉 MẠNG HYPERLEDGER FABRIC ĐÃ ĐƯỢC TRIỂN KHAI THÀNH CÔNG! 🎉🎉🎉${NC}"
  echo -e "${GREEN}Channel: $CHANNEL_NAME${NC}"
  echo -e "${GREEN}Peers đã tham gia: peer0.bank.loyalty.com, peer1.bank.loyalty.com${NC}"
}

function networkStatus() {
  echo -e "${BLUE}📊 Trạng thái mạng...${NC}"
  
  echo -e "${YELLOW}=== CONTAINERS ===${NC}"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=orderer.loyalty.com|peer0.bank.loyalty.com|peer1.bank.loyalty.com|cli|couchdb0|couchdb1"
  
  echo -e "\n${YELLOW}=== CHANNEL INFO ===${NC}"
  if docker exec cli peer channel list &>/dev/null; then
    docker exec cli peer channel list
  else
    echo "Không thể lấy thông tin channel"
  fi
}

# ===================================================================================
# MAIN SCRIPT
# ===================================================================================

case "${1:-}" in
  "up"|"start"|"deploy")
    deployNetwork
    ;;
  "down"|"stop"|"clear")
    clearNetwork
    ;;
  "restart")
    clearNetwork
    sleep 5
    deployNetwork
    ;;
  "status")
    networkStatus
    ;;
  *)
    echo -e "${YELLOW}Cách sử dụng:${NC}"
    echo -e "  ${GREEN}$0 up|start|deploy${NC}  - Triển khai mạng"
    echo -e "  ${GREEN}$0 down|stop|clear${NC}   - Dừng và dọn dẹp mạng"
    echo -e "  ${GREEN}$0 restart${NC}           - Khởi động lại mạng"
    echo -e "  ${GREEN}$0 status${NC}            - Kiểm tra trạng thái mạng"
    exit 1
    ;;
esac