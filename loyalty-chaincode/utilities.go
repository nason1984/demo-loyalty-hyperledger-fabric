package main

import (
	"fmt"
	"strconv"
	"time"
)

// =========================================================================================
// UTILITY FUNCTIONS
// =========================================================================================

// ParseTimestamp parses a timestamp string
func ParseTimestamp(timestamp string) (time.Time, error) {
	return time.Parse(time.RFC3339, timestamp)
}

// ValidateCustomerData validates customer data fields
func ValidateCustomerData(customer *Customer) error {
	if customer.CustomerID == "" {
		return fmt.Errorf("customer ID is required")
	}
	if customer.FullName == "" {
		return fmt.Errorf("full name is required")
	}
	if customer.Email == "" {
		return fmt.Errorf("email is required")
	}
	if customer.Phone == "" {
		return fmt.Errorf("phone is required")
	}
	if !isValidTier(customer.Tier) {
		return fmt.Errorf("invalid tier: %s", customer.Tier)
	}
	if !isValidStatus(customer.Status) {
		return fmt.Errorf("invalid status: %s", customer.Status)
	}
	return nil
}

// ValidateAccountData validates loyalty account data
func ValidateAccountData(account *LoyaltyAccount) error {
	if account.CustomerID == "" {
		return fmt.Errorf("customer ID is required")
	}
	if account.Balance < 0 {
		return fmt.Errorf("balance cannot be negative")
	}
	if account.LifetimeEarned < 0 {
		return fmt.Errorf("lifetime earned cannot be negative")
	}
	if account.LifetimeRedeemed < 0 {
		return fmt.Errorf("lifetime redeemed cannot be negative")
	}
	if !isValidStatus(account.Status) {
		return fmt.Errorf("invalid status: %s", account.Status)
	}
	return nil
}

// ValidateRewardData validates reward data
func ValidateRewardData(reward *Reward) error {
	if reward.RewardID == "" {
		return fmt.Errorf("reward ID is required")
	}
	if reward.Name == "" {
		return fmt.Errorf("reward name is required")
	}
	if reward.PointsCost <= 0 {
		return fmt.Errorf("points cost must be positive")
	}
	if reward.CashValue < 0 {
		return fmt.Errorf("cash value cannot be negative")
	}
	if reward.Quantity < 0 {
		return fmt.Errorf("quantity cannot be negative")
	}
	if !isValidStatus(reward.Status) {
		return fmt.Errorf("invalid status: %s", reward.Status)
	}
	return nil
}

// isValidTier checks if a tier is valid
func isValidTier(tier string) bool {
	validTiers := []string{"BRONZE", "SILVER", "GOLD", "PLATINUM"}
	for _, validTier := range validTiers {
		if tier == validTier {
			return true
		}
	}
	return false
}

// isValidStatus checks if a status is valid
func isValidStatus(status string) bool {
	validStatuses := []string{"ACTIVE", "INACTIVE", "SUSPENDED", "CLOSED"}
	for _, validStatus := range validStatuses {
		if status == validStatus {
			return true
		}
	}
	return false
}

// CalculateTierFromPoints determines customer tier based on lifetime points
func CalculateTierFromPoints(lifetimeEarned int) string {
	if lifetimeEarned >= 50000 {
		return "PLATINUM"
	} else if lifetimeEarned >= 25000 {
		return "GOLD"
	} else if lifetimeEarned >= 10000 {
		return "SILVER"
	}
	return "BRONZE"
}

// GetTierBenefits returns the benefits for a given tier
func GetTierBenefits(tier string) map[string]interface{} {
	benefits := make(map[string]interface{})
	
	switch tier {
	case "PLATINUM":
		benefits["pointsMultiplier"] = 2.0
		benefits["transferLimit"] = 10000
		benefits["transferFee"] = 0
		benefits["redemptionDiscount"] = 0.15
		benefits["exclusiveRewards"] = true
	case "GOLD":
		benefits["pointsMultiplier"] = 1.5
		benefits["transferLimit"] = 5000
		benefits["transferFee"] = 0
		benefits["redemptionDiscount"] = 0.10
		benefits["exclusiveRewards"] = false
	case "SILVER":
		benefits["pointsMultiplier"] = 1.2
		benefits["transferLimit"] = 2000
		benefits["transferFee"] = 0.02
		benefits["redemptionDiscount"] = 0.05
		benefits["exclusiveRewards"] = false
	case "BRONZE":
		benefits["pointsMultiplier"] = 1.0
		benefits["transferLimit"] = 1000
		benefits["transferFee"] = 0.05
		benefits["redemptionDiscount"] = 0.0
		benefits["exclusiveRewards"] = false
	default:
		benefits["pointsMultiplier"] = 1.0
		benefits["transferLimit"] = 1000
		benefits["transferFee"] = 0.05
		benefits["redemptionDiscount"] = 0.0
		benefits["exclusiveRewards"] = false
	}
	
	return benefits
}

// CalculatePointsEarned calculates points earned based on spend amount and tier
func CalculatePointsEarned(spendAmount float64, tier string) int {
	benefits := GetTierBenefits(tier)
	multiplier := benefits["pointsMultiplier"].(float64)
	
	// Base rate: 1 point per dollar spent
	basePoints := int(spendAmount)
	return int(float64(basePoints) * multiplier)
}

// FormatCurrency formats a float64 as currency string
func FormatCurrency(amount float64) string {
	return fmt.Sprintf("$%.2f", amount)
}

// ParseCurrency parses a currency string to float64
func ParseCurrency(currencyStr string) (float64, error) {
	// Remove $ symbol if present
	if len(currencyStr) > 0 && currencyStr[0] == '$' {
		currencyStr = currencyStr[1:]
	}
	return strconv.ParseFloat(currencyStr, 64)
}

