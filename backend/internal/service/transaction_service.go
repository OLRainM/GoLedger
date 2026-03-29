package service

import (
	"time"

	"github.com/GoLedger/backend/internal/model"
	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/GoLedger/backend/internal/repository"
	"github.com/gocraft/dbr/v2"
)

type TransactionService struct {
	txnRepo      *repository.TransactionRepo
	accountRepo  *repository.AccountRepo
	categoryRepo *repository.CategoryRepo
	sess         *dbr.Session
}

func NewTransactionService(
	txnRepo *repository.TransactionRepo,
	accountRepo *repository.AccountRepo,
	categoryRepo *repository.CategoryRepo,
	sess *dbr.Session,
) *TransactionService {
	return &TransactionService{
		txnRepo:      txnRepo,
		accountRepo:  accountRepo,
		categoryRepo: categoryRepo,
		sess:         sess,
	}
}

type CreateTransactionRequest struct {
	AccountID     uint64    `json:"account_id" binding:"required"`
	CategoryID    uint64    `json:"category_id" binding:"required"`
	Type          string    `json:"type" binding:"required"`
	Amount        int64     `json:"amount" binding:"required,gt=0"`
	Note          string    `json:"note" binding:"max=200"`
	TransactionAt time.Time `json:"transaction_at" binding:"required"`
}

type CreateTransactionResponse struct {
	ID         uint64 `json:"id"`
	AccountID  uint64 `json:"account_id"`
	NewBalance int64  `json:"new_balance"`
	NewVersion uint32 `json:"new_version"`
}

