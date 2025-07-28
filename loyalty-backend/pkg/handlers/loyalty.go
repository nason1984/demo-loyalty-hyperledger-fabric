package handlers

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"

	"loyalty-backend/pkg/fabric"
	"loyalty-backend/pkg/models"
	"loyalty-backend/pkg/services"
)

// LoyaltyHandler handles loyalty-related HTTP requests
type LoyaltyHandler struct {
	fabricClient *fabric.FabricClient
	userService  *services.UserService
}

// JWT secret key - in production, this should be from environment variable
var jwtSecret = []byte("loyalty-app-secret-key-2024")

// JWT Claims structure
type Claims struct {
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

// generateJWT creates a JWT token for the user
func generateJWT(username, role string) (string, error) {
	// Create claims
	claims := &Claims{
		Username: username,
		Role:     role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)), // 24 hours
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "loyalty-app",
			Subject:   username,
		},
	}

	// Create token with claims
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// Sign token with secret
	tokenString, err := token.SignedString(jwtSecret)
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// NewLoyaltyHandler creates a new loyalty handler
func NewLoyaltyHandler(fabricClient *fabric.FabricClient) *LoyaltyHandler {
	var userService *services.UserService
	mode := os.Getenv("MODE")
	if mode == "database" || mode == "" {
		userService = services.NewUserService()
	}
	
	return &LoyaltyHandler{
		fabricClient: fabricClient,
		userService:  userService,
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

	// Check if running in standalone mode (fabricClient is nil)
	if h.fabricClient == nil {
		// Return mock account data for standalone mode
		mockAccount := models.LoyaltyAccount{
			CustomerID:  req.CustomerID,
			Balance:     0,
			LastUpdated: time.Now().Format(time.RFC3339),
		}

		c.JSON(http.StatusCreated, models.APIResponse{
			Success: true,
			Message: "Account created successfully",
			Data:    mockAccount,
		})
		return
	}

	// Submit transaction to create account (for Fabric mode)
	result, err := h.fabricClient.CreateLoyaltyAccount(req.CustomerID)
	if err != nil {
		log.Printf("Error creating account on blockchain: %v", err)
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to create account on blockchain",
		})
		return
	}

	// For Fabric mode, result is already a proper structure
	c.JSON(http.StatusCreated, models.APIResponse{
		Success: true,
		Message: "Account created successfully",
		Data:    result,
	})
}

