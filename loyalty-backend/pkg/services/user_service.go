package services

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"loyalty-backend/pkg/database"
	"loyalty-backend/pkg/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type UserService struct {
	db *gorm.DB
}

func NewUserService() *UserService {
	return &UserService{
		db: database.DB,
	}
}

// Authenticate user with username and password
func (s *UserService) Authenticate(username, password string) (*models.User, error) {
	var user models.User
	
	// Find user by username
	err := s.db.Where("username = ? AND status = ?", username, "active").First(&user).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("invalid username or password")
		}
		return nil, fmt.Errorf("database error: %w", err)
	}

	// Check password
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		return nil, errors.New("invalid username or password")
	}

	// Update last login time
	now := time.Now()
	user.LastLoginAt = &now
	s.db.Save(&user)

	return &user, nil
}

// Create new user
func (s *UserService) CreateUser(req models.RegisterRequest) (*models.User, error) {
	// Check if username already exists
	var existingUser models.User
	err := s.db.Where("username = ?", req.Username).First(&existingUser).Error
	if err == nil {
		return nil, errors.New("username already exists")
	}

	// Check if email already exists
	err = s.db.Where("email = ?", req.Email).First(&existingUser).Error
	if err == nil {
		return nil, errors.New("email already exists")
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Set default role if not provided
	role := req.Role
	if role == "" {
		role = "customer"
	}

	// Create user
	user := models.User{
		Username:     req.Username,
		PasswordHash: string(hashedPassword),
		Email:        req.Email,
		FullName:     req.FullName,
		Role:         role,
		Status:       "active",
	}

	err = s.db.Create(&user).Error
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return &user, nil
}

// Get user by ID
func (s *UserService) GetUserByID(id uint) (*models.User, error) {
	var user models.User
	err := s.db.Preload("Profile").First(&user, id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("user not found")
		}
		return nil, fmt.Errorf("database error: %w", err)
	}
	return &user, nil
}

// Get user by username
func (s *UserService) GetUserByUsername(username string) (*models.User, error) {
	var user models.User
	err := s.db.Preload("Profile").Where("username = ?", username).First(&user).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("user not found")
		}
		return nil, fmt.Errorf("database error: %w", err)
	}
	return &user, nil
}

// Create user session
func (s *UserService) CreateSession(userID uint, token string, expiresAt time.Time, ipAddress, userAgent string) (*models.UserSession, error) {
	// Generate session ID
	sessionID, err := generateSessionID()
	if err != nil {
		return nil, fmt.Errorf("failed to generate session ID: %w", err)
	}

	session := models.UserSession{
		SessionID:      sessionID,
		UserID:         userID,
		Token:          token,
		ExpiresAt:      expiresAt,
		IPAddress:      ipAddress,
		UserAgent:      userAgent,
		LastAccessedAt: time.Now(),
	}

	err = s.db.Create(&session).Error
	if err != nil {
		return nil, fmt.Errorf("failed to create session: %w", err)
	}

	return &session, nil
}

// Log user action
func (s *UserService) LogAction(userID *uint, username, action, resource, resourceID string, details map[string]interface{}, ipAddress, userAgent string) error {
	var detailsJSON string
	if details != nil {
		// Convert details to proper JSON string
		jsonBytes, err := json.Marshal(details)
		if err != nil {
			detailsJSON = "{}"
		} else {
			detailsJSON = string(jsonBytes)
		}
	}

	auditLog := models.AuditLog{
		UserID:     userID,
		Username:   username,
		Action:     action,
		Resource:   resource,
		ResourceID: resourceID,
		Details:    detailsJSON,
		IPAddress:  ipAddress,
		UserAgent:  userAgent,
		Timestamp:  time.Now(),
	}

	return s.db.Create(&auditLog).Error
}

// Generate random session ID
func generateSessionID() (string, error) {
	bytes := make([]byte, 32)
	_, err := rand.Read(bytes)
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}
