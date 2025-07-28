#!/bin/bash

# Script để package và deploy chaincode lên test network

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "main.go" ]; then
    print_error "Please run this script from the loyalty-chaincode directory"
    exit 1
fi

print_status "Starting chaincode packaging and deployment..."

# Step 1: Build chaincode
print_status "Building chaincode..."
go mod tidy
go build

if [ $? -eq 0 ]; then
    print_status "Chaincode built successfully"
else
    print_error "Failed to build chaincode"
    exit 1
fi

# Step 2: Package chaincode
print_status "Packaging chaincode..."
CHAINCODE_NAME="loyalty"
CHAINCODE_VERSION="1.0"
PACKAGE_FILE="${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz"

# Create package directory structure
mkdir -p /tmp/chaincode-package/src
cp -r . /tmp/chaincode-package/src/
cd /tmp/chaincode-package

# Create connection.json for external chaincode (if needed)
cat > connection.json << EOF
{
  "address": "chaincode:7052",
  "dial_timeout": "10s",
  "tls_required": false
}
EOF

# Create metadata.json
cat > metadata.json << EOF
{
  "type": "golang",
  "label": "${CHAINCODE_NAME}_${CHAINCODE_VERSION}"
}
EOF

# Package the chaincode
tar -czf "${PACKAGE_FILE}" .
mv "${PACKAGE_FILE}" /home/ubuntu/loyalty-project/loyalty-chaincode/

cd /home/ubuntu/loyalty-project/loyalty-chaincode/
rm -rf /tmp/chaincode-package

print_status "Chaincode packaged as ${PACKAGE_FILE}"

# Step 3: Create test script
print_status "Creating test script..."

cat > test_chaincode.sh << 'EOF'
#!/bin/bash

# Test script for loyalty chaincode functions

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test parameters
CHANNEL_NAME="mychannel"
CHAINCODE_NAME="loyalty"
CUSTOMER_ID="CUST001"
CUSTOMER_ID_2="CUST002"

print_test "Testing Customer Creation..."
echo "Creating customer ${CUSTOMER_ID}..."

# Test 1: Create Customer
peer chaincode invoke -o orderer.example.com:7050 \
    --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C $CHANNEL_NAME -n $CHAINCODE_NAME \
    -c '{"function":"CreateCustomer","Args":["'$CUSTOMER_ID'","john_doe","john@example.com","John Doe","+1234567890","2024-01-01","ACTIVE","BRONZE"]}'

if [ $? -eq 0 ]; then
    print_success "Customer created successfully"
else
    print_error "Failed to create customer"
fi

print_test "Testing Account Creation..."
echo "Creating loyalty account for ${CUSTOMER_ID}..."

# Test 2: Create Loyalty Account
peer chaincode invoke -o orderer.example.com:7050 \
    --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C $CHANNEL_NAME -n $CHAINCODE_NAME \
    -c '{"function":"CreateLoyaltyAccount","Args":["'$CUSTOMER_ID'","0"]}'

if [ $? -eq 0 ]; then
    print_success "Loyalty account created successfully"
else
    print_error "Failed to create loyalty account"
fi

print_test "Testing Points Issuance..."
echo "Issuing 1000 points to ${CUSTOMER_ID}..."

# Test 3: Issue Points
peer chaincode invoke -o orderer.example.com:7050 \
    --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C $CHANNEL_NAME -n $CHAINCODE_NAME \
    -c '{"function":"IssuePoints","Args":["'$CUSTOMER_ID'","1000","Welcome bonus","WEB","WEBSITE","SYSTEM","",""]}'

if [ $? -eq 0 ]; then
    print_success "Points issued successfully"
else
    print_error "Failed to issue points"
fi

print_test "Testing Customer Query..."
echo "Querying customer ${CUSTOMER_ID}..."

# Test 4: Query Customer
peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
    -c '{"function":"GetCustomer","Args":["'$CUSTOMER_ID'"]}'

if [ $? -eq 0 ]; then
    print_success "Customer query successful"
else
    print_error "Failed to query customer"
fi

print_test "Testing Account Query..."
echo "Querying loyalty account for ${CUSTOMER_ID}..."

# Test 5: Query Loyalty Account
peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
    -c '{"function":"GetLoyaltyAccount","Args":["'$CUSTOMER_ID'"]}'

if [ $? -eq 0 ]; then
    print_success "Account query successful"
else
    print_error "Failed to query account"
fi

print_test "Testing Transaction History..."
echo "Querying transaction history for ${CUSTOMER_ID}..."

# Test 6: Query Transaction History
peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
    -c '{"function":"GetTransactionHistory","Args":["'$CUSTOMER_ID'","10"]}'

