# Loyalty System Chaincode

## Overview

This chaincode implements a comprehensive loyalty points system on Hyperledger Fabric. It supports customer management, points earning/redemption, transfers between customers, reward management, and detailed transaction tracking.

## Features

### Core Functions
- **Customer Management**: Create and manage customer profiles
- **Loyalty Accounts**: Track points balance, lifetime earned/redeemed
- **Points Operations**: Issue, redeem, and transfer points
- **Reward System**: Create and manage rewards catalog
- **Transaction History**: Complete audit trail of all operations

### Advanced Features
- **Tier-based Benefits**: Bronze, Silver, Gold, Platinum tiers with different benefits
- **Transfer Limits**: Tier-based daily transfer limits and fees
- **Reward Restrictions**: Tier-based reward access
- **Business Rules**: Configurable system parameters
- **Statistics**: Customer analytics and ranking systems

## Data Models

### Customer
- Customer profile information
- Tier status and registration details
- Metadata support for extensibility

### LoyaltyAccount
- Points balance and lifetime statistics
- Account status and activity tracking
- Tier-based configuration

### Transaction
- Complete transaction history
- Type-based categorization
- Reference linking between related transactions

### Reward
- Reward catalog with points cost
- Quantity and validity management
- Tier-based access control

### PointTransfer
- Peer-to-peer points transfers
- Fee calculation based on tier
- Transfer status tracking

### Redemption
- Points-to-rewards exchange
- Inventory management
- Redemption history

## API Functions

### Customer Management
```go
CreateCustomer(customerID, firstName, lastName, email, phone, tier, status)
GetCustomer(customerID)
UpdateCustomer(customerID, data)
```

### Account Management
```go
CreateLoyaltyAccount(customerID, initialBalance)
GetLoyaltyAccount(customerID)
```

### Points Operations
```go
IssuePoints(customerID, amount, reason, channel, location, employeeID)
RedeemPoints(customerID, rewardID, quantity, channel, location, employeeID)
TransferPoints(fromCustomerID, toCustomerID, amount, message, channel, location, employeeID)
```

### Reward Management
```go
CreateReward(rewardID, name, description, category, pointsCost, cashValue, quantity, validFrom, validTo, tierRestriction)
GetReward(rewardID)
GetAvailableRewards(customerID)
```

### Transaction History
```go
GetTransactionHistory(customerID, limit)
GetCustomerSummary(customerID)
```

### Analytics
```go
GetCustomerStatistics(customerID, days)
GetTopCustomers(criteria, limit)
GetRedemptionHistory(customerID, limit)
GetTransferHistory(customerID, limit)
```

## Business Rules

### Tier System
- **Bronze**: 1x points multiplier, 1000 transfer limit, 5% transfer fee
- **Silver**: 1.2x points multiplier, 2000 transfer limit, 2% transfer fee  
- **Gold**: 1.5x points multiplier, 5000 transfer limit, no transfer fee
- **Platinum**: 2x points multiplier, 10000 transfer limit, no transfer fee

### Tier Advancement
- **Silver**: 10,000+ lifetime points
- **Gold**: 25,000+ lifetime points  
- **Platinum**: 50,000+ lifetime points

### Transfer Rules
- Minimum transfer: 10 points
- Maximum transfer: 10,000 points
- Daily limits based on sender's tier
- Fees calculated based on sender's tier
- Cannot transfer to same customer

### Redemption Rules
- Minimum redemption: 50 points
- Tier-based reward access
- Inventory tracking for limited rewards
- Validity date enforcement

## Installation

1. Copy chaincode files to your Hyperledger Fabric network
2. Package and install the chaincode on peer nodes
3. Instantiate/deploy chaincode on channels
4. Invoke functions through client applications

## Usage Examples

### Create Customer and Account
```bash
# Create customer
peer chaincode invoke -C mychannel -n loyalty \
  -c '{"function":"CreateCustomer","Args":["CUST001","John","Doe","john@example.com","+1234567890","BRONZE","ACTIVE"]}'

# Create loyalty account
peer chaincode invoke -C mychannel -n loyalty \
  -c '{"function":"CreateLoyaltyAccount","Args":["CUST001","0"]}'
```

### Issue Points
```bash
peer chaincode invoke -C mychannel -n loyalty \
  -c '{"function":"IssuePoints","Args":["CUST001","1000","Purchase reward","ONLINE","WEBSITE","EMP001"]}'
```

### Create and Redeem Reward
```bash
# Create reward
peer chaincode invoke -C mychannel -n loyalty \
  -c '{"function":"CreateReward","Args":["RWD001","Coffee Cup","Free coffee","BEVERAGE","500","5.00","100","","",""]}'

# Redeem reward
peer chaincode invoke -C mychannel -n loyalty \
  -c '{"function":"RedeemPoints","Args":["CUST001","RWD001","1","STORE","BRANCH001","EMP001"]}'
```

### Transfer Points
```bash
peer chaincode invoke -C mychannel -n loyalty \
  -c '{"function":"TransferPoints","Args":["CUST001","CUST002","500","Birthday gift","MOBILE","APP",""]}'
```

### Query Functions
```bash
# Get customer details
peer chaincode query -C mychannel -n loyalty \
  -c '{"function":"GetCustomer","Args":["CUST001"]}'

# Get transaction history
peer chaincode query -C mychannel -n loyalty \
  -c '{"function":"GetTransactionHistory","Args":["CUST001","50"]}'

# Get customer statistics
peer chaincode query -C mychannel -n loyalty \
  -c '{"function":"GetCustomerStatistics","Args":["CUST001","30"]}'
```

## Configuration

The chaincode includes configurable business rules in `utilities.go`:

- Points earning rates
- Tier thresholds and benefits
- Transfer limits and fees
- Minimum/maximum transaction amounts
- Expiry and inactivity periods

## Security Considerations

- All state changes are recorded on the blockchain
- Transaction history provides complete audit trail
- Access control should be implemented at the application layer
- Sensitive customer data should be encrypted if required
- Consider using private data collections for confidential information

## Error Handling

The chaincode includes comprehensive error handling for:
- Invalid input parameters
- Insufficient balances
- Business rule violations
- Data validation failures
- Constraint violations

## Events

The chaincode emits events for major operations:
- `CustomerCreated`
- `PointsIssued`
- `PointsRedeemed`
- `PointsTransferred`
- `RewardCreated`

These events can be consumed by client applications for real-time notifications and integration.

## Testing

Use the Hyperledger Fabric test network to:
1. Deploy chaincode in development environment
2. Test all API functions with various scenarios
3. Validate business rules and constraints
4. Performance testing with large datasets
5. Integration testing with client applications

## Future Enhancements

Potential improvements:
- Multi-currency support
- Scheduled/recurring rewards
- Customer segmentation and targeting
- Integration with external payment systems
- Machine learning for fraud detection
- Mobile SDK for direct blockchain access