// =========================================================================================
// BUSINESS RULE FUNCTIONS
// =========================================================================================

// CanTransferPoints checks if a customer can transfer points
func CanTransferPoints(fromTier string, amount int) (bool, string) {
	benefits := GetTierBenefits(fromTier)
	limit := benefits["transferLimit"].(int)
	
	if amount > limit {
		return false, fmt.Sprintf("Transfer amount %d exceeds daily limit %d for tier %s", amount, limit, fromTier)
	}
	
	return true, ""
}

// CanRedeemReward checks if a customer can redeem a specific reward
func CanRedeemReward(customerTier, rewardTier string, customerBalance, rewardCost int) (bool, string) {
	// Check tier eligibility
	if rewardTier != "" && !isRewardAvailableForTier(rewardTier, customerTier) {
		return false, fmt.Sprintf("Reward not available for tier %s", customerTier)
	}
	
	// Check balance
	if customerBalance < rewardCost {
		return false, fmt.Sprintf("Insufficient balance: %d, required: %d", customerBalance, rewardCost)
	}
	
	return true, ""
}

// isRewardAvailableForTier checks tier eligibility for rewards
func isRewardAvailableForTier(rewardTier, customerTier string) bool {
	if rewardTier == "" {
		return true // No restriction
	}

	tierHierarchy := map[string]int{
		"BRONZE":   1,
		"SILVER":   2,
		"GOLD":     3,
		"PLATINUM": 4,
	}

	rewardLevel := tierHierarchy[rewardTier]
	customerLevel := tierHierarchy[customerTier]

	return customerLevel >= rewardLevel
}

// =========================================================================================
// SYSTEM CONFIGURATION FUNCTIONS
// =========================================================================================

// GetSystemConfig returns system-wide configuration
func GetSystemConfig() map[string]interface{} {
	config := make(map[string]interface{})
	
	// Points earning rules
	config["basePointsPerDollar"] = 1
	config["tierMultipliers"] = map[string]float64{
		"BRONZE":   1.0,
		"SILVER":   1.2,
		"GOLD":     1.5,
		"PLATINUM": 2.0,
	}
	
	// Transfer limits
	config["transferLimits"] = map[string]int{
		"BRONZE":   1000,
		"SILVER":   2000,
		"GOLD":     5000,
		"PLATINUM": 10000,
	}
	
	// Transfer fees
	config["transferFees"] = map[string]float64{
		"BRONZE":   0.05,
		"SILVER":   0.02,
		"GOLD":     0.0,
		"PLATINUM": 0.0,
	}
	
	// Tier thresholds
	config["tierThresholds"] = map[string]int{
		"SILVER":   10000,
		"GOLD":     25000,
		"PLATINUM": 50000,
	}
	
	// Redemption discounts
	config["redemptionDiscounts"] = map[string]float64{
		"BRONZE":   0.0,
		"SILVER":   0.05,
		"GOLD":     0.10,
		"PLATINUM": 0.15,
	}
	
	// Business rules
	config["minTransferAmount"] = 10
	config["maxTransferAmount"] = 10000
	config["minRedemptionAmount"] = 50
	config["pointExpiryDays"] = 365
	config["accountInactivityDays"] = 730
	
	return config
}

// ValidateBusinessRules validates transaction against business rules
func ValidateBusinessRules(transactionType string, amount int, customerTier string) error {
	config := GetSystemConfig()
	
	switch transactionType {
	case "TRANSFER":
		minAmount := config["minTransferAmount"].(int)
		maxAmount := config["maxTransferAmount"].(int)
		
		if amount < minAmount {
			return fmt.Errorf("transfer amount %d is below minimum %d", amount, minAmount)
		}
		if amount > maxAmount {
			return fmt.Errorf("transfer amount %d exceeds maximum %d", amount, maxAmount)
		}
		
		// Check tier-specific limits
		tierLimits := config["transferLimits"].(map[string]int)
		if limit, exists := tierLimits[customerTier]; exists {
			if amount > limit {
				return fmt.Errorf("transfer amount %d exceeds tier limit %d for %s", amount, limit, customerTier)
			}
		}
		
	case "REDEMPTION":
		minAmount := config["minRedemptionAmount"].(int)
		if amount < minAmount {
			return fmt.Errorf("redemption amount %d is below minimum %d", amount, minAmount)
		}
	}
	
	return nil
}

// =========================================================================================
// AUDIT AND LOGGING FUNCTIONS
// =========================================================================================

// CreateAuditLog creates an audit log entry (placeholder for future implementation)
func CreateAuditLog(action, entityType, entityID, userID, details string) map[string]interface{} {
	return map[string]interface{}{
		"action":     action,
		"entityType": entityType,
		"entityID":   entityID,
		"userID":     userID,
		"details":    details,
		"timestamp":  GetCurrentTimestamp(),
	}
}

// ValidateMetadata validates metadata structure
func ValidateMetadata(metadata map[string]string) error {
	// Check for required metadata fields if any
	// Add validation rules as needed
	
	// Example: Limit metadata size
	if len(metadata) > 20 {
		return fmt.Errorf("metadata cannot have more than 20 fields")
	}
	
	// Validate individual field lengths
	for key, value := range metadata {
		if len(key) > 50 {
			return fmt.Errorf("metadata key '%s' exceeds maximum length of 50", key)
		}
		if len(value) > 500 {
			return fmt.Errorf("metadata value for key '%s' exceeds maximum length of 500", key)
		}
	}
	
	return nil
}