if [ $? -eq 0 ]; then
    print_success "Transaction history query successful"
else
    print_error "Failed to query transaction history"
fi

print_test "Testing Customer Summary..."
echo "Getting customer summary for ${CUSTOMER_ID}..."

# Test 7: Get Customer Summary
peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
    -c '{"function":"GetCustomerSummary","Args":["'$CUSTOMER_ID'"]}'

if [ $? -eq 0 ]; then
    print_success "Customer summary query successful"
else
    print_error "Failed to get customer summary"
fi

echo ""
print_success "All basic tests completed!"
print_test "You can now test advanced features like rewards, transfers, and redemptions"

EOF

chmod +x test_chaincode.sh

print_status "Test script created: test_chaincode.sh"

# Step 4: Create deployment guide
cat > DEPLOYMENT_GUIDE.md << 'EOF'
# Loyalty Chaincode Deployment Guide

## Prerequisites

1. Hyperledger Fabric test network running
2. Peer CLI tools configured
3. Channel created and peers joined

## Deployment Steps

### 1. Start Test Network

```bash
cd /path/to/fabric-samples/test-network
./network.sh up createChannel -ca
```

### 2. Install Chaincode Package

```bash
# Install on peer0.org1
peer lifecycle chaincode install loyalty_1.0.tar.gz

# Install on peer0.org2  
peer lifecycle chaincode install loyalty_1.0.tar.gz

# Get package ID
peer lifecycle chaincode queryinstalled
```

### 3. Approve Chaincode Definition

```bash
# Set package ID (replace with actual package ID)
export PACKAGE_ID=loyalty_1.0:abc123...

# Approve for Org1
peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 \
    --tls --cafile $ORDERER_CA \
    --channelID mychannel --name loyalty --version 1.0 \
    --package-id $PACKAGE_ID --sequence 1

# Approve for Org2 (switch to Org2 peer first)
peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 \
    --tls --cafile $ORDERER_CA \
    --channelID mychannel --name loyalty --version 1.0 \
    --package-id $PACKAGE_ID --sequence 1
```

### 4. Commit Chaincode Definition

```bash
peer lifecycle chaincode commit -o orderer.example.com:7050 \
    --tls --cafile $ORDERER_CA \
    --channelID mychannel --name loyalty --version 1.0 \
    --sequence 1 \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles $PEER0_ORG1_CA \
    --peerAddresses peer0.org2.example.com:9051 \
    --tlsRootCertFiles $PEER0_ORG2_CA
```

### 5. Test Chaincode

```bash
# Run the test script
./test_chaincode.sh
```

## Manual Testing Examples

### Create Customer
```bash
peer chaincode invoke -C mychannel -n loyalty \
    -c '{"function":"CreateCustomer","Args":["CUST001","john_doe","john@example.com","John Doe","+1234567890","2024-01-01","ACTIVE","BRONZE"]}'
```

### Create Account
```bash
peer chaincode invoke -C mychannel -n loyalty \
    -c '{"function":"CreateLoyaltyAccount","Args":["CUST001","0"]}'
```

### Issue Points
```bash
peer chaincode invoke -C mychannel -n loyalty \
    -c '{"function":"IssuePoints","Args":["CUST001","1000","Welcome bonus","WEB","WEBSITE","SYSTEM","",""]}'
```

### Query Customer
```bash
peer chaincode query -C mychannel -n loyalty \
    -c '{"function":"GetCustomer","Args":["CUST001"]}'
```

### Query Account
```bash
peer chaincode query -C mychannel -n loyalty \
    -c '{"function":"GetLoyaltyAccount","Args":["CUST001"]}'
```

## Troubleshooting

1. **Build Errors**: Check Go version compatibility and dependencies
2. **Package Errors**: Ensure all files are included in the package
3. **Deployment Errors**: Verify network is running and configured correctly
4. **Invoke Errors**: Check function names and parameter formats

## Next Steps

1. Test all chaincode functions
2. Integrate with backend API
3. Set up monitoring and logging
4. Configure production deployment
EOF

print_status "Deployment guide created: DEPLOYMENT_GUIDE.md"

print_status "✅ Chaincode packaging complete!"
print_status "Files created:"
print_status "  - ${PACKAGE_FILE} (chaincode package)"
print_status "  - test_chaincode.sh (test script)"
print_status "  - DEPLOYMENT_GUIDE.md (deployment guide)"
print_status ""
print_status "Next steps:"
print_status "1. Deploy to Hyperledger Fabric test network"
print_status "2. Run ./test_chaincode.sh to test functions"
print_status "3. Integrate with backend API"
