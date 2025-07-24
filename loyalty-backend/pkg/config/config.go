package config

import (
	"os"
)

// Config holds all configuration for the application
type Config struct {
	Port           string
	Mode           string
	ChannelName    string
	ChaincodeName  string
	MSPPath        string
	CertPath       string
	KeyPath        string
	TLSCertPath    string
	PeerEndpoint   string
	GatewayPeer    string
	MSPID          string
}

// LoadConfig loads configuration from environment variables with defaults
func LoadConfig() *Config {
	return &Config{
		Port:           getEnv("PORT", "8080"),
		Mode:           getEnv("MODE", "fabric"),
		ChannelName:    getEnv("CHANNEL_NAME", "loyaltychannel"),
		ChaincodeName:  getEnv("CHAINCODE_NAME", "loyalty"),
		MSPPath:        getEnv("MSP_PATH", "/opt/gopath/src/github.com/chaincode/loyalty-network/network/organizations/peerOrganizations/bank.loyalty.com/users/Admin@bank.loyalty.com/msp"),
		CertPath:       getEnv("CERT_PATH", "/opt/gopath/src/github.com/chaincode/loyalty-network/network/organizations/peerOrganizations/bank.loyalty.com/users/Admin@bank.loyalty.com/msp/signcerts/cert.pem"),
		KeyPath:        getEnv("KEY_PATH", "/opt/gopath/src/github.com/chaincode/loyalty-network/network/organizations/peerOrganizations/bank.loyalty.com/users/Admin@bank.loyalty.com/msp/keystore"),
		TLSCertPath:    getEnv("TLS_CERT_PATH", "/opt/gopath/src/github.com/chaincode/loyalty-network/network/organizations/peerOrganizations/bank.loyalty.com/peers/peer0.bank.loyalty.com/tls/ca.crt"),
		PeerEndpoint:   getEnv("PEER_ENDPOINT", "localhost:7051"),
		GatewayPeer:    getEnv("GATEWAY_PEER", "peer0.bank.loyalty.com"),
		MSPID:          getEnv("MSP_ID", "BankOrgMSP"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
