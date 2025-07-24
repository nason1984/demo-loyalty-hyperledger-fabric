package fabric

import (
	"fmt"
	"loyalty-backend/pkg/config"
)

type FabricClient struct {
	Contract *ContractStub
}

type ContractStub struct{}

// SubmitTransaction stub for standalone mode
func (c *ContractStub) SubmitTransaction(name string, args ...string) ([]byte, error) {
	return nil, fmt.Errorf("Fabric contract not available in standalone mode")
}

// EvaluateTransaction stub for standalone mode  
func (c *ContractStub) EvaluateTransaction(name string, args ...string) ([]byte, error) {
	return nil, fmt.Errorf("Fabric contract not available in standalone mode")
}

// NewFabricClient creates a new Fabric client for standalone mode
func NewFabricClient(cfg *config.Config) (*FabricClient, error) {
	return &FabricClient{
		Contract: &ContractStub{},
	}, nil
}

// Close closes the Fabric client connection
func (fc *FabricClient) Close() {
	// TODO: Implement actual close logic when Fabric is implemented
}
