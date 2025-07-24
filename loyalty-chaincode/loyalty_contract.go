package chaincode

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract cung cấp các hàm logic để quản lý điểm loyalty
type SmartContract struct {
	contractapi.Contract
}

// LoyaltyAccount định nghĩa cấu trúc cho một tài khoản loyalty trên sổ cái
type LoyaltyAccount struct {
	CustomerID  string `json:"customerID"`
	Balance     int    `json:"balance"`
	LastUpdated string `json:"lastUpdated"`
}

// LoyaltyTransaction định nghĩa cấu trúc cho một giao dịch loyalty
// (Chúng ta sẽ sử dụng nó trong các hàm sau)
type LoyaltyTransaction struct {
	TransactionID string `json:"transactionID"`
	CustomerID    string `json:"customerID"`
	Type          string `json:"type"` // ISSUE, REDEEM, TRANSFER_IN, TRANSFER_OUT, CREATE_ACCOUNT
	Amount        int    `json:"amount"`
	Timestamp     string `json:"timestamp"`
	Description   string `json:"description"`
}

// =========================================================================================
// UC-001: Tạo tài khoản Loyalty
// Yêu cầu: FRS-001
//
// Logic chính:
// 1. Kiểm tra xem tài khoản với `customerID` đã tồn tại trên sổ cái chưa. Nếu đã tồn tại -> trả về lỗi.
// 2. Nếu chưa tồn tại, tạo một đối tượng LoyaltyAccount mới.
// 3. Gán CustomerID từ tham số đầu vào, Balance là 0, và LastUpdated là thời gian hiện tại.
// 4. Chuyển đổi đối tượng thành dạng JSON.
// 5. Lưu đối tượng JSON này vào World State của sổ cái với key là customerID.
// 6. Trả về đối tượng LoyaltyAccount vừa tạo.
// =========================================================================================
// Gợi ý cho Copilot:
// CreateLoyaltyAccount tạo một tài khoản loyalty mới trên sổ cái.
// Đồng thời phát ra một sự kiện "CreateAccountEvent" để ghi nhận giao dịch.
func (s *SmartContract) CreateLoyaltyAccount(ctx contractapi.TransactionContextInterface, customerID string) (*LoyaltyAccount, error) {
	// === Validation: Thêm bước kiểm tra đầu vào ===
	if customerID == "" {
		return nil, fmt.Errorf("customer ID cannot be empty")
	}

	// 1. Kiểm tra xem tài khoản với customerID đã tồn tại trên sổ cái chưa
	existingAccountJSON, err := ctx.GetStub().GetState(customerID)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if existingAccountJSON != nil {
		return nil, fmt.Errorf("loyalty account with customer ID '%s' already exists", customerID)
	}

	// 2. & 3. Tạo một đối tượng LoyaltyAccount mới
	account := LoyaltyAccount{
		CustomerID:  customerID,
		Balance:     0,
		LastUpdated: time.Now().UTC().Format(time.RFC3339),
	}

	// 4. Chuyển đổi đối tượng thành dạng JSON
	accountJSON, err := json.Marshal(account)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal loyalty account: %v", err)
	}

	// 5. Lưu đối tượng JSON này vào World State
	err = ctx.GetStub().PutState(customerID, accountJSON)
	if err != nil {
		return nil, fmt.Errorf("failed to put state for account: %v", err)
	}

	// === CẢI TIẾN: Ghi lại giao dịch bằng cách phát ra một sự kiện ===
	transaction := LoyaltyTransaction{
		TransactionID: ctx.GetStub().GetTxID(), // Lấy ID của giao dịch hiện tại
		CustomerID:    customerID,
		Type:          "CREATE_ACCOUNT",
		Amount:        0,
		Timestamp:     account.LastUpdated,
		Description:   "Initial account creation",
	}
	transactionJSON, err := json.Marshal(transaction)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal transaction event: %v", err)
	}

	// Đặt tên cho sự kiện để các ứng dụng client có thể lắng nghe
	err = ctx.GetStub().SetEvent("CreateAccountEvent", transactionJSON)
	if err != nil {
		return nil, fmt.Errorf("failed to set event for transaction: %v", err)
	}

	// 6. Trả về đối tượng LoyaltyAccount vừa tạo
	return &account, nil
}


