#!/bin/bash

# =============================================================================
# LOYALTY BLOCKCHAIN NETWORK MANAGEMENT SCRIPT
# =============================================================================
# Author: AI Assistant
# Description: Comprehensive management script for Loyalty Blockchain Network
# Components: Fabric Network, Chaincode, Explorer, Backend, Frontend
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="/home/ubuntu/loyalty-project"
NETWORK_DIR="$PROJECT_ROOT/loyalty-network"
CHAINCODE_DIR="$PROJECT_ROOT/loyalty-chaincode"
EXPLORER_DIR="$PROJECT_ROOT/blockchain-explorer"

# Functions for colored output
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

# Function to check if a service is running
check_service() {
    local service_name=$1
    local container_pattern=$2
    
    if docker ps | grep -q "$container_pattern"; then
        print_success "$service_name is running"
        return 0
    else
        print_warning "$service_name is not running"
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local check_command=$2
    local max_attempts=${3:-30}
    local sleep_time=${4:-2}
    
    print_step "Waiting for $service_name to be ready..."
    
    for ((i=1; i<=max_attempts; i++)); do
        if eval "$check_command" >/dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        echo -n "."
        sleep $sleep_time
    done
    
    print_error "$service_name failed to start within $((max_attempts * sleep_time)) seconds"
    return 1
}

# Function to start Fabric Network
start_network() {
    print_header "STARTING HYPERLEDGER FABRIC NETWORK"
    
    cd "$NETWORK_DIR"
    
    print_step "Starting Fabric network..."
    if [ -f "scripts/start-cryptogen.sh" ]; then
        ./scripts/start-cryptogen.sh up
    else
        print_error "Network start script not found"
        return 1
    fi
    
    # Wait for containers to be ready
    wait_for_service "Orderer" "docker exec cli peer channel list" 10 3
    wait_for_service "Peer" "docker exec cli peer channel getinfo -c loyaltychannel" 10 3
    
    print_success "Fabric network started successfully"
}

# Function to stop Fabric Network
stop_network() {
    print_header "STOPPING HYPERLEDGER FABRIC NETWORK"
    
    cd "$NETWORK_DIR"
    
    print_step "Stopping Fabric network..."
    if [ -f "scripts/start-cryptogen.sh" ]; then
        ./scripts/start-cryptogen.sh down
    else
        print_warning "Network stop script not found, using docker-compose down"
        docker-compose down
    fi
    
    print_success "Fabric network stopped"
}

# Function to deploy/upgrade chaincode
deploy_chaincode() {
    print_header "DEPLOYING LOYALTY CHAINCODE"
    
    local version=${1:-"1.3"}
    local sequence=${2:-4}
    
    cd "$CHAINCODE_DIR"
    
    print_step "Building chaincode..."
    docker exec cli rm -rf /opt/gopath/src/github.com/loyalty-chaincode
    docker cp . cli:/opt/gopath/src/github.com/loyalty-chaincode/
    
    print_step "Packaging chaincode version $version..."
    docker exec cli sh -c "cd /opt/gopath/src/github.com/loyalty-chaincode && peer lifecycle chaincode package loyalty_$version.tar.gz --path . --lang golang --label loyalty_$version"
    
    print_step "Installing chaincode..."
    local package_id=$(docker exec cli sh -c "cd /opt/gopath/src/github.com/loyalty-chaincode && peer lifecycle chaincode install loyalty_$version.tar.gz" | grep "Chaincode code package identifier:" | cut -d: -f2- | tr -d ' ')
    
    if [ -z "$package_id" ]; then
        print_error "Failed to install chaincode"
        return 1
    fi
    
    print_info "Package ID: $package_id"
    
    print_step "Approving chaincode..."
    docker exec cli peer lifecycle chaincode approveformyorg \
        -o orderer.loyalty.com:7050 \
        --channelID loyaltychannel \
        --name loyalty \
        --version $version \
        --package-id $package_id \
        --sequence $sequence \
        --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/loyalty.com/orderers/orderer.loyalty.com/msp/tlscacerts/tlsca.loyalty.com-cert.pem
    
    print_step "Committing chaincode..."
    docker exec cli peer lifecycle chaincode commit \
        -o orderer.loyalty.com:7050 \
        --channelID loyaltychannel \
        --name loyalty \
        --version $version \
        --sequence $sequence \
        --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/loyalty.com/orderers/orderer.loyalty.com/msp/tlscacerts/tlsca.loyalty.com-cert.pem \
        --peerAddresses peer0.bank.loyalty.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bank.loyalty.com/peers/peer0.bank.loyalty.com/msp/tlscacerts/tlsca.bank.loyalty.com-cert.pem
    
    print_success "Chaincode deployed successfully"
    
    # Test chaincode
    print_step "Testing chaincode..."
    test_chaincode
}

