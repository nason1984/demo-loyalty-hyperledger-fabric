package handlers

import (
	"net/http"
	"strconv"
	"time"

	"loyalty-backend/pkg/models"
	"loyalty-backend/pkg/services"
	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	userService *services.UserService
}

func NewAuthHandler() *AuthHandler {
	return &AuthHandler{
		userService: services.NewUserService(),
	}
}

// Login handles POST /auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	// Authenticate user
	user, err := h.userService.Authenticate(req.Username, req.Password)
	if err != nil {
		// Log failed login attempt
		h.userService.LogAction(nil, req.Username, "LOGIN_FAILED", "auth", "", 
			map[string]interface{}{"reason": err.Error()}, 
			c.ClientIP(), c.GetHeader("User-Agent"))
		
		c.JSON(http.StatusUnauthorized, models.APIResponse{
			Success: false,
			Error:   "Invalid username or password",
		})
		return
	}

	// Generate JWT token
	token, err := generateJWT(user.Username, user.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to generate token",
		})
		return
	}

	// Create session
	expiresAt := time.Now().Add(24 * time.Hour)
	session, err := h.userService.CreateSession(user.ID, token, expiresAt, c.ClientIP(), c.GetHeader("User-Agent"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Failed to create session",
		})
		return
	}

	// Log successful login
	h.userService.LogAction(&user.ID, user.Username, "LOGIN_SUCCESS", "auth", "", 
		map[string]interface{}{"session_id": session.SessionID}, 
		c.ClientIP(), c.GetHeader("User-Agent"))

	// Return response
	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Login successful",
		Data: models.LoginResponse{
			Token: token,
			User:  *user,
		},
	})
}

// Register handles POST /auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	// Create user
	user, err := h.userService.CreateUser(req)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	// Log user registration
	h.userService.LogAction(&user.ID, user.Username, "USER_REGISTERED", "auth", strconv.Itoa(int(user.ID)), 
		map[string]interface{}{"role": user.Role}, 
		c.ClientIP(), c.GetHeader("User-Agent"))

	c.JSON(http.StatusCreated, models.APIResponse{
		Success: true,
		Message: "User registered successfully",
		Data:    user,
	})
}

// GetProfile handles GET /auth/profile
func (h *AuthHandler) GetProfile(c *gin.Context) {
	// Get user from context (set by auth middleware)
	userInterface, exists := c.Get("user")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.APIResponse{
			Success: false,
			Error:   "User not found in context",
		})
		return
	}

	user, ok := userInterface.(*models.User)
	if !ok {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   "Invalid user data",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Data:    user,
	})
}

// Logout handles POST /auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	// Get user from context (set by auth middleware)
	userInterface, exists := c.Get("user")
	if exists {
		if user, ok := userInterface.(*models.User); ok {
			// Log logout action
			h.userService.LogAction(&user.ID, user.Username, "LOGOUT", "auth", "", 
				map[string]interface{}{"logout_time": time.Now()}, 
				c.ClientIP(), c.GetHeader("User-Agent"))
		}
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Logged out successfully",
	})
}