// Create inserts a new transaction and updates account balance in a single DB transaction.
func (s *TransactionService) Create(userID uint64, req *CreateTransactionRequest) (*CreateTransactionResponse, error) {
	if req.Type != model.TransactionTypeIncome && req.Type != model.TransactionTypeExpense {
		return nil, errs.New(errs.ErrBadRequest, "类型必须是 income 或 expense")
	}
	if req.Amount > 9999999999 {
		return nil, errs.New(errs.ErrBadRequest, "金额超过上限")
	}

	// Verify account exists, belongs to user, and is active
	account, err := s.accountRepo.GetByID(req.AccountID, userID)
	if err != nil {
		return nil, err
	}
	if account == nil {
		return nil, errs.New(errs.ErrNotFound, "账户不存在")
	}
	if account.IsActive == 0 {
		return nil, errs.New(errs.ErrUnprocessable, "该账户已停用, 无法记账")
	}

	// Verify category exists and belongs to user
	cat, err := s.categoryRepo.GetByID(req.CategoryID, userID)
	if err != nil {
		return nil, err
	}
	if cat == nil {
		return nil, errs.New(errs.ErrNotFound, "分类不存在")
	}

	// Calculate balance delta
	delta := req.Amount
	if req.Type == model.TransactionTypeExpense {
		delta = -delta
	}

	// Begin DB transaction
	tx, err := s.sess.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.RollbackUnlessCommitted()

	// Insert transaction record
	txnModel := &model.Transaction{
		UserID:        userID,
		AccountID:     req.AccountID,
		CategoryID:    req.CategoryID,
		Type:          req.Type,
		Amount:        req.Amount,
		Note:          req.Note,
		TransactionAt: req.TransactionAt,
		SourceType:    model.SourceTypeManual,
	}
	txnID, err := s.txnRepo.CreateInTx(tx, txnModel)
	if err != nil {
		return nil, err
	}

	// Update balance with optimistic lock
	affected, err := s.accountRepo.UpdateBalanceOptimistic(tx, req.AccountID, delta, account.Version)
	if err != nil {
		return nil, err
	}
	if affected == 0 {
		return nil, errs.New(errs.ErrConflict, "账户余额版本冲突, 请重试")
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return &CreateTransactionResponse{
		ID:         txnID,
		AccountID:  req.AccountID,
		NewBalance: account.Balance + delta,
		NewVersion: account.Version + 1,
	}, nil
}

// GetByID returns a single transaction.
func (s *TransactionService) GetByID(userID, txnID uint64) (*model.Transaction, error) {
	t, err := s.txnRepo.GetByID(txnID, userID)
	if err != nil {
		return nil, err
	}
	if t == nil {
		return nil, errs.ErrNotFound
	}
	return t, nil
}

// List returns paginated transactions with filters.
func (s *TransactionService) List(f repository.ListFilter) ([]model.TransactionWithNames, int64, error) {
	return s.txnRepo.List(f)
}

type UpdateTransactionRequest struct {
	AccountID     *uint64    `json:"account_id"`
	CategoryID    *uint64    `json:"category_id"`
	Type          *string    `json:"type"`
	Amount        *int64     `json:"amount"`
	Note          *string    `json:"note" binding:"omitempty,max=200"`
	TransactionAt *time.Time `json:"transaction_at"`
	Version       uint32     `json:"version" binding:"required"`
}

// Update modifies a transaction, rolling back old balance and applying new balance.
func (s *TransactionService) Update(userID, txnID uint64, req *UpdateTransactionRequest) error {
	old, err := s.txnRepo.GetByID(txnID, userID)
	if err != nil {
		return err
	}
	if old == nil {
		return errs.ErrNotFound
	}

	// Build updated record
	updated := *old
	if req.AccountID != nil {
		updated.AccountID = *req.AccountID
	}
	if req.CategoryID != nil {
		updated.CategoryID = *req.CategoryID
	}
	if req.Type != nil {
		updated.Type = *req.Type
	}
	if req.Amount != nil {
		updated.Amount = *req.Amount
	}
	if req.Note != nil {
		updated.Note = *req.Note
	}
	if req.TransactionAt != nil {
		updated.TransactionAt = *req.TransactionAt
	}
	updated.Version = req.Version

	// Calculate old delta (reverse) and new delta
	oldDelta := old.Amount
	if old.Type == model.TransactionTypeExpense {
		oldDelta = -oldDelta
	}
	newDelta := updated.Amount
	if updated.Type == model.TransactionTypeExpense {
		newDelta = -newDelta
	}

	// Get account for optimistic lock
	account, err := s.accountRepo.GetByID(updated.AccountID, userID)
	if err != nil {
		return err
	}
	if account == nil {
		return errs.New(errs.ErrNotFound, "账户不存在")
	}

	tx, err := s.sess.Begin()
	if err != nil {
		return err
	}
	defer tx.RollbackUnlessCommitted()

	// Update transaction with optimistic lock
	affected, err := s.txnRepo.UpdateInTx(tx, &updated)
	if err != nil {
		return err
	}
	if affected == 0 {
		return errs.New(errs.ErrConflict, "流水版本冲突, 请重试")
	}

	// Reverse old balance, apply new balance
	balanceDelta := -oldDelta + newDelta
	if balanceDelta != 0 {
		affectedAcc, err := s.accountRepo.UpdateBalanceOptimistic(tx, account.ID, balanceDelta, account.Version)
		if err != nil {
			return err
		}
		if affectedAcc == 0 {
			return errs.New(errs.ErrConflict, "账户余额版本冲突, 请重试")
		}
	}

	return tx.Commit()
}

// Delete soft-deletes a transaction and rolls back its balance impact.
func (s *TransactionService) Delete(userID, txnID uint64, version uint32) error {
	old, err := s.txnRepo.GetByID(txnID, userID)
	if err != nil {
		return err
	}
	if old == nil {
		return errs.ErrNotFound
	}

	// Calculate reverse delta
	reverseDelta := old.Amount
	if old.Type == model.TransactionTypeIncome {
		reverseDelta = -reverseDelta
	}
	// expense was -amount, reverse is +amount (already positive)

	account, err := s.accountRepo.GetByID(old.AccountID, userID)
	if err != nil {
		return err
	}
	if account == nil {
		return errs.New(errs.ErrNotFound, "账户不存在")
	}

	tx, err := s.sess.Begin()
	if err != nil {
		return err
	}
	defer tx.RollbackUnlessCommitted()

	affected, err := s.txnRepo.SoftDeleteInTx(tx, txnID, userID, version)
	if err != nil {
		return err
	}
	if affected == 0 {
		return errs.New(errs.ErrConflict, "流水版本冲突, 请重试")
	}

	affectedAcc, err := s.accountRepo.UpdateBalanceOptimistic(tx, account.ID, reverseDelta, account.Version)
	if err != nil {
		return err
	}
	if affectedAcc == 0 {
		return errs.New(errs.ErrConflict, "账户余额版本冲突, 请重试")
	}

	return tx.Commit()
}