# Function to test chaincode
test_chaincode() {
    print_header "TESTING LOYALTY CHAINCODE"
    
    local test_customer="TEST$(date +%s)"
    
    print_step "Creating test account: $test_customer"
    local result=$(docker exec cli peer chaincode invoke \
        -o orderer.loyalty.com:7050 \
        --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/loyalty.com/orderers/orderer.loyalty.com/msp/tlscacerts/tlsca.loyalty.com-cert.pem \
        -C loyaltychannel \
        -n loyalty \
        --peerAddresses peer0.bank.loyalty.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bank.loyalty.com/peers/peer0.bank.loyalty.com/msp/tlscacerts/tlsca.bank.loyalty.com-cert.pem \
        -c "{\"function\":\"CreateLoyaltyAccount\",\"Args\":[\"$test_customer\"]}")
    
    if echo "$result" | grep -q "Chaincode invoke successful"; then
        print_success "Account creation: PASSED"
    else
        print_error "Account creation: FAILED"
        return 1
    fi
    
    print_step "Querying test account..."
    local query_result=$(docker exec cli peer chaincode query \
        -C loyaltychannel \
        -n loyalty \
        -c "{\"function\":\"QueryLoyaltyAccount\",\"Args\":[\"$test_customer\"]}")
    
    if echo "$query_result" | grep -q "$test_customer"; then
        print_success "Account query: PASSED"
        print_info "Account data: $query_result"
    else
        print_error "Account query: FAILED"
        return 1
    fi
    
    print_success "Chaincode tests completed successfully"
}

# Function to start Explorer
start_explorer() {
    print_header "STARTING HYPERLEDGER EXPLORER"
    
    cd "$EXPLORER_DIR"
    
    print_step "Starting Explorer services..."
    docker-compose up -d
    
    wait_for_service "Explorer DB" "docker exec explorerdb_1 pg_isready -U hppoc" 15 2
    wait_for_service "Explorer" "curl -s http://localhost:8090 > /dev/null" 20 3
    
    print_success "Explorer started successfully"
    print_info "Explorer URL: http://localhost:8090"
    print_info "Username: exploreradmin"
    print_info "Password: exploreradminpw"
}

# Function to stop Explorer
stop_explorer() {
    print_header "STOPPING HYPERLEDGER EXPLORER"
    
    cd "$EXPLORER_DIR"
    docker-compose down
    
    print_success "Explorer stopped"
}

# Function to start backend services
start_backend() {
    print_header "STARTING LOYALTY BACKEND SERVICES"
    
    cd "$PROJECT_ROOT"
    
    print_step "Starting backend and frontend services..."
    docker-compose up -d loyalty_backend loyalty_frontend loyalty_postgres
    
    wait_for_service "PostgreSQL" "docker exec loyalty_postgres pg_isready -U loyalty_user" 10 2
    wait_for_service "Backend API" "curl -s http://localhost:8080/health > /dev/null" 15 3
    wait_for_service "Frontend" "curl -s http://localhost > /dev/null" 10 2
    
    print_success "Backend services started successfully"
    print_info "Frontend URL: http://localhost"
    print_info "Backend API: http://localhost:8080"
}

# Function to stop backend services
stop_backend() {
    print_header "STOPPING LOYALTY BACKEND SERVICES"
    
    cd "$PROJECT_ROOT"
    docker-compose down
    
    print_success "Backend services stopped"
}

