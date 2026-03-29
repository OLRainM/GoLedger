package model

import "time"

// Account represents a user's financial account.
// Balance and InitialBalance are stored in cents (分).
type Account struct {
	ID             uint64    `db:"id" json:"id"`
	UserID         uint64    `db:"user_id" json:"user_id"`
	Name           string    `db:"name" json:"name"`
	Type           string    `db:"type" json:"type"` // cash | bank_card | e_wallet | other
	Balance        int64     `db:"balance" json:"balance"`
	InitialBalance int64     `db:"initial_balance" json:"initial_balance"`
	IsActive       int8      `db:"is_active" json:"is_active"`
	Version        uint32    `db:"version" json:"version"`
	CreatedAt      time.Time `db:"created_at" json:"created_at"`
	UpdatedAt      time.Time `db:"updated_at" json:"updated_at"`
}

// Valid account types.
const (
	AccountTypeCash     = "cash"
	AccountTypeBankCard = "bank_card"
	AccountTypeEWallet  = "e_wallet"
	AccountTypeOther    = "other"
)

// ValidAccountTypes returns the list of allowed account types.
func ValidAccountTypes() []string {
	return []string{AccountTypeCash, AccountTypeBankCard, AccountTypeEWallet, AccountTypeOther}
}

// IsValidAccountType checks if the given type string is valid.
func IsValidAccountType(t string) bool {
	for _, v := range ValidAccountTypes() {
		if v == t {
			return true
		}
	}
	return false
}