// =========================================================================================
// UC-002: Phát hành điểm Loyalty
// Yêu cầu: FRS-002
//
// Logic chính:
// 1. Kiểm tra định danh của người gọi. Chỉ có thành viên của `BankOrgMSP` mới có quyền phát hành điểm.
// 2. Tìm tài khoản Loyalty theo `customerID`. Nếu không tồn tại -> trả về lỗi.
// 3. Kiểm tra `amount` (số điểm) phải là số nguyên dương (>0). Nếu không -> trả về lỗi.
// 4. Đọc số dư hiện tại, tính số dư mới = số dư cũ + amount.
// 5. Cập nhật lại đối tượng LoyaltyAccount với số dư mới vào World State.
// 6. Tạo và phát ra một sự kiện "IssuePointsEvent" với thông tin chi tiết của giao dịch.
// 7. Trả về đối tượng LoyaltyAccount đã được cập nhật.
// =========================================================================================
// Gợi ý cho Copilot:
func (s *SmartContract) IssuePoints(ctx contractapi.TransactionContextInterface, customerID string, amount int, description string) (*LoyaltyAccount, error) {
	// 1. Kiểm tra định danh của người gọi - chỉ BankOrgMSP mới có quyền phát hành điểm
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return nil, fmt.Errorf("failed to get client MSP ID: %v", err)
	}
	if clientMSPID != "BankOrgMSP" {
		return nil, fmt.Errorf("access denied: only BankOrgMSP can issue points, got MSP ID: %s", clientMSPID)
	}

	// === Validation đầu vào ===
	if customerID == "" {
		return nil, fmt.Errorf("customer ID cannot be empty")
	}
	// 3. Kiểm tra amount phải là số nguyên dương
	if amount <= 0 {
		return nil, fmt.Errorf("amount must be a positive integer, got: %d", amount)
	}

	// 2. Tìm tài khoản Loyalty theo customerID
	accountJSON, err := ctx.GetStub().GetState(customerID)
	if err != nil {
		return nil, fmt.Errorf("failed to read account from world state: %v", err)
	}
	if accountJSON == nil {
		return nil, fmt.Errorf("loyalty account with customer ID '%s' does not exist", customerID)
	}

	// Deserialize tài khoản hiện tại
	var account LoyaltyAccount
	err = json.Unmarshal(accountJSON, &account)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal account data: %v", err)
	}

	// 4. Tính số dư mới = số dư cũ + amount
	oldBalance := account.Balance
	account.Balance = oldBalance + amount
	account.LastUpdated = time.Now().UTC().Format(time.RFC3339)

	// 5. Cập nhật lại đối tượng LoyaltyAccount vào World State
	updatedAccountJSON, err := json.Marshal(account)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal updated account: %v", err)
	}

	err = ctx.GetStub().PutState(customerID, updatedAccountJSON)
	if err != nil {
		return nil, fmt.Errorf("failed to update account in world state: %v", err)
	}

	// 6. Tạo và phát ra sự kiện "IssuePointsEvent"
	transaction := LoyaltyTransaction{
		TransactionID: ctx.GetStub().GetTxID(),
		CustomerID:    customerID,
		Type:          "ISSUE",
		Amount:        amount,
		Timestamp:     account.LastUpdated,
		Description:   description,
	}

	transactionJSON, err := json.Marshal(transaction)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal transaction event: %v", err)
	}

	err = ctx.GetStub().SetEvent("IssuePointsEvent", transactionJSON)
	if err != nil {
		return nil, fmt.Errorf("failed to set event for transaction: %v", err)
	}

	// 7. Trả về đối tượng LoyaltyAccount đã được cập nhật
	return &account, nil
}

