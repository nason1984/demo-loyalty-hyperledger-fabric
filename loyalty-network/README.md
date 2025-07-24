# 🏦 Hyperledger Fabric Network - Loyalty Project

[![Hyperledger Fabric](https://img.shields.io/badge/Hyperledger%20Fabric-2.5.5-blue.svg)](https://hyperledger-fabric.readthedocs.io/)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](https://github.com/your-repo/loyalty-project)

> A production-ready Hyperledger Fabric blockchain network implementation for loyalty points management system using cryptogen-based certificate generation.

## 📑 Table of Contents

- [Overview](#-overview)
- [Architecture](#️-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Usage](#-usage)
- [Configuration](#️-configuration)
- [API Reference](#-api-reference)
- [Monitoring](#-monitoring)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

This project implements a **Hyperledger Fabric blockchain network** specifically designed for **loyalty points management systems**. The network enables secure, transparent, and decentralized management of loyalty points across multiple organizations.

### ✨ Key Features

- 🔐 **Secure Certificate Management** - Cryptogen-based PKI infrastructure
- 🏢 **Multi-Organization Support** - Bank and merchant organizations
- 📊 **State Database Options** - CouchDB and LevelDB support
- 🔄 **Automated Deployment** - One-command network setup
- 📈 **Monitoring Ready** - Built-in health checks and logging
- 🐳 **Containerized** - Full Docker containerization
- 🛡️ **TLS Enabled** - End-to-end encryption

### 🎨 Use Cases

- **Loyalty Points Transfer** between banks and merchants
- **Cross-Organization Rewards** program management
- **Transparent Audit Trail** for all transactions
- **Real-time Points Balance** tracking
- **Fraud Prevention** through blockchain immutability

## 🏗️ Architecture

```mermaid
graph TB
    subgraph "Loyalty Fabric Network"
        subgraph "Ordering Service"
            O[Orderer<br/>loyalty.com:7050]
        end
        
        subgraph "Bank Organization"
            P1[Peer0<br/>bank.loyalty.com:7051]
            P2[Peer1<br/>bank.loyalty.com:8051]
            DB1[(CouchDB0<br/>:5984)]
            DB2[(CouchDB1<br/>:7984)]
            P1 --- DB1
            P2 --- DB2
        end
        
        subgraph "Channel: loyaltychannel"
            CH[Channel Configuration]
        end
        
        CLI[CLI Container<br/>Management Interface]
        
        O -.-> P1
        O -.-> P2
        P1 <--> P2
        CLI --> P1
        CLI --> P2
        CLI --> O
        CH --> P1
        CH --> P2
    end
```

### 📋 Network Components

| Component | Container Name | Port | Purpose |
|-----------|---------------|------|---------|
| **Orderer** | `orderer.loyalty.com` | 7050 | Transaction ordering |
| **Peer0** | `peer0.bank.loyalty.com` | 7051 | Primary endorsing peer |
| **Peer1** | `peer1.bank.loyalty.com` | 8051 | Secondary endorsing peer |
| **CouchDB0** | `couchdb0` | 5984 | State database for Peer0 |
| **CouchDB1** | `couchdb1` | 7984 | State database for Peer1 |
| **CLI** | `cli` | - | Network management interface |

### 🏛️ Organizations

- **OrdererOrg** (`OrdererMSP`) - Network ordering service
- **BankOrg** (`BankOrgMSP`) - Banking organization with endorsing peers

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### System Requirements

- **OS**: Ubuntu 20.04+ / macOS 10.15+ / Windows 10 (WSL2)
- **RAM**: Minimum 8GB, Recommended 16GB
- **Storage**: At least 20GB free space
- **Network**: Internet connection for Docker image downloads

### Required Software

| Software | Version | Installation |
|----------|---------|--------------|
| **Docker** | 20.10+ | [Install Docker](https://docs.docker.com/get-docker/) |
| **Docker Compose** | 2.0+ | [Install Compose](https://docs.docker.com/compose/install/) |
| **Node.js** | 16+ | [Install Node.js](https://nodejs.org/) |
| **Git** | 2.25+ | `sudo apt install git` |

### Hyperledger Fabric Binaries

```bash
# Download and install Fabric binaries
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.5 1.5.6

# Add to PATH (add to ~/.bashrc for persistence)
export PATH=$HOME/fabric-samples/bin:$PATH
```

## 🚀 Quick Start

Get your blockchain network up and running in under 5 minutes:

```bash
# 1. Clone the repository
git clone https://github.com/your-username/loyalty-project.git
cd loyalty-project/loyalty-network

# 2. Make script executable
chmod +x scripts/start-cryptogen.sh

# 3. Deploy the complete network
./scripts/start-cryptogen.sh deploy

# 4. Verify deployment
./scripts/start-cryptogen.sh status
```

**Expected Output:**
```
🎉🎉🎉 MẠNG HYPERLEDGER FABRIC ĐÃ ĐƯỢC TRIỂN KHAI THÀNH CÔNG! 🎉🎉🎉
Channel: loyaltychannel
Peers đã tham gia: peer0.bank.loyalty.com, peer1.bank.loyalty.com
```

## 💾 Installation

### Step-by-Step Installation

#### 1. **Environment Setup**

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required dependencies
sudo apt install -y curl wget git build-essential

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### 2. **Download Fabric Tools**

```bash
# Create workspace
mkdir -p ~/blockchain/loyalty-project
cd ~/blockchain/loyalty-project

# Download Hyperledger Fabric
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.5 1.5.6

# Set environment variables
echo 'export PATH=$HOME/blockchain/loyalty-project/fabric-samples/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

#### 3. **Clone and Setup Project**

```bash
# Clone repository
git clone https://github.com/your-username/loyalty-project.git
cd loyalty-project/loyalty-network

# Verify structure
tree -L 3
```

#### 4. **Verify Installation**

```bash
# Check Docker
docker --version
docker-compose --version

# Check Fabric tools
cryptogen version
configtxgen --version
peer version
```

## 🎯 Usage

### Available Commands

The `start-cryptogen.sh` script provides comprehensive network management:

```bash
# Network Lifecycle Management
./scripts/start-cryptogen.sh deploy    # Full deployment from scratch
./scripts/start-cryptogen.sh up       # Start existing network
./scripts/start-cryptogen.sh down     # Stop network (preserve data)
./scripts/start-cryptogen.sh restart  # Restart network
./scripts/start-cryptogen.sh clear    # Complete cleanup
./scripts/start-cryptogen.sh status   # Check network status
```

### Detailed Usage Examples

#### 🔧 **Network Management**

```bash
# Start fresh deployment
./scripts/start-cryptogen.sh deploy

# Check if all containers are running
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View network logs
docker logs peer0.bank.loyalty.com --tail 50
```

#### 📊 **Channel Operations**

```bash
# Access CLI container
docker exec -it cli bash

# List joined channels
peer channel list

# Get channel information
peer channel getinfo -c loyaltychannel

# Query channel block
peer channel fetch config config_block.pb -o orderer.loyalty.com:7050 -c loyaltychannel --tls
```

#### 🔍 **Network Inspection**

```bash
# Check network connectivity
docker network inspect loyalty-cryptogen

# Verify peer endpoints
docker exec cli peer node status

# Test peer communication
docker exec cli peer channel fetch newest -c loyaltychannel
```

### Interactive CLI

```bash
# Enter CLI container
docker exec -it cli bash

# Set peer environment for peer0
export CORE_PEER_ADDRESS=peer0.bank.loyalty.com:7051
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bank.loyalty.com/users/Admin@bank.loyalty.com/msp

# Set peer environment for peer1
export CORE_PEER_ADDRESS=peer1.bank.loyalty.com:8051

# Execute peer commands
peer channel list
peer lifecycle chaincode queryinstalled
```

## ⚙️ Configuration

### Project Structure

```
loyalty-network/
├── 📁 config/
│   ├── 📄 configtx.yaml           # Channel & network configuration
│   └── 📄 crypto-config.yaml      # Certificate generation config
├── 📁 docker/
│   └── 📄 docker-compose-cryptogen.yaml  # Container orchestration
├── 📁 scripts/
│   └── 📄 start-cryptogen.sh      # Main deployment script
├── 📁 network/                    # Generated artifacts (auto-created)
│   ├── 📁 organizations/          # MSP certificates & keys
│   ├── 📁 channel-artifacts/      # Channel configuration files
│   └── 📁 system-genesis-block/   # Genesis block
└── 📄 README.md
```

### Key Configuration Files

#### `configtx.yaml` - Network Topology

```yaml
Organizations:
  - &OrdererOrg
    Name: OrdererOrg
    ID: OrdererMSP
    MSPDir: ../network/organizations/ordererOrganizations/loyalty.com/msp
    
  - &BankOrg
    Name: BankOrg
    ID: BankOrgMSP
    MSPDir: ../network/organizations/peerOrganizations/bank.loyalty.com/msp
    AnchorPeers:
      - Host: peer0.bank.loyalty.com
        Port: 7051

Profiles:
  LoyaltyGenesisProfile:    # Genesis block profile
  LoyaltyChannelProfile:    # Application channel profile
```

#### `crypto-config.yaml` - Certificate Generation

```yaml
OrdererOrgs:
  - Name: Orderer
    Domain: loyalty.com
    Specs:
      - Hostname: orderer

PeerOrgs:
  - Name: Bank
    Domain: bank.loyalty.com
    EnableNodeOUs: true
    Template:
      Count: 2    # Creates peer0 and peer1
    Users:
      Count: 1    # Creates User1
```

### Environment Variables

#### Docker Compose Configuration

```yaml
# Peer Environment Variables
environment:
  - FABRIC_LOGGING_SPEC=INFO
  - CORE_PEER_TLS_ENABLED=true
  - CORE_PEER_LOCALMSPID=BankOrgMSP
  - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
  - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb0:5984
  - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
  - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpw
```

#### CLI Environment Variables

```bash
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=BankOrgMSP
export CORE_PEER_TLS_ROOTCERT_FILE=/path/to/ca.crt
export CORE_PEER_MSPCONFIGPATH=/path/to/admin/msp
export CORE_PEER_ADDRESS=peer0.bank.loyalty.com:7051
```

### Customization Options

#### Database Backend

Switch between CouchDB and LevelDB:

```yaml
# For CouchDB (rich queries, JSON)
- CORE_LEDGER_STATE_STATEDATABASE=CouchDB
- CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb0:5984

# For LevelDB (simple key-value, faster)
# Comment out CouchDB variables (LevelDB is default)
```

#### Logging Levels

```yaml
# Available levels: CRITICAL, ERROR, WARNING, NOTICE, INFO, DEBUG
- FABRIC_LOGGING_SPEC=INFO                    # Global level
- FABRIC_LOGGING_SPEC=INFO:gossip=WARNING    # Module-specific
- FABRIC_LOGGING_SPEC=DEBUG                  # Debug mode
```

## 📚 API Reference

### Network Management API

| Command | Description | Usage |
|---------|-------------|-------|
| `deploy` | Full network deployment | `./scripts/start-cryptogen.sh deploy` |
| `up` | Start existing network | `./scripts/start-cryptogen.sh up` |
| `down` | Stop network | `./scripts/start-cryptogen.sh down` |
| `restart` | Restart network | `./scripts/start-cryptogen.sh restart` |
| `clear` | Complete cleanup | `./scripts/start-cryptogen.sh clear` |
| `status` | Network status | `./scripts/start-cryptogen.sh status` |

### Peer CLI Commands

#### Channel Operations

```bash
# Create channel
peer channel create -o orderer:7050 -c mychannel -f channel.tx --tls

# Join channel
peer channel join -b mychannel.block --tls

# List channels
peer channel list

# Get channel info
peer channel getinfo -c mychannel
```

#### Chaincode Lifecycle

```bash
# Package chaincode
peer lifecycle chaincode package cc.tar.gz --path /path/to/chaincode --lang node --label mycc_1.0

# Install chaincode
peer lifecycle chaincode install cc.tar.gz

# Query installed chaincodes
peer lifecycle chaincode queryinstalled

# Approve chaincode
peer lifecycle chaincode approveformyorg --channelID mychannel --name mycc --version 1.0 --package-id package_id --sequence 1

# Commit chaincode
peer lifecycle chaincode commit --channelID mychannel --name mycc --version 1.0 --sequence 1
```

### REST API Endpoints (Future Implementation)

```typescript
// Planned REST API endpoints
POST   /api/v1/loyalty/transfer     // Transfer loyalty points
GET    /api/v1/loyalty/balance/:id  // Get user balance  
POST   /api/v1/loyalty/redeem       // Redeem points
GET    /api/v1/loyalty/history/:id  // Transaction history
GET    /api/v1/network/status       // Network health
```

## 📊 Monitoring

### Health Checks

#### Container Health Status

```bash
# Check all containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Health check for specific container
docker inspect --format='{{.State.Health.Status}}' peer0.bank.loyalty.com

# View container resource usage
docker stats
```

#### Network Connectivity

```bash
# Test peer connectivity
docker exec cli peer node status

# Test orderer connectivity
docker exec cli peer channel fetch config -o orderer.loyalty.com:7050 -c loyaltychannel --tls

# Check gossip network
docker exec peer0.bank.loyalty.com peer node status
```

### Logging

#### Container Logs

```bash
# View real-time logs
docker logs -f peer0.bank.loyalty.com

# Get last 100 lines
docker logs --tail 100 orderer.loyalty.com

# Filter by time
docker logs --since="2025-07-23T10:00:00" peer1.bank.loyalty.com
```

#### Log Analysis

```bash
# Check for errors
docker logs peer0.bank.loyalty.com 2>&1 | grep -i error

# Monitor transaction processing
docker logs orderer.loyalty.com 2>&1 | grep -i "Ordering Service"

# Watch gossip messages
docker logs peer0.bank.loyalty.com 2>&1 | grep -i gossip
```

### Performance Metrics

#### System Resources

```bash
# Container resource usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Disk usage
docker system df

# Network usage
docker exec cli netstat -i
```

#### Blockchain Metrics

```bash
# Block height
docker exec cli peer channel getinfo -c loyaltychannel

# Chaincode operations
docker exec cli peer lifecycle chaincode queryinstalled

# Transaction throughput (requires monitoring setup)
# Prometheus metrics available on :9443 endpoints
```

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 🔥 **Container Startup Failures**

**Problem**: Containers exit immediately after startup

```bash
# Diagnosis
docker ps -a  # Check exit codes
docker logs <container_name>  # Check error messages

# Common solutions
./scripts/start-cryptogen.sh clear  # Clean restart
docker system prune -f  # Clean Docker cache
```

**Specific Issues**:

- **Exit Code 125**: Configuration error → Check docker-compose.yaml
- **Exit Code 1**: Application error → Check container logs
- **Exit Code 2**: Misuse of shell builtin → Check script syntax

#### 🔐 **Certificate/MSP Issues**

**Problem**: "creator org unknown" or MSP validation errors

```bash
# Check MSP structure
find network/organizations/ -name "admincerts" -exec ls -la {} \;

# Verify admin certificates exist
ls -la network/organizations/peerOrganizations/bank.loyalty.com/msp/admincerts/

# Solution: Regenerate certificates
./scripts/start-cryptogen.sh clear
./scripts/start-cryptogen.sh deploy
```

#### 🌐 **Network Connectivity Issues**

**Problem**: Peers cannot communicate or join channel fails

```bash
# Check Docker network
docker network inspect loyalty-cryptogen

# Test container connectivity
docker exec cli ping peer0.bank.loyalty.com

# Check port accessibility
docker exec cli nc -z peer0.bank.loyalty.com 7051

# Solution: Restart network services
docker-compose -f docker/docker-compose-cryptogen.yaml restart
```

#### 💾 **Database Connection Issues**

**Problem**: CouchDB connection failures

```bash
# Check CouchDB health
docker exec couchdb0 curl -f http://admin:adminpw@localhost:5984/

# Check CouchDB logs
docker logs couchdb0

# Solution: Use LevelDB (comment out CouchDB sections)
# Or fix CouchDB credentials in docker-compose.yaml
```

#### 📦 **Channel Creation/Join Issues**

**Problem**: Channel operations fail

```bash
# Check channel artifacts
ls -la network/channel-artifacts/

# Verify genesis block
file network/system-genesis-block/genesis.block

# Regenerate channel artifacts
cd config
configtxgen -profile LoyaltyChannelProfile -outputCreateChannelTx ../network/channel-artifacts/loyaltychannel.tx -channelID loyaltychannel
```

### Debug Mode

Enable detailed logging for troubleshooting:

```bash
# Set debug environment
export FABRIC_LOGGING_SPEC=DEBUG

# Enable debug in docker-compose
environment:
  - FABRIC_LOGGING_SPEC=DEBUG

# View debug logs
docker logs peer0.bank.loyalty.com 2>&1 | grep DEBUG
```

### Recovery Procedures

#### Complete Network Reset

```bash
# Nuclear option - complete cleanup and restart
./scripts/start-cryptogen.sh clear
docker system prune -af
docker volume prune -f
./scripts/start-cryptogen.sh deploy
```

#### Partial Recovery

```bash
# Restart just the containers (preserve crypto materials)
docker-compose -f docker/docker-compose-cryptogen.yaml down
docker-compose -f docker/docker-compose-cryptogen.yaml up -d

# Recreate channel only
docker exec cli peer channel create -o orderer.loyalty.com:7050 -c loyaltychannel -f channel-artifacts/loyaltychannel.tx --tls
```

### Getting Help

If you encounter issues not covered here:

1. **Check logs** first: `docker logs <container_name>`
2. **Search issues**: [GitHub Issues](https://github.com/your-repo/issues)
3. **Community support**: [Hyperledger Discord](https://discord.gg/hyperledger)
4. **Documentation**: [Fabric Docs](https://hyperledger-fabric.readthedocs.io/)

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### Development Setup

```bash
# Fork and clone
git clone https://github.com/your-username/loyalty-project.git
cd loyalty-project

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and test
./loyalty-network/scripts/start-cryptogen.sh deploy

# Commit with conventional commits
git commit -m "feat: add new network configuration"

# Push and create PR
git push origin feature/your-feature-name
```

### Contribution Guidelines

#### 📝 **Code Standards**

- **Shell Scripts**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **YAML Files**: Use 2-space indentation
- **Documentation**: Update README.md for any configuration changes
- **Testing**: Ensure deployment scripts work on clean environment

#### 🧪 **Testing Requirements**

```bash
# Test deployment from scratch
./scripts/start-cryptogen.sh clear
./scripts/start-cryptogen.sh deploy

# Verify all containers start
docker ps --filter "name=loyalty|orderer|peer|cli"

# Test channel operations
docker exec cli peer channel list
```

#### 📋 **Pull Request Process**

1. **Description**: Clearly describe what your PR does
2. **Testing**: Include testing steps and results
3. **Documentation**: Update relevant documentation
4. **Review**: Address all review comments
5. **Merge**: Squash commits when merging

### Types of Contributions

- 🐛 **Bug fixes**
- ✨ **New features**
- 📚 **Documentation improvements**
- 🏗️ **Infrastructure enhancements**
- 🧪 **Testing improvements**
- 🔧 **Configuration optimizations**

## 🛡️ Security

### Security Considerations

- **Private Keys**: Never commit private keys to repository
- **Passwords**: Use environment variables for sensitive data
- **TLS**: All network communication is TLS-encrypted
- **MSP**: Proper certificate validation and access controls
- **Updates**: Keep Fabric version updated for security patches

### Reporting Security Issues

Please report security vulnerabilities to: security@your-domain.com

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 Loyalty Project Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

## 🙏 Acknowledgments

- **Hyperledger Fabric Community** for the excellent blockchain framework
- **Linux Foundation** for supporting open-source blockchain development
- **Docker Team** for containerization technology
- **Contributors** who have helped improve this project

## 📞 Contact & Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/your-repo/issues)
- **Discussions**: [Community discussions](https://github.com/your-repo/discussions)
- **Email**: loyalty-project@your-domain.com
- **Discord**: [Join our community](https://discord.gg/your-discord)

---

<div align="center">

**⭐ If this project helps you, please give it a star! ⭐**

Made with ❤️ by the Loyalty Project Team

[🔝 Back to top](#-hyperledger-fabric-network---loyalty-project)

</div>
