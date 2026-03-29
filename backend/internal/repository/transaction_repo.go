package repository

import (
	"time"

	"github.com/GoLedger/backend/internal/model"
	"github.com/gocraft/dbr/v2"
)

type TransactionRepo struct {
	sess *dbr.Session
}

func NewTransactionRepo(sess *dbr.Session) *TransactionRepo {
	return &TransactionRepo{sess: sess}
}

// CreateInTx inserts a transaction record within the given database transaction.
func (r *TransactionRepo) CreateInTx(tx *dbr.Tx, t *model.Transaction) (uint64, error) {
	result, err := tx.InsertInto("transactions").
		Columns("user_id", "account_id", "category_id", "type", "amount", "note", "transaction_at", "source_type").
		Values(t.UserID, t.AccountID, t.CategoryID, t.Type, t.Amount, t.Note, t.TransactionAt, t.SourceType).
		Exec()
	if err != nil {
		return 0, err
	}
	id, err := result.LastInsertId()
	if err != nil {
		return 0, err
	}
	return uint64(id), nil
}

// GetByID returns a single transaction by ID and user_id (soft-delete aware).
func (r *TransactionRepo) GetByID(id, userID uint64) (*model.Transaction, error) {
	var t model.Transaction
	err := r.sess.Select("*").
		From("transactions").
		Where("id = ? AND user_id = ? AND deleted_at IS NULL", id, userID).
		LoadOne(&t)
	if err != nil {
		if err == dbr.ErrNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &t, nil
}

// ListFilter holds the filter parameters for listing transactions.
type ListFilter struct {
	UserID     uint64
	AccountID  *uint64
	CategoryID *uint64
	Type       string
	StartDate  *time.Time
	EndDate    *time.Time
	Page       int
	PageSize   int
}

// List returns paginated transactions with optional filters.
func (r *TransactionRepo) List(f ListFilter) ([]model.TransactionWithNames, int64, error) {
	// Count total
	countQ := r.sess.Select("COUNT(*)").
		From("transactions").
		Where("user_id = ? AND deleted_at IS NULL", f.UserID)
	countQ = applyFilters(countQ, f)

	var total int64
	if err := countQ.LoadOne(&total); err != nil {
		return nil, 0, err
	}

	// Query list with joined names
	q := r.sess.Select(
		"t.*",
		"c.name AS category_name",
		"a.name AS account_name",
	).
		From(dbr.I("transactions").As("t")).
		LeftJoin(dbr.I("categories").As("c"), "t.category_id = c.id").
		LeftJoin(dbr.I("accounts").As("a"), "t.account_id = a.id").
		Where("t.user_id = ? AND t.deleted_at IS NULL", f.UserID)
	q = applyFiltersAliased(q, f)
	q = q.OrderDir("t.transaction_at", false). // DESC
							Limit(uint64(f.PageSize)).
							Offset(uint64((f.Page - 1) * f.PageSize))

	var list []model.TransactionWithNames
	if _, err := q.Load(&list); err != nil {
		return nil, 0, err
	}
	return list, total, nil
}

// UpdateInTx updates a transaction within a database transaction.
func (r *TransactionRepo) UpdateInTx(tx *dbr.Tx, t *model.Transaction) (int64, error) {
	result, err := tx.Update("transactions").
		Set("account_id", t.AccountID).
		Set("category_id", t.CategoryID).
		Set("type", t.Type).
		Set("amount", t.Amount).
		Set("note", t.Note).
		Set("transaction_at", t.TransactionAt).
		Set("version", dbr.Expr("version + 1")).
		Where("id = ? AND user_id = ? AND version = ? AND deleted_at IS NULL", t.ID, t.UserID, t.Version).
		Exec()
	if err != nil {
		return 0, err
	}
	return result.RowsAffected()
}

// SoftDeleteInTx marks a transaction as deleted within a database transaction.
func (r *TransactionRepo) SoftDeleteInTx(tx *dbr.Tx, id, userID uint64, version uint32) (int64, error) {
	now := time.Now()
	result, err := tx.Update("transactions").
		Set("deleted_at", now).
		Set("version", dbr.Expr("version + 1")).
		Where("id = ? AND user_id = ? AND version = ? AND deleted_at IS NULL", id, userID, version).
		Exec()
	if err != nil {
		return 0, err
	}
	return result.RowsAffected()
}

// MonthlySummary holds the result of a monthly aggregation query.
type MonthlySummary struct {
	TotalIncome  int64 `db:"total_income" json:"total_income"`
	TotalExpense int64 `db:"total_expense" json:"total_expense"`
}

// GetMonthlySummary returns the sum of income and expense for a given year/month.
func (r *TransactionRepo) GetMonthlySummary(userID uint64, year, month int) (*MonthlySummary, error) {
	var summary MonthlySummary
	err := r.sess.SelectBySql(`
		SELECT
			COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_income,
			COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_expense
		FROM transactions
		WHERE user_id = ? AND deleted_at IS NULL
			AND YEAR(transaction_at) = ? AND MONTH(transaction_at) = ?
	`, userID, year, month).LoadOne(&summary)
	if err != nil {
		if err == dbr.ErrNotFound {
			return &MonthlySummary{}, nil
		}
		return nil, err
	}
	return &summary, nil
}

// applyFilters adds optional WHERE clauses to a query builder (non-aliased table).
func applyFilters(q *dbr.SelectStmt, f ListFilter) *dbr.SelectStmt {
	if f.AccountID != nil {
		q = q.Where("account_id = ?", *f.AccountID)
	}
	if f.CategoryID != nil {
		q = q.Where("category_id = ?", *f.CategoryID)
	}
	if f.Type != "" {
		q = q.Where("type = ?", f.Type)
	}
	if f.StartDate != nil {
		q = q.Where("transaction_at >= ?", *f.StartDate)
	}
	if f.EndDate != nil {
		q = q.Where("transaction_at <= ?", *f.EndDate)
	}
	return q
}

// applyFiltersAliased adds optional WHERE clauses with "t." table alias prefix.
func applyFiltersAliased(q *dbr.SelectStmt, f ListFilter) *dbr.SelectStmt {
	if f.AccountID != nil {
		q = q.Where("t.account_id = ?", *f.AccountID)
	}
	if f.CategoryID != nil {
		q = q.Where("t.category_id = ?", *f.CategoryID)
	}
	if f.Type != "" {
		q = q.Where("t.type = ?", f.Type)
	}
	if f.StartDate != nil {
		q = q.Where("t.transaction_at >= ?", *f.StartDate)
	}
	if f.EndDate != nil {
		q = q.Where("t.transaction_at <= ?", *f.EndDate)
	}
	return q
}
