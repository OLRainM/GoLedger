package model

import "time"

// Transaction represents a single income or expense record.
// Amount is stored in cents (分).
type Transaction struct {
	ID            uint64     `db:"id" json:"id"`
	UserID        uint64     `db:"user_id" json:"user_id"`
	AccountID     uint64     `db:"account_id" json:"account_id"`
	CategoryID    uint64     `db:"category_id" json:"category_id"`
	Type          string     `db:"type" json:"type"` // income | expense
	Amount        int64      `db:"amount" json:"amount"`
	Note          string     `db:"note" json:"note"`
	TransactionAt time.Time  `db:"transaction_at" json:"transaction_at"`
	SourceType    string     `db:"source_type" json:"source_type"` // manual | ocr
	Version       uint32     `db:"version" json:"version"`
	CreatedAt     time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt     time.Time  `db:"updated_at" json:"updated_at"`
	DeletedAt     *time.Time `db:"deleted_at" json:"deleted_at,omitempty"`
}

// TransactionWithNames is used for list queries with joined category/account names.
type TransactionWithNames struct {
	Transaction
	CategoryName string `db:"category_name" json:"category_name"`
	AccountName  string `db:"account_name" json:"account_name"`
}

const (
	TransactionTypeIncome  = "income"
	TransactionTypeExpense = "expense"
	SourceTypeManual       = "manual"
)