// =========================================================================================
// UC-003: Quy đổi điểm Loyalty
// Yêu cầu: FRS-003
//
// Logic chính:
// 1. Tìm tài khoản Loyalty theo `customerID`. Nếu không tồn tại -> trả về lỗi.
// 2. Kiểm tra `amount` (số điểm) phải là số nguyên dương (>0). Nếu không -> trả về lỗi.
// 3. Đọc số dư hiện tại của tài khoản.
// 4. KIỂM TRA QUAN TRỌNG: Số dư hiện tại phải lớn hơn hoặc bằng số điểm muốn quy đổi (balance >= amount). Nếu không -> trả về lỗi "Không đủ điểm".
// 5. Tính số dư mới = số dư cũ - amount.
// 6. Cập nhật lại đối tượng LoyaltyAccount với số dư mới vào World State.
// 7. Tạo và phát ra một sự kiện "RedeemPointsEvent" với thông tin chi tiết của giao dịch.
// 8. Trả về đối tượng LoyaltyAccount đã được cập nhật.
// =========================================================================================
// Gợi ý cho Copilot:
func (s *SmartContract) RedeemPoints(ctx contractapi.TransactionContextInterface, customerID string, amount int, description string) (*LoyaltyAccount, error) {
	// === Validation đầu vào ===
	if customerID == "" {
		return nil, fmt.Errorf("customer ID cannot be empty")
	}
	// 2. Kiểm tra amount phải là số nguyên dương
	if amount <= 0 {
		return nil, fmt.Errorf("amount must be a positive integer, got: %d", amount)
	}

	// 1. Tìm tài khoản Loyalty theo customerID
	accountJSON, err := ctx.GetStub().GetState(customerID)
	if err != nil {
		return nil, fmt.Errorf("failed to read account from world state: %v", err)
	}
	if accountJSON == nil {
		return nil, fmt.Errorf("loyalty account with customer ID '%s' does not exist", customerID)
	}

	// 3. Deserialize tài khoản để đọc số dư hiện tại
	var account LoyaltyAccount
	err = json.Unmarshal(accountJSON, &account)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal account data: %v", err)
	}

	// 4. KIỂM TRA QUAN TRỌNG: Số dư hiện tại phải >= số điểm muốn quy đổi
	if account.Balance < amount {
		return nil, fmt.Errorf("insufficient balance: current balance is %d, requested amount is %d", account.Balance, amount)
	}

	// 5. Tính số dư mới = số dư cũ - amount
	oldBalance := account.Balance
	account.Balance = oldBalance - amount
	account.LastUpdated = time.Now().UTC().Format(time.RFC3339)

	// 6. Cập nhật lại đối tượng LoyaltyAccount vào World State
	updatedAccountJSON, err := json.Marshal(account)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal updated account: %v", err)
	}

	err = ctx.GetStub().PutState(customerID, updatedAccountJSON)
	if err != nil {
		return nil, fmt.Errorf("failed to update account in world state: %v", err)
	}

	// 7. Tạo và phát ra sự kiện "RedeemPointsEvent"
	transaction := LoyaltyTransaction{
		TransactionID: ctx.GetStub().GetTxID(),
		CustomerID:    customerID,
		Type:          "REDEEM",
		Amount:        amount,
		Timestamp:     account.LastUpdated,
		Description:   description,
	}

	transactionJSON, err := json.Marshal(transaction)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal transaction event: %v", err)
	}

	err = ctx.GetStub().SetEvent("RedeemPointsEvent", transactionJSON)
	if err != nil {
		return nil, fmt.Errorf("failed to set event for transaction: %v", err)
	}

	// 8. Trả về đối tượng LoyaltyAccount đã được cập nhật
	return &account, nil
}

