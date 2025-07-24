package models

// LoyaltyAccount represents a loyalty account on the ledger
type LoyaltyAccount struct {
	CustomerID  string `json:"customerID"`
	Balance     int    `json:"balance"`
	LastUpdated string `json:"lastUpdated"`
}

// LoyaltyTransaction represents a loyalty transaction
type LoyaltyTransaction struct {
	TransactionID string `json:"transactionID"`
	CustomerID    string `json:"customerID"`
	Type          string `json:"type"` // ISSUE, REDEEM, TRANSFER_IN, TRANSFER_OUT, CREATE_ACCOUNT
	Amount        int    `json:"amount"`
	Timestamp     string `json:"timestamp"`
	Description   string `json:"description"`
}

// CreateAccountRequest represents the request to create a new loyalty account
type CreateAccountRequest struct {
	CustomerID string `json:"customerID" binding:"required"`
}

// IssuePointsRequest represents the request to issue loyalty points
type IssuePointsRequest struct {
	CustomerID  string `json:"customerID" binding:"required"`
	Amount      int    `json:"amount" binding:"required,min=1"`
	Description string `json:"description"`
}

// RedeemPointsRequest represents the request to redeem loyalty points
type RedeemPointsRequest struct {
	CustomerID  string `json:"customerID" binding:"required"`
	Amount      int    `json:"amount" binding:"required,min=1"`
	Description string `json:"description"`
}

// TransferPointsRequest represents the request to transfer loyalty points
type TransferPointsRequest struct {
	SourceCustomerID string `json:"sourceCustomerID" binding:"required"`
	TargetCustomerID string `json:"targetCustomerID" binding:"required"`
	Amount           int    `json:"amount" binding:"required,min=1"`
	Description      string `json:"description"`
}

// APIResponse represents a standard API response
type APIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}