// GetAccount handles GET /accounts/:customerID
func (h *LoyaltyHandler) GetAccount(c *gin.Context) {
	// Safe nil check first
	if h == nil {
		log.Println("ERROR: Handler is nil")
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Internal server error - handler not initialized",
		})
		return
	}

	if c == nil {
		log.Println("ERROR: Context is nil")
		return
	}

	log.Println("GetAccount function called successfully")
	
	customerID := c.Param("customerID")
	log.Printf("customerID: %s", customerID)
	
	if customerID == "" {
		log.Println("customerID is empty")
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   "Customer ID is required",
		})
		return
	}

	mode := os.Getenv("MODE")
	log.Printf("Current mode: %s", mode)

	// Database mode - get user from database first
	if (mode == "database" || mode == "") && h.userService != nil {
		log.Println("Running in database mode, fetching user data")
		
		user, err := h.userService.GetUserByUsername(customerID)
		if err != nil {
			log.Printf("User not found in database: %v", err)
			c.JSON(http.StatusNotFound, models.APIResponse{
				Success: false,
				Error:   "Customer not found",
			})
			return
		}

		// If Fabric client is available, try to get real balance
		if h.fabricClient != nil {
			log.Println("Fabric client available, getting real account data from blockchain")
			fabricAccount, err := h.fabricClient.GetLoyaltyAccount(customerID)
			if err != nil {
				log.Printf("Error getting account from blockchain: %v", err)
				// Fallback to creating account if it doesn't exist
				log.Println("Account doesn't exist on blockchain, creating new account...")
				
				// Create account on blockchain with 0 initial balance
				newAccount, createErr := h.fabricClient.CreateLoyaltyAccount(customerID)
				if createErr != nil {
					log.Printf("Error creating account on blockchain: %v", createErr)
					c.JSON(http.StatusInternalServerError, models.APIResponse{
						Success: false,
						Error:   "Failed to create or retrieve account from blockchain",
					})
					return
				}
				fabricAccount = newAccount
			}
			
			log.Printf("Real account data from blockchain: %+v", fabricAccount)
			c.JSON(http.StatusOK, models.APIResponse{
				Success: true,
				Data:    fabricAccount,
			})
			return
		}

		// Fallback: For database mode without Fabric, create account response with mock data
		log.Println("No Fabric client, returning mock account data")
		mockAccount := models.LoyaltyAccount{
			CustomerID:  user.Username,
			Balance:     0, // Start with 0 balance instead of mock 1250
			LastUpdated: time.Now().Format(time.RFC3339),
		}
		
		log.Printf("Mock account created: %+v", mockAccount)

		c.JSON(http.StatusOK, models.APIResponse{
			Success: true,
			Data:    mockAccount,
		})
		return
	}

	log.Printf("fabricClient is nil: %v", h.fabricClient == nil)
	
	// Check if running in standalone mode (fabricClient is nil)
	if h.fabricClient == nil {
		log.Println("Running in standalone mode, creating mock account")
		// Return mock account data for standalone mode
		mockAccount := models.LoyaltyAccount{
			CustomerID:  customerID,
			Balance:     1250,
			LastUpdated: time.Now().AddDate(0, 0, -2).Format(time.RFC3339),
		}
		log.Printf("Mock account created: %+v", mockAccount)

		c.JSON(http.StatusOK, models.APIResponse{
			Success: true,
			Data:    mockAccount,
		})
		return
	}

	log.Printf("fabricClient is nil: %v", h.fabricClient == nil)
	
	// Check if running in standalone mode (fabricClient is nil)
	if h.fabricClient == nil {
		log.Println("Running in standalone mode, creating mock account")
		// Return mock account data for standalone mode
		mockAccount := models.LoyaltyAccount{
			CustomerID:  customerID,
			Balance:     1250,
			LastUpdated: time.Now().AddDate(0, 0, -2).Format(time.RFC3339),
		}
		log.Printf("Mock account created: %+v", mockAccount)

		c.JSON(http.StatusOK, models.APIResponse{
			Success: true,
			Data:    mockAccount,
		})
		return
	}

	log.Println("Running in Fabric mode - calling blockchain")
	// Get account from blockchain (for Fabric mode)
	result, err := h.fabricClient.GetLoyaltyAccount(customerID)
	if err != nil {
		log.Printf("Error getting account from blockchain: %v", err)
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to get account from blockchain",
		})
		return
	}

	// For Fabric mode, result is already a proper structure
	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Data:    result,
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

	// Check if running in standalone mode (fabricClient is nil)
	if h.fabricClient == nil {
		// Return mock account data for standalone mode
		mockAccount := models.LoyaltyAccount{
			CustomerID:  customerID,
			Balance:     1250 + req.Amount, // Add issued points
			LastUpdated: time.Now().Format(time.RFC3339),
		}

		c.JSON(http.StatusOK, models.APIResponse{
			Success: true,
			Message: "Points issued successfully",
			Data:    mockAccount,
		})
		return
	}

	// Submit transaction to issue points (for Fabric mode)
	result, err := h.fabricClient.IssuePoints(customerID, req.Amount, req.Description)
	if err != nil {
		log.Printf("Error issuing points on blockchain: %v", err)
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to issue points on blockchain",
		})
		return
	}

	// For Fabric mode, result is already a proper structure
	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Points issued successfully",
		Data:    result,
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

	// Check if running in standalone mode (fabricClient is nil)
	if h.fabricClient == nil {
		// Check if user has enough points
		currentBalance := 1250 // Mock current balance
		if req.Amount > currentBalance {
			c.JSON(http.StatusBadRequest, models.APIResponse{
				Success: false,
				Error:   "Insufficient points balance",
			})
			return
		}

		// Return mock account data for standalone mode
		mockAccount := models.LoyaltyAccount{
			CustomerID:  customerID,
			Balance:     currentBalance - req.Amount, // Subtract redeemed points
			LastUpdated: time.Now().Format(time.RFC3339),
		}

		c.JSON(http.StatusOK, models.APIResponse{
			Success: true,
			Message: "Points redeemed successfully",
			Data:    mockAccount,
		})
		return
	}

	// Submit transaction to redeem points (for Fabric mode)
	result, err := h.fabricClient.RedeemPoints(customerID, req.Amount, req.Description)
	if err != nil {
		log.Printf("Error redeeming points on blockchain: %v", err)
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to redeem points on blockchain",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Points redeemed successfully",
		Data:    result,
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

	// Check if running in standalone mode (fabricClient is nil)
	if h.fabricClient == nil {
		// Mock validation - check if source and target are different
		if req.SourceCustomerID == req.TargetCustomerID {
			c.JSON(http.StatusBadRequest, models.APIResponse{
				Success: false,
				Error:   "Cannot transfer points to the same account",
			})
			return
		}

		// Mock validation - check if user has enough points
		if req.Amount > 1250 { // Mock current balance
			c.JSON(http.StatusBadRequest, models.APIResponse{
				Success: false,
				Error:   "Insufficient points balance",
			})
			return
		}

		c.JSON(http.StatusOK, models.APIResponse{
			Success: true,
			Message: "Points transferred successfully",
		})
		return
	}

	// Submit transaction to transfer points (for Fabric mode)
	result, err := h.fabricClient.TransferPoints(req.SourceCustomerID, req.TargetCustomerID, req.Amount, req.Description)
	if err != nil {
		log.Printf("Error transferring points on blockchain: %v", err)
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to transfer points on blockchain",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Points transferred successfully",
		Data:    result,
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

// Login handles POST /login
func (h *LoyaltyHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   "Invalid request format",
		})
		return
	}

	// Simple mock authentication for standalone mode
	// In production, this should verify against a database
	if req.Username == "" || req.Password == "" {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   "Username and password are required",
		})
		return
	}

	// Mock authentication logic - accept any password for demo
	var role string
	if req.Username == "admin" || req.Username == "employee" {
		role = "employee"
	} else {
		role = "customer"
	}

	// Generate a real JWT token
	token, err := generateJWT(req.Username, role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to generate token",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Login successful",
		Data: gin.H{
			"token": token,
			"user": gin.H{
				"username": req.Username,
				"role":     role,
			},
		},
	})
}