// =========================================================================================
// UC-006: Chuyển điểm Loyalty
// Yêu cầu: FRS-006 (Chức năng mở rộng)
//
// Logic chính:
// 1. Lấy thông tin tài khoản nguồn (source) và tài khoản đích (target) từ sổ cái.
// 2. Kiểm tra cả hai tài khoản phải tồn tại. Nếu một trong hai không tồn tại -> trả về lỗi.
// 3. Kiểm tra các điều kiện đầu vào:
//    - `amount` phải là số nguyên dương (>0).
//    - Tài khoản nguồn và đích phải khác nhau (`sourceCustomerID != targetCustomerID`).
// 4. KIỂM TRA QUAN TRỌNG: Số dư của tài khoản nguồn phải lớn hơn hoặc bằng số điểm muốn chuyển. Nếu không -> trả về lỗi.
// 5. Trừ điểm từ tài khoản nguồn và cộng điểm vào tài khoản đích.
// 6. Cập nhật lại cả hai đối tượng tài khoản vào World State.
// 7. Tạo và phát ra hai sự kiện:
//    - "TransferOutEvent" cho tài khoản nguồn.
//    - "TransferInEvent" cho tài khoản đích.
// 8. Trả về thông báo thành công. (Hàm này không cần trả về đối tượng tài khoản, chỉ cần nil error là đủ).
// =========================================================================================
// Gợi ý cho Copilot:
func (s *SmartContract) TransferPoints(ctx contractapi.TransactionContextInterface, sourceCustomerID string, targetCustomerID string, amount int, description string) error {
	// === Validation đầu vào ===
	if sourceCustomerID == "" {
		return fmt.Errorf("source customer ID cannot be empty")
	}
	if targetCustomerID == "" {
		return fmt.Errorf("target customer ID cannot be empty")
	}
	// 3. Kiểm tra tài khoản nguồn và đích phải khác nhau
	if sourceCustomerID == targetCustomerID {
		return fmt.Errorf("source and target customer IDs must be different")
	}
	// 3. Kiểm tra amount phải là số nguyên dương
	if amount <= 0 {
		return fmt.Errorf("amount must be a positive integer, got: %d", amount)
	}

	// 1. & 2. Lấy thông tin tài khoản nguồn (source)
	sourceAccountJSON, err := ctx.GetStub().GetState(sourceCustomerID)
	if err != nil {
		return fmt.Errorf("failed to read source account from world state: %v", err)
	}
	if sourceAccountJSON == nil {
		return fmt.Errorf("source loyalty account with customer ID '%s' does not exist", sourceCustomerID)
	}

	// 1. & 2. Lấy thông tin tài khoản đích (target)
	targetAccountJSON, err := ctx.GetStub().GetState(targetCustomerID)
	if err != nil {
		return fmt.Errorf("failed to read target account from world state: %v", err)
	}
	if targetAccountJSON == nil {
		return fmt.Errorf("target loyalty account with customer ID '%s' does not exist", targetCustomerID)
	}

	// Deserialize cả hai tài khoản
	var sourceAccount LoyaltyAccount
	err = json.Unmarshal(sourceAccountJSON, &sourceAccount)
	if err != nil {
		return fmt.Errorf("failed to unmarshal source account data: %v", err)
	}

	var targetAccount LoyaltyAccount
	err = json.Unmarshal(targetAccountJSON, &targetAccount)
	if err != nil {
		return fmt.Errorf("failed to unmarshal target account data: %v", err)
	}

	// 4. KIỂM TRA QUAN TRỌNG: Số dư của tài khoản nguồn phải >= số điểm muốn chuyển
	if sourceAccount.Balance < amount {
		return fmt.Errorf("insufficient balance in source account: current balance is %d, requested amount is %d", sourceAccount.Balance, amount)
	}

	// 5. Trừ điểm từ tài khoản nguồn và cộng điểm vào tài khoản đích
	currentTime := time.Now().UTC().Format(time.RFC3339)
	
	sourceAccount.Balance -= amount
	sourceAccount.LastUpdated = currentTime
	
	targetAccount.Balance += amount
	targetAccount.LastUpdated = currentTime

	// 6. Cập nhật lại cả hai đối tượng tài khoản vào World State
	updatedSourceJSON, err := json.Marshal(sourceAccount)
	if err != nil {
		return fmt.Errorf("failed to marshal updated source account: %v", err)
	}

	updatedTargetJSON, err := json.Marshal(targetAccount)
	if err != nil {
		return fmt.Errorf("failed to marshal updated target account: %v", err)
	}

	err = ctx.GetStub().PutState(sourceCustomerID, updatedSourceJSON)
	if err != nil {
		return fmt.Errorf("failed to update source account in world state: %v", err)
	}

	err = ctx.GetStub().PutState(targetCustomerID, updatedTargetJSON)
	if err != nil {
		return fmt.Errorf("failed to update target account in world state: %v", err)
	}

	// 7. Tạo và phát ra hai sự kiện
	txID := ctx.GetStub().GetTxID()

	// Sự kiện "TransferOutEvent" cho tài khoản nguồn
	transferOutTransaction := LoyaltyTransaction{
		TransactionID: txID,
		CustomerID:    sourceCustomerID,
		Type:          "TRANSFER_OUT",
		Amount:        amount,
		Timestamp:     currentTime,
		Description:   fmt.Sprintf("Transfer to %s: %s", targetCustomerID, description),
	}

	transferOutJSON, err := json.Marshal(transferOutTransaction)
	if err != nil {
		return fmt.Errorf("failed to marshal transfer out transaction: %v", err)
	}

	err = ctx.GetStub().SetEvent("TransferOutEvent", transferOutJSON)
	if err != nil {
		return fmt.Errorf("failed to set transfer out event: %v", err)
	}

	// Sự kiện "TransferInEvent" cho tài khoản đích
	transferInTransaction := LoyaltyTransaction{
		TransactionID: txID,
		CustomerID:    targetCustomerID,
		Type:          "TRANSFER_IN",
		Amount:        amount,
		Timestamp:     currentTime,
		Description:   fmt.Sprintf("Transfer from %s: %s", sourceCustomerID, description),
	}

	transferInJSON, err := json.Marshal(transferInTransaction)
	if err != nil {
		return fmt.Errorf("failed to marshal transfer in transaction: %v", err)
	}

	err = ctx.GetStub().SetEvent("TransferInEvent", transferInJSON)
	if err != nil {
		return fmt.Errorf("failed to set transfer in event: %v", err)
	}

	// 8. Trả về thành công (nil error)
	return nil
}

