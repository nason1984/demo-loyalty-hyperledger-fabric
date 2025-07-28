package models

import (
	"time"
	"gorm.io/gorm"
)

// User represents the users table
type User struct {
	ID           uint           `json:"id" gorm:"primaryKey"`
	Username     string         `json:"username" gorm:"uniqueIndex;not null"`
	PasswordHash string         `json:"-" gorm:"not null"`
	Email        string         `json:"email" gorm:"uniqueIndex;not null"`
	FullName     string         `json:"full_name" gorm:"not null"`
	Role         string         `json:"role" gorm:"default:'customer'"`
	Status       string         `json:"status" gorm:"default:'active'"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	LastLoginAt  *time.Time     `json:"last_login_at"`
	DeletedAt    gorm.DeletedAt `json:"-" gorm:"index"`
	
	// Relationships
	Sessions []UserSession `json:"-" gorm:"foreignKey:UserID"`
	Profile  *UserProfile  `json:"profile,omitempty" gorm:"foreignKey:UserID"`
	AuditLogs []AuditLog   `json:"-" gorm:"foreignKey:UserID"`
}

// UserSession represents the user_sessions table
type UserSession struct {
	ID             uint      `json:"id" gorm:"primaryKey"`
	SessionID      string    `json:"session_id" gorm:"uniqueIndex;not null"`
	UserID         uint      `json:"user_id" gorm:"not null"`
	Token          string    `json:"-" gorm:"not null"`
	ExpiresAt      time.Time `json:"expires_at" gorm:"not null"`
	CreatedAt      time.Time `json:"created_at"`
	LastAccessedAt time.Time `json:"last_accessed_at"`
	IPAddress      string    `json:"ip_address"`
	UserAgent      string    `json:"user_agent"`
	
	// Relationships
	User User `json:"user" gorm:"foreignKey:UserID"`
}

// UserProfile represents the user_profiles table
type UserProfile struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	UserID      uint      `json:"user_id" gorm:"not null"`
	Phone       string    `json:"phone"`
	Address     string    `json:"address"`
	DateOfBirth *time.Time `json:"date_of_birth"`
	Gender      string    `json:"gender"`
	Preferences string    `json:"preferences" gorm:"type:jsonb"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// SystemConfig represents the system_config table
type SystemConfig struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	ConfigKey   string    `json:"config_key" gorm:"uniqueIndex;not null"`
	ConfigValue string    `json:"config_value"`
	Description string    `json:"description"`
	DataType    string    `json:"data_type" gorm:"default:'string'"`
	IsSecret    bool      `json:"is_secret" gorm:"default:false"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// AuditLog represents the audit_logs table
type AuditLog struct {
	ID         uint      `json:"id" gorm:"primaryKey"`
	UserID     *uint     `json:"user_id"`
	Username   string    `json:"username"`
	Action     string    `json:"action" gorm:"not null"`
	Resource   string    `json:"resource"`
	ResourceID string    `json:"resource_id"`
	Details    string    `json:"details" gorm:"type:jsonb"`
	IPAddress  string    `json:"ip_address"`
	UserAgent  string    `json:"user_agent"`
	Timestamp  time.Time `json:"timestamp" gorm:"default:CURRENT_TIMESTAMP"`
	
	// Relationships
	User *User `json:"user,omitempty" gorm:"foreignKey:UserID"`
}

// LoginResponse represents login response
type LoginResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

// RegisterRequest represents user registration request
type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=50"`
	Password string `json:"password" binding:"required,min=6"`
	Email    string `json:"email" binding:"required,email"`
	FullName string `json:"full_name" binding:"required,min=2"`
	Role     string `json:"role,omitempty"`
}

// UserUpdateRequest represents user update request
type UserUpdateRequest struct {
	Email    string `json:"email,omitempty" binding:"omitempty,email"`
	FullName string `json:"full_name,omitempty" binding:"omitempty,min=2"`
	Role     string `json:"role,omitempty"`
	Status   string `json:"status,omitempty"`
}

// ChangePasswordRequest represents password change request
type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" binding:"required"`
	NewPassword     string `json:"new_password" binding:"required,min=6"`
}
