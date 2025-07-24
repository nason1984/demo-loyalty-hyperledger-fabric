# Loyalty Backend API

## Overview
RESTful API server for the Hyperledger Fabric-based Loyalty Points Management System.

## Features
- Create loyalty accounts
- Issue loyalty points (Bank MSP only)
- Redeem loyalty points  
- Transfer points between accounts
- Query account balance
- RESTful API with JSON responses
- Fabric Gateway integration
- CORS support
- Request validation

## API Endpoints

### Health Check
- **GET** `/health` - Health check endpoint

### Account Operations
- **POST** `/api/v1/accounts` - Create a new loyalty account
- **GET** `/api/v1/accounts/:customerID` - Query account balance

### Point Operations  
- **POST** `/api/v1/accounts/:customerID/issue` - Issue points to account
- **POST** `/api/v1/accounts/:customerID/redeem` - Redeem points from account
- **POST** `/api/v1/transfer` - Transfer points between accounts

## Quick Start

### Prerequisites
- Go 1.21+
- Running Hyperledger Fabric network
- Deployed loyalty chaincode

### Environment Variables
```bash
PORT=8080
CHANNEL_NAME=loyaltychannel
CHAINCODE_NAME=loyalty
MSP_ID=BankOrgMSP
PEER_ENDPOINT=localhost:7051
GATEWAY_PEER=peer0.bank.loyalty.com
```

### Installation
```bash
cd loyalty-backend
go mod tidy
go run main.go
```

### Usage Examples

#### Create Account
```bash
curl -X POST http://localhost:8080/api/v1/accounts \
  -H "Content-Type: application/json" \
  -d '{"customerID": "CUST001"}'
```

#### Query Account
```bash
curl http://localhost:8080/api/v1/accounts/CUST001
```

#### Issue Points
```bash
curl -X POST http://localhost:8080/api/v1/accounts/CUST001/issue \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "description": "Welcome bonus"}'
```

#### Redeem Points
```bash
curl -X POST http://localhost:8080/api/v1/accounts/CUST001/redeem \
  -H "Content-Type: application/json" \
  -d '{"amount": 500, "description": "Gift card redemption"}'
```

#### Transfer Points
```bash
curl -X POST http://localhost:8080/api/v1/transfer \
  -H "Content-Type: application/json" \
  -d '{
    "sourceCustomerID": "CUST001",
    "targetCustomerID": "CUST002", 
    "amount": 200,
    "description": "Birthday gift"
  }'
```

## Project Structure
```
loyalty-backend/
├── main.go              # Main application entry point
├── go.mod               # Go module dependencies
├── pkg/
│   ├── config/          # Configuration management
│   ├── fabric/          # Hyperledger Fabric client
│   ├── handlers/        # HTTP request handlers
│   └── models/          # Data models and structures
└── README.md            # This file
```

## Response Format
All API responses follow this standard format:
```json
{
  "success": true|false,
  "message": "Optional message",
  "data": {}, 
  "error": "Error message if success=false"
}
```

## Error Handling
- Input validation with detailed error messages
- Fabric network error propagation
- HTTP status codes following REST conventions
- Structured error responses

## Security
- MSP-based access control for issuing points
- Input validation and sanitization
- CORS configuration
- No authentication (to be added in production)

## Monitoring
- Health check endpoint
- Gin framework logging
- Recovery middleware for panic handling
