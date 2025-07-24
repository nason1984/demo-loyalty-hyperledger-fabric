package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"loyalty-backend/pkg/fabric"
	"loyalty-backend/pkg/models"
)

// LoyaltyHandler handles loyalty-related HTTP requests
type LoyaltyHandler struct {
	fabricClient *fabric.FabricClient
}

// NewLoyaltyHandler creates a new loyalty handler
func NewLoyaltyHandler(fabricClient *fabric.FabricClient) *LoyaltyHandler {
	return &LoyaltyHandler{
		fabricClient: fabricClient,
	}
}

// CreateAccount handles POST /accounts
func (h *LoyaltyHandler) CreateAccount(c *gin.Context) {
	var req models.CreateAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	// Submit transaction to create account
	result, err := h.fabricClient.Contract.SubmitTransaction("CreateLoyaltyAccount", req.CustomerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	var account models.LoyaltyAccount
	if err := json.Unmarshal(result, &account); err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to parse response",
		})
		return
	}

	c.JSON(http.StatusCreated, models.APIResponse{
		Success: true,
		Message: "Account created successfully",
		Data:    account,
	})
}

// GetAccount handles GET /accounts/:customerID
func (h *LoyaltyHandler) GetAccount(c *gin.Context) {
	customerID := c.Param("customerID")
	if customerID == "" {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   "Customer ID is required",
		})
		return
	}

	// Evaluate transaction to query account
	result, err := h.fabricClient.Contract.EvaluateTransaction("QueryLoyaltyAccount", customerID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	var account models.LoyaltyAccount
	if err := json.Unmarshal(result, &account); err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to parse response",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Data:    account,
	})
}

// IssuePoints handles POST /accounts/:customerID/issue
func (h *LoyaltyHandler) IssuePoints(c *gin.Context) {
	customerID := c.Param("customerID")
	if customerID == "" {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   "Customer ID is required",
		})
		return
	}

	var req models.IssuePointsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	// Submit transaction to issue points
	result, err := h.fabricClient.Contract.SubmitTransaction("IssuePoints", customerID, fmt.Sprintf("%d", req.Amount), req.Description)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	var account models.LoyaltyAccount
	if err := json.Unmarshal(result, &account); err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to parse response",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Points issued successfully",
		Data:    account,
	})
}

// RedeemPoints handles POST /accounts/:customerID/redeem
func (h *LoyaltyHandler) RedeemPoints(c *gin.Context) {
	customerID := c.Param("customerID")
	if customerID == "" {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   "Customer ID is required",
		})
		return
	}

	var req models.RedeemPointsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	// Submit transaction to redeem points
	result, err := h.fabricClient.Contract.SubmitTransaction("RedeemPoints", customerID, fmt.Sprintf("%d", req.Amount), req.Description)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	var account models.LoyaltyAccount
	if err := json.Unmarshal(result, &account); err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to parse response",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Points redeemed successfully",
		Data:    account,
	})
}

// TransferPoints handles POST /transfer
func (h *LoyaltyHandler) TransferPoints(c *gin.Context) {
	var req models.TransferPointsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	// Submit transaction to transfer points
	_, err := h.fabricClient.Contract.SubmitTransaction("TransferPoints", req.SourceCustomerID, req.TargetCustomerID, fmt.Sprintf("%d", req.Amount), req.Description)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Points transferred successfully",
	})
}

// HealthCheck handles GET /health
func (h *LoyaltyHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Loyalty API is running",
		Data: gin.H{
			"status":    "healthy",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		},
	})
}
