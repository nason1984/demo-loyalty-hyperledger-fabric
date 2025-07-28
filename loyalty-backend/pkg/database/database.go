package database

import (
	"fmt"
	"log"
	"os"
	"time"

	"loyalty-backend/pkg/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

// Initialize database connection
func Initialize() error {
	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "localhost"
	}
	
	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "5432"
	}
	
	user := os.Getenv("DB_USER")
	if user == "" {
		user = "loyalty_user"
	}
	
	password := os.Getenv("DB_PASSWORD")
	if password == "" {
		password = "loyalty_password"
	}
	
	dbname := os.Getenv("DB_NAME")
	if dbname == "" {
		dbname = "loyalty_db"
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=UTC",
		host, user, password, dbname, port)

	var err error
	
	// Configure GORM logger
	gormLogger := logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags),
		logger.Config{
			SlowThreshold:             time.Second,
			LogLevel:                  logger.Info,
			IgnoreRecordNotFoundError: true,
			Colorful:                  true,
		},
	)

	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: gormLogger,
	})
	
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}

	// Get underlying sql.DB to configure connection pool
	sqlDB, err := DB.DB()
	if err != nil {
		return fmt.Errorf("failed to get underlying sql.DB: %w", err)
	}

	// Configure connection pool
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	log.Println("✅ Database connection established successfully")
	
	// Auto-migrate models (optional, since we have SQL migrations)
	err = autoMigrate()
	if err != nil {
		log.Printf("⚠️  Auto-migration failed: %v", err)
	}

	return nil
}

// Auto-migrate GORM models
func autoMigrate() error {
	return DB.AutoMigrate(
		&models.User{},
		&models.UserSession{},
		&models.UserProfile{},
		&models.SystemConfig{},
		&models.AuditLog{},
	)
}

// Close database connection
func Close() error {
	sqlDB, err := DB.DB()
	if err != nil {
		return err
	}
	return sqlDB.Close()
}

// Health check for database
func HealthCheck() error {
	sqlDB, err := DB.DB()
	if err != nil {
		return err
	}
	return sqlDB.Ping()
}