// GetRecentTransactions handles GET /accounts/:customerID/recent-transactions
func (h *LoyaltyHandler) GetRecentTransactions(c *gin.Context) {
	customerID := c.Param("customerID")
	if customerID == "" {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   "Customer ID is required",
		})
		return
	}

	// Check if Fabric client is available
	if h.fabricClient != nil {
		log.Println("Fabric client available, getting real transaction history from blockchain")
		
		// For Fabric mode, call chaincode to get loyalty history
		transactions, err := h.fabricClient.GetLoyaltyHistory(customerID)
		if err != nil {
			log.Printf("Error getting transaction history from blockchain: %v", err)
			c.JSON(http.StatusInternalServerError, models.APIResponse{
				Success: false,
				Error:   "Failed to get transaction history from blockchain",
			})
			return
		}
		
		log.Printf("Real transaction history from blockchain: %+v", transactions)
		c.JSON(http.StatusOK, models.APIResponse{
			Success: true,
			Message: "Recent transactions retrieved successfully",
			Data:    transactions,
		})
		return
	}

	// Fallback: Return empty transactions instead of mock data for standalone mode
	log.Println("No Fabric client available, returning empty transaction list")
	emptyTransactions := []gin.H{}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "No transaction history available",
		Data:    emptyTransactions,
	})
}
