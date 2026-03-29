package model

import "time"

// Category represents a transaction category (income or expense).
type Category struct {
	ID        uint64    `db:"id" json:"id"`
	UserID    uint64    `db:"user_id" json:"user_id"`
	Name      string    `db:"name" json:"name"`
	Type      string    `db:"type" json:"type"` // income | expense
	IsSystem  int8      `db:"is_system" json:"is_system"`
	IsActive  int8      `db:"is_active" json:"is_active"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
	UpdatedAt time.Time `db:"updated_at" json:"updated_at"`
}

const (
	CategoryTypeIncome  = "income"
	CategoryTypeExpense = "expense"
)

// DefaultExpenseCategories are pre-created for new users.
var DefaultExpenseCategories = []string{
	"餐饮", "交通", "购物", "住房", "娱乐", "医疗", "教育", "通讯", "其他支出",
}

// DefaultIncomeCategories are pre-created for new users.
var DefaultIncomeCategories = []string{
	"工资", "奖金", "投资收益", "兼职", "其他收入",
}

