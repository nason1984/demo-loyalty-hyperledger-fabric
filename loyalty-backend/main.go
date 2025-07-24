// main.go
package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"loyalty-backend/pkg/config"
	"loyalty-backend/pkg/fabric"
	"loyalty-backend/pkg/handlers"
)

// =========================================================================================
// Sprint 2 - Task 1: Khởi tạo Web Server API
//
// Logic chính:
// 1. Load configuration từ environment variables.
// 2. Khởi tạo kết nối đến Hyperledger Fabric network.
// 3. Khởi tạo Gin engine và setup middleware.
// 4. Đăng ký các API routes cho loyalty operations.
// 5. Chạy server trên port được cấu hình.
//
// API Endpoints:
// - GET /health - Health check
// - POST /api/v1/accounts - Tạo tài khoản loyalty
// - GET /api/v1/accounts/:customerID - Truy vấn tài khoản
// - POST /api/v1/accounts/:customerID/issue - Phát hành điểm
// - POST /api/v1/accounts/:customerID/redeem - Quy đổi điểm  
// - POST /api/v1/transfer - Chuyển điểm giữa tài khoản
// =========================================================================================
func main() {
	// 1. Load configuration
	cfg := config.LoadConfig()
	log.Printf("Starting Loyalty API server on port %s", cfg.Port)

	// 2. Initialize Fabric client connection (only if not in standalone mode)
	var fabricClient *fabric.FabricClient
	if cfg.Mode != "standalone" {
		var err error
		fabricClient, err = fabric.NewFabricClient(cfg)
		if err != nil {
			log.Printf("Warning: Failed to create Fabric client: %v", err)
			log.Println("Running in standalone mode with mock data")
		} else {
			defer fabricClient.Close()
			log.Println("Connected to Hyperledger Fabric network successfully")
		}
	} else {
		log.Println("Running in standalone mode with mock data")
	}

	// 3. Initialize Gin engine
	r := gin.Default()

	// Add CORS middleware
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		
		c.Next()
	})

	// Add logging middleware
	r.Use(gin.Logger())
	r.Use(gin.Recovery())

	// 4. Initialize handlers
	loyaltyHandler := handlers.NewLoyaltyHandler(fabricClient)

	// Health check endpoint
	r.GET("/health", loyaltyHandler.HealthCheck)
	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Loyalty API is running",
			"version": "1.0.0",
			"endpoints": gin.H{
				"health":       "GET /health",
				"accounts":     "POST /api/v1/accounts",
				"query":        "GET /api/v1/accounts/:customerID", 
				"issue":        "POST /api/v1/accounts/:customerID/issue",
				"redeem":       "POST /api/v1/accounts/:customerID/redeem",
				"transfer":     "POST /api/v1/transfer",
			},
		})
	})

	// API v1 routes group
	v1 := r.Group("/api/v1")
	{
		// Account operations
		accounts := v1.Group("/accounts")
		{
			accounts.POST("", loyaltyHandler.CreateAccount)                    // Create account
			accounts.GET("/:customerID", loyaltyHandler.GetAccount)            // Query account
			accounts.POST("/:customerID/issue", loyaltyHandler.IssuePoints)    // Issue points
			accounts.POST("/:customerID/redeem", loyaltyHandler.RedeemPoints)  // Redeem points
		}

		// Transfer operations
		v1.POST("/transfer", loyaltyHandler.TransferPoints) // Transfer points
	}

	// 5. Start server
	log.Printf("Server starting on :%s", cfg.Port)
	log.Printf("API Documentation available at: http://localhost:%s/", cfg.Port)
	
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}