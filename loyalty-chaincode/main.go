package main

import (
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func main() {
	loyaltySmartContract, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Error creating loyalty chaincode: %v", err)
	}

	if err := loyaltySmartContract.Start(); err != nil {
		log.Panicf("Error starting loyalty chaincode: %v", err)
	}
}
