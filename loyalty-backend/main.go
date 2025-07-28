// main.go
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"

	"loyalty-backend/pkg/config"
	"loyalty-backend/pkg/database"
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

	// 2. Initialize Database connection
	mode := os.Getenv("MODE")
	if mode == "database" || mode == "" {
		log.Println("Initializing PostgreSQL database...")
		err := database.Initialize()
		if err != nil {
			log.Fatalf("Failed to initialize database: %v", err)
		}
		defer database.Close()
		log.Println("✅ Database connection established successfully")
	}

	// 3. Initialize Fabric client connection (always try to connect)
	var fabricClient *fabric.FabricClient
	var err error
	fabricClient, err = fabric.NewFabricClient(cfg)
	if err != nil {
		log.Printf("Warning: Failed to create Fabric client: %v", err)
		log.Println("Continuing without Fabric client - will return mock data")
		fabricClient = nil
	} else {
		defer fabricClient.Close()
		log.Println("✅ Connected to Hyperledger Fabric network successfully")
	}

	// Determine runtime mode
	if mode == "" || mode == "database" {
		log.Println("Running with PostgreSQL database")
	} else if mode == "standalone" {
		log.Println("Running in standalone mode with mock data")
	} else if mode == "fabric" {
		log.Println("Running with Hyperledger Fabric")
	}

	// 4. Initialize Gin engine
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

	// 5. Initialize handlers
	authHandler := handlers.NewAuthHandler()
	loyaltyHandler := handlers.NewLoyaltyHandler(fabricClient)

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		// Check database health if in database mode
		if mode == "database" || mode == "" {
			err := database.HealthCheck()
			if err != nil {
				c.JSON(http.StatusServiceUnavailable, gin.H{
					"status":   "unhealthy",
					"database": "disconnected",
					"mode":     mode,
					"error":    err.Error(),
				})
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"status":   "healthy",
				"database": "connected",
				"mode":     mode,
			})
		} else {
			c.JSON(http.StatusOK, gin.H{
				"status": "healthy",
				"mode":   mode,
			})
		}
	})
	
	// API documentation endpoint
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Loyalty API is running",
			"version": "1.0.0",
			"mode":    mode,
			"endpoints": gin.H{
				"health":     "GET /health",
				"login":      "POST /api/v1/auth/login",
				"register":   "POST /api/v1/auth/register", 
				"profile":    "GET /api/v1/auth/profile",
				"logout":     "POST /api/v1/auth/logout",
				"accounts":   "POST /api/v1/accounts",
				"query":      "GET /api/v1/accounts/:customerID",
				"issue":      "POST /api/v1/accounts/:customerID/issue",
				"redeem":     "POST /api/v1/accounts/:customerID/redeem",
				"transfer":   "POST /api/v1/transfer",
			},
		})
	})

	// API v1 routes group
	v1 := r.Group("/api/v1")
	{
		// Authentication routes
		auth := v1.Group("/auth")
		{
			auth.POST("/login", authHandler.Login)
			auth.POST("/register", authHandler.Register)
			auth.GET("/profile", authHandler.GetProfile)
			auth.POST("/logout", authHandler.Logout)
		}

		// Legacy login endpoint (for backward compatibility)
		v1.POST("/login", authHandler.Login)

		// Account operations
		accounts := v1.Group("/accounts")
		{
			accounts.POST("", loyaltyHandler.CreateAccount)
			accounts.GET("/:customerID", loyaltyHandler.GetAccount)
			accounts.GET("/:customerID/recent-transactions", loyaltyHandler.GetRecentTransactions)
			accounts.POST("/:customerID/issue", loyaltyHandler.IssuePoints)
			accounts.POST("/:customerID/redeem", loyaltyHandler.RedeemPoints)
		}

		// Transfer operations
		v1.POST("/transfer", loyaltyHandler.TransferPoints)
	}

	// 5. Start server
	log.Printf("Server starting on :%s", cfg.Port)
	log.Printf("API Documentation available at: http://localhost:%s/", cfg.Port)
	
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}