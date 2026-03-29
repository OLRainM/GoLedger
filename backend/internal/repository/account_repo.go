package repository

import (
	"github.com/GoLedger/backend/internal/model"
	"github.com/gocraft/dbr/v2"
)

type AccountRepo struct {
	sess *dbr.Session
}

func NewAccountRepo(sess *dbr.Session) *AccountRepo {
	return &AccountRepo{sess: sess}
}

// Create inserts a new account and returns the inserted ID.
func (r *AccountRepo) Create(a *model.Account) (uint64, error) {
	result, err := r.sess.InsertInto("accounts").
		Columns("user_id", "name", "type", "balance", "initial_balance").
		Values(a.UserID, a.Name, a.Type, a.Balance, a.InitialBalance).
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

// ListByUserID returns all accounts for a given user.
func (r *AccountRepo) ListByUserID(userID uint64) ([]model.Account, error) {
	var accounts []model.Account
	_, err := r.sess.Select("*").
		From("accounts").
		Where("user_id = ?", userID).
		OrderAsc("created_at").
		Load(&accounts)
	if err != nil {
		return nil, err
	}
	return accounts, nil
}

// GetByID returns a single account by ID and user_id (for ownership check).
func (r *AccountRepo) GetByID(id, userID uint64) (*model.Account, error) {
	var a model.Account
	err := r.sess.Select("*").
		From("accounts").
		Where("id = ? AND user_id = ?", id, userID).
		LoadOne(&a)
	if err != nil {
		if err == dbr.ErrNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &a, nil
}

// Update modifies account name, type, and is_active.
func (r *AccountRepo) Update(a *model.Account) error {
	_, err := r.sess.Update("accounts").
		Set("name", a.Name).
		Set("type", a.Type).
		Set("is_active", a.IsActive).
		Where("id = ? AND user_id = ?", a.ID, a.UserID).
		Exec()
	return err
}

// CountByUserID returns the number of accounts the user has.
func (r *AccountRepo) CountByUserID(userID uint64) (int64, error) {
	var count int64
	err := r.sess.Select("COUNT(*)").
		From("accounts").
		Where("user_id = ?", userID).
		LoadOne(&count)
	return count, err
}

// UpdateBalanceOptimistic updates balance using optimistic locking within a transaction.
// Returns the number of affected rows (0 means version conflict).
func (r *AccountRepo) UpdateBalanceOptimistic(tx *dbr.Tx, id uint64, delta int64, currentVersion uint32) (int64, error) {
	result, err := tx.Update("accounts").
		Set("balance", dbr.Expr("balance + ?", delta)).
		Set("version", dbr.Expr("version + 1")).
		Where("id = ? AND version = ?", id, currentVersion).
		Exec()
	if err != nil {
		return 0, err
	}
	return result.RowsAffected()
}