// =========================================================================================
// UC-004: Truy vấn số dư Loyalty
// Yêu cầu: FRS-004
//
// Logic chính:
// 1. Lấy trạng thái của tài khoản từ sổ cái bằng `customerID`.
// 2. Nếu không tìm thấy tài khoản -> trả về lỗi.
// 3. Nếu tìm thấy, deserialize dữ liệu JSON thành đối tượng LoyaltyAccount.
// 4. Trả về đối tượng LoyaltyAccount.
// =========================================================================================
// Gợi ý cho Copilot:
func (s *SmartContract) QueryLoyaltyAccount(ctx contractapi.TransactionContextInterface, customerID string) (*LoyaltyAccount, error) {
	// === Validation đầu vào ===
	if customerID == "" {
		return nil, fmt.Errorf("customer ID cannot be empty")
	}

	// 1. Lấy trạng thái của tài khoản từ sổ cái bằng customerID
	accountJSON, err := ctx.GetStub().GetState(customerID)
	if err != nil {
		return nil, fmt.Errorf("failed to read account from world state: %v", err)
	}

	// 2. Nếu không tìm thấy tài khoản -> trả về lỗi
	if accountJSON == nil {
		return nil, fmt.Errorf("loyalty account with customer ID '%s' does not exist", customerID)
	}

	// 3. Deserialize dữ liệu JSON thành đối tượng LoyaltyAccount
	var account LoyaltyAccount
	err = json.Unmarshal(accountJSON, &account)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal account data: %v", err)
	}

	// 4. Trả về đối tượng LoyaltyAccount
	return &account, nil
}

// =========================================================================================
// UC-005: Truy vấn lịch sử giao dịch Loyalty
// Yêu cầu: FRS-005
//
// Logic chính:
// 1. Sử dụng hàm `GetHistoryForKey` của Fabric để lấy một iterator cho tất cả các thay đổi lịch sử của `customerID`.
// 2. Lặp qua iterator.
// 3. Với mỗi bản ghi lịch sử, bỏ qua nếu nó là bản ghi xóa (IsDelete).
// 4. Deserialize giá trị của bản ghi thành một đối tượng LoyaltyAccount (để lấy thông tin về trạng thái tại thời điểm đó).
// 5. Tạo một đối tượng `historyItem` chứa thông tin TransactionID, Timestamp và trạng thái tài khoản.
// 6. Thêm `historyItem` vào một danh sách kết quả.
// 7. Trả về danh sách kết quả.
// =========================================================================================
// Gợi ý cho Copilot:
// HistoryQueryResult cấu trúc dữ liệu trả về cho truy vấn lịch sử
type HistoryQueryResult struct {
	Record    *LoyaltyAccount `json:"record"`
	TxId      string          `json:"txId"`
	Timestamp time.Time       `json:"timestamp"`
	IsDelete  bool            `json:"isDelete"`
}

func (s *SmartContract) QueryLoyaltyHistory(ctx contractapi.TransactionContextInterface, customerID string) ([]*HistoryQueryResult, error) {
	// 1. Sử dụng hàm `GetHistoryForKey` của Fabric để lấy một iterator cho tất cả các thay đổi lịch sử của `customerID`.
	historyIterator, err := ctx.GetStub().GetHistoryForKey(customerID)
	if err != nil {
		return nil, fmt.Errorf("failed to get history for key '%s': %v", customerID, err)
	}
	defer historyIterator.Close()

	// 2. Lặp qua iterator.
	var results []*HistoryQueryResult
	for historyIterator.HasNext() {
		// 3. Với mỗi bản ghi lịch sử, bỏ qua nếu nó là bản ghi xóa (IsDelete).
		historyRecord, err := historyIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate history: %v", err)
		}
		if historyRecord.IsDelete {
			continue
		}

		// 4. Deserialize giá trị của bản ghi thành một đối tượng LoyaltyAccount (để lấy thông tin về trạng thái tại thời điểm đó).
		var account LoyaltyAccount
		err = json.Unmarshal(historyRecord.Value, &account)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal history record: %v", err)
		}

		// 5. Tạo một đối tượng `historyItem` chứa thông tin TransactionID, Timestamp và trạng thái tài khoản.
		historyItem := &HistoryQueryResult{
			Record:    &account,
			TxId:      historyRecord.TxId,
			Timestamp: historyRecord.Timestamp,
			IsDelete:  historyRecord.IsDelete,
		}

		// 6. Thêm `historyItem` vào một danh sách kết quả.
		results = append(results, historyItem)
	}

	// 7. Trả về danh sách kết quả.
	return results, nil
}