# Function to show system status
show_status() {
    print_header "LOYALTY BLOCKCHAIN SYSTEM STATUS"
    
    echo -e "${CYAN}📊 Service Status:${NC}"
    check_service "Fabric Orderer" "orderer.loyalty.com"
    check_service "Fabric Peer0" "peer0.bank.loyalty.com"
    check_service "Fabric Peer1" "peer1.bank.loyalty.com"
    check_service "Loyalty Backend" "loyalty_backend"
    check_service "Loyalty Frontend" "loyalty_frontend"
    check_service "PostgreSQL" "loyalty_postgres"
    check_service "Explorer" "explorer"
    check_service "Explorer DB" "explorerdb"
    
    echo ""
    echo -e "${CYAN}🔗 Network Information:${NC}"
    
    # Check chaincode
    if docker exec cli peer lifecycle chaincode querycommitted -C loyaltychannel 2>/dev/null | grep -q "loyalty"; then
        local chaincode_info=$(docker exec cli peer lifecycle chaincode querycommitted -C loyaltychannel | grep "Name: loyalty")
        print_success "Chaincode: $chaincode_info"
    else
        print_warning "Chaincode: Not deployed"
    fi
    
    # Check channel
    if docker exec cli peer channel getinfo -c loyaltychannel >/dev/null 2>&1; then
        local height=$(docker exec cli peer channel getinfo -c loyaltychannel | grep "Blockchain info" -A 5 | grep "height" | cut -d: -f2 | tr -d ' ')
        print_success "Channel loyaltychannel: Active (Height: $height)"
    else
        print_warning "Channel loyaltychannel: Not accessible"
    fi
    
    echo ""
    echo -e "${CYAN}🌐 Access URLs:${NC}"
    echo -e "Frontend:    ${GREEN}http://localhost${NC}"
    echo -e "Backend API: ${GREEN}http://localhost:8080${NC}"
    echo -e "Explorer:    ${GREEN}http://localhost:8090${NC}"
}

# Function to start everything
start_all() {
    print_header "STARTING COMPLETE LOYALTY BLOCKCHAIN SYSTEM"
    
    print_step "Step 1: Starting Fabric Network..."
    start_network
    
    print_step "Step 2: Starting Backend Services..."
    start_backend
    
    print_step "Step 3: Starting Explorer..."
    start_explorer
    
    print_step "Step 4: Testing Chaincode..."
    test_chaincode
    
    print_success "🎉 Complete system started successfully!"
    show_status
}

# Function to stop everything
stop_all() {
    print_header "STOPPING COMPLETE LOYALTY BLOCKCHAIN SYSTEM"
    
    print_step "Stopping Explorer..."
    stop_explorer
    
    print_step "Stopping Backend Services..."
    stop_backend
    
    print_step "Stopping Fabric Network..."
    stop_network
    
    print_success "Complete system stopped"
}

# Function to restart everything
restart_all() {
    print_header "RESTARTING COMPLETE LOYALTY BLOCKCHAIN SYSTEM"
    
    stop_all
    sleep 5
    start_all
}

# Function to show usage
usage() {
    echo -e "${BLUE}Loyalty Blockchain Network Management Script${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC} $0 [COMMAND] [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  start-all                 Start complete system (network + backend + explorer)"
    echo "  stop-all                  Stop complete system"
    echo "  restart-all               Restart complete system"
    echo "  start-network             Start only Fabric network"
    echo "  stop-network              Stop only Fabric network"
    echo "  start-backend             Start only backend services"
    echo "  stop-backend              Stop only backend services"
    echo "  start-explorer            Start only Hyperledger Explorer"
    echo "  stop-explorer             Stop only Hyperledger Explorer"
    echo "  deploy-chaincode [VER]    Deploy/upgrade chaincode (default version: 1.3)"
    echo "  test-chaincode            Test chaincode functions"
    echo "  status                    Show system status"
    echo "  help                      Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 start-all                    # Start everything"
    echo "  $0 deploy-chaincode 1.4         # Deploy chaincode version 1.4"
    echo "  $0 status                       # Check system status"
}

# Main script logic
case "${1}" in
    "start-all")
        start_all
        ;;
    "stop-all")
        stop_all
        ;;
    "restart-all")
        restart_all
        ;;
    "start-network")
        start_network
        ;;
    "stop-network")
        stop_network
        ;;
    "start-backend")
        start_backend
        ;;
    "stop-backend")
        stop_backend
        ;;
    "start-explorer")
        start_explorer
        ;;
    "stop-explorer")
        stop_explorer
        ;;
    "deploy-chaincode")
        deploy_chaincode "${2}"
        ;;
    "test-chaincode")
        test_chaincode
        ;;
    "status")
        show_status
        ;;
    "help"|"--help"|"-h")
        usage
        ;;
    *)
        print_error "Invalid command: $1"
        echo ""
        usage
        exit 1
        ;;
esac
