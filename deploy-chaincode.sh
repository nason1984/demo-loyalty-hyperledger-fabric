#!/bin/bash

# =============================================================================
# CHAINCODE DEPLOYMENT SCRIPT
# =============================================================================
# Description: Automated chaincode deployment for loyalty system
# Author: AI Assistant
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CHAINCODE_NAME="loyalty"
CHAINCODE_VERSION="${1:-1.3}"
CHAINCODE_SEQUENCE="${2:-1}"
CHANNEL_NAME="loyaltychannel"
CHAINCODE_DIR="/home/ubuntu/loyalty-project/loyalty-chaincode"
ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/loyalty.com/orderers/orderer.loyalty.com/msp/tlscacerts/tlsca.loyalty.com-cert.pem"

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
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Wait for service to be ready
wait_for_service() {
    local service_name=$1
    local test_command=$2
    local max_wait=${3:-30}
    local interval=${4:-2}
    
    print_info "Waiting for $service_name to be ready..."
    local count=0
    while [ $count -lt $max_wait ]; do
        if eval "$test_command" >/dev/null 2>&1; then
            print_success "$service_name is ready"
            return 0
        fi
        sleep $interval
        count=$((count + 1))
        echo -n "."
    done
    print_error "$service_name failed to start within $((max_wait * interval)) seconds"
    return 1
}

# Check if fabric network is running
check_network() {
    print_info "Checking Fabric network status..."
    
    if ! docker ps | grep -q "cli"; then
        print_error "CLI container not running. Please start the Fabric network first."
        exit 1
    fi
    
    if ! docker exec cli peer channel list 2>/dev/null | grep -q "$CHANNEL_NAME"; then
        print_error "Channel $CHANNEL_NAME not found. Please check network setup."
        exit 1
    fi
    
    print_success "Fabric network is running"
}

# Package chaincode
package_chaincode() {
    print_header "PACKAGING CHAINCODE"
    
    print_info "Packaging chaincode $CHAINCODE_NAME version $CHAINCODE_VERSION..."
    
    # Copy chaincode to CLI container
    docker cp "$CHAINCODE_DIR" cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode/
    
    docker exec cli peer lifecycle chaincode package ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz \
        --path /opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode/ \
        --lang golang \
        --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}
    
    if [ $? -eq 0 ]; then
        print_success "Chaincode packaged successfully"
    else
        print_error "Failed to package chaincode"
        exit 1
    fi
}

# Install chaincode
install_chaincode() {
    print_header "INSTALLING CHAINCODE"
    
    print_info "Installing chaincode on peer..."
    
    docker exec cli peer lifecycle chaincode install ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz
    
    if [ $? -eq 0 ]; then
        print_success "Chaincode installed successfully"
    else
        print_error "Failed to install chaincode"
        exit 1
    fi
}

# Get package ID
get_package_id() {
    print_info "Getting package ID..."
    
    PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled --output json | jq -r ".installed_chaincodes[] | select(.label==\"${CHAINCODE_NAME}_${CHAINCODE_VERSION}\") | .package_id")
    
    if [ -z "$PACKAGE_ID" ]; then
        print_error "Failed to get package ID"
        exit 1
    fi
    
    print_success "Package ID: $PACKAGE_ID"
}

# Approve chaincode
approve_chaincode() {
    print_header "APPROVING CHAINCODE"
    
    print_info "Approving chaincode for org..."
    
    docker exec cli peer lifecycle chaincode approveformyorg \
        --tls \
        --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --sequence $CHAINCODE_SEQUENCE \
        --package-id $PACKAGE_ID
    
    if [ $? -eq 0 ]; then
        print_success "Chaincode approved successfully"
    else
        print_error "Failed to approve chaincode"
        exit 1
    fi
}

# Commit chaincode
commit_chaincode() {
    print_header "COMMITTING CHAINCODE"
    
    print_info "Committing chaincode to channel..."
    
    docker exec cli peer lifecycle chaincode commit \
        --tls \
        --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --sequence $CHAINCODE_SEQUENCE
    
    if [ $? -eq 0 ]; then
        print_success "Chaincode committed successfully"
    else
        print_error "Failed to commit chaincode"
        exit 1
    fi
}

# Test chaincode
test_chaincode() {
    print_header "TESTING CHAINCODE"
    
    print_info "Testing chaincode with sample transaction..."
    
    # Test creating loyalty account
    TEST_CUSTOMER="test_$(date +%s)"
    docker exec cli peer chaincode invoke \
        --tls \
        --cafile $ORDERER_CA \
        -C $CHANNEL_NAME \
        -n $CHAINCODE_NAME \
        -c "{\"function\":\"CreateLoyaltyAccount\",\"Args\":[\"$TEST_CUSTOMER\"]}"
    
    if [ $? -eq 0 ]; then
        print_success "Chaincode test successful"
        
        # Query the account
        print_info "Querying test account..."
        docker exec cli peer chaincode query \
            -C $CHANNEL_NAME \
            -n $CHAINCODE_NAME \
            -c "{\"function\":\"QueryLoyaltyAccount\",\"Args\":[\"$TEST_CUSTOMER\"]}"
    else
        print_error "Chaincode test failed"
        exit 1
    fi
}

# Check if chaincode already exists
check_existing_chaincode() {
    print_info "Checking if chaincode is already deployed..."
    
    if docker exec cli peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME 2>/dev/null; then
        print_warning "Chaincode $CHAINCODE_NAME is already deployed"
        read -p "Do you want to upgrade? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deployment cancelled"
            exit 0
        fi
        # Increment sequence for upgrade
        CHAINCODE_SEQUENCE=$((CHAINCODE_SEQUENCE + 1))
        print_info "Using sequence $CHAINCODE_SEQUENCE for upgrade"
    fi
}

# Main deployment function
main() {
    print_header "LOYALTY CHAINCODE DEPLOYMENT"
    print_info "Chaincode: $CHAINCODE_NAME"
    print_info "Version: $CHAINCODE_VERSION"
    print_info "Sequence: $CHAINCODE_SEQUENCE"
    print_info "Channel: $CHANNEL_NAME"
    
    check_network
    check_existing_chaincode
    package_chaincode
    install_chaincode
    get_package_id
    approve_chaincode
    commit_chaincode
    test_chaincode
    
    print_header "DEPLOYMENT COMPLETED SUCCESSFULLY"
    print_success "Chaincode $CHAINCODE_NAME v$CHAINCODE_VERSION is now deployed and ready to use!"
}

# Script usage
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [VERSION] [SEQUENCE]"
    echo "  VERSION:  Chaincode version (default: 1.3)"
    echo "  SEQUENCE: Chaincode sequence (default: 1)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy version 1.3, sequence 1"
    echo "  $0 1.4                # Deploy version 1.4, sequence 1"  
    echo "  $0 1.4 2              # Deploy version 1.4, sequence 2"
    exit 0
fi

# Run main function
main
