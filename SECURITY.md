# 🔐 SECURITY NOTICE

## ⚠️ IMPORTANT SECURITY INFORMATION

**This repository does NOT contain private keys or certificates for security reasons.**

All cryptographic materials (private keys, certificates, MSP materials) are:
- **Generated locally** during network startup
- **Never committed** to version control
- **Automatically regenerated** each time you start the network

## 🚀 How to Generate Crypto Materials

### Automatic Generation (Recommended)
```bash
# Start the complete system - this will auto-generate all crypto materials
./manage-loyalty-system.sh start-all
```

### Manual Generation
```bash
# Start only the Fabric network to generate crypto materials
./manage-loyalty-system.sh start-network

# Or use the network scripts directly
cd loyalty-network
./scripts/start-cryptogen.sh up
```

## 📁 Generated Files Location

After running the network, crypto materials will be generated in:
```
loyalty-network/network/organizations/
├── ordererOrganizations/
└── peerOrganizations/
    └── bank.loyalty.com/
        ├── ca/                    # Certificate Authority files
        ├── msp/                   # Membership Service Provider
        ├── peers/                 # Peer certificates
        ├── tlsca/                 # TLS Certificate Authority
        └── users/                 # User certificates
```

## 🛡️ Security Best Practices

1. **Never commit private keys** (*.key, priv_sk, *private*)
2. **Keep certificates local** - they're auto-generated
3. **Regenerate crypto materials** if compromised
4. **Use different keys** for production environments
5. **Monitor .gitignore** to ensure sensitive files are excluded

## 🔄 Regenerating Crypto Materials

If you need to regenerate all crypto materials:

```bash
# Stop the network
./manage-loyalty-system.sh stop-network

# Clean up existing materials
rm -rf loyalty-network/network/organizations/
rm -rf loyalty-network/network/channel-artifacts/
rm -rf loyalty-network/network/system-genesis-block/

# Start fresh
./manage-loyalty-system.sh start-all
```

## 📞 Support

If you encounter issues with crypto material generation:
1. Check that Docker is running
2. Ensure network ports are available
3. Run `./manage-loyalty-system.sh status` to check system state
4. Review logs with `docker logs <container-name>`

---
**🔒 Remember: Security is everyone's responsibility!**
