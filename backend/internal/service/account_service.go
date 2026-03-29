package service

import (
	"github.com/GoLedger/backend/internal/model"
	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/GoLedger/backend/internal/repository"
)

const MaxAccountsPerUser = 20

type AccountService struct {
	accountRepo *repository.AccountRepo
}

func NewAccountService(accountRepo *repository.AccountRepo) *AccountService {
	return &AccountService{accountRepo: accountRepo}
}

type CreateAccountRequest struct {
	Name           string `json:"name" binding:"required,max=50"`
	Type           string `json:"type" binding:"required"`
	InitialBalance int64  `json:"initial_balance"` // unit: cents (分)
}

// Create creates a new account for the user.
func (s *AccountService) Create(userID uint64, req *CreateAccountRequest) (*model.Account, error) {
	// Validate account type
	if !model.IsValidAccountType(req.Type) {
		return nil, errs.New(errs.ErrBadRequest, "无效的账户类型")
	}

	// Check account limit
	count, err := s.accountRepo.CountByUserID(userID)
	if err != nil {
		return nil, err
	}
	if count >= MaxAccountsPerUser {
		return nil, errs.New(errs.ErrUnprocessable, "账户数量已达上限(20)")
	}

	account := &model.Account{
		UserID:         userID,
		Name:           req.Name,
		Type:           req.Type,
		Balance:        req.InitialBalance,
		InitialBalance: req.InitialBalance,
		IsActive:       1,
	}

	id, err := s.accountRepo.Create(account)
	if err != nil {
		return nil, err
	}

	account.ID = id
	account.Version = 1
	return account, nil
}

// List returns all accounts for the user.
func (s *AccountService) List(userID uint64) ([]model.Account, error) {
	return s.accountRepo.ListByUserID(userID)
}

type UpdateAccountRequest struct {
	Name     *string `json:"name" binding:"omitempty,max=50"`
	Type     *string `json:"type"`
	IsActive *int8   `json:"is_active"`
}

// Update modifies an existing account's name, type, or active status.
func (s *AccountService) Update(userID, accountID uint64, req *UpdateAccountRequest) (*model.Account, error) {
	account, err := s.accountRepo.GetByID(accountID, userID)
	if err != nil {
		return nil, err
	}
	if account == nil {
		return nil, errs.ErrNotFound
	}

	if req.Name != nil {
		account.Name = *req.Name
	}
	if req.Type != nil {
		if !model.IsValidAccountType(*req.Type) {
			return nil, errs.New(errs.ErrBadRequest, "无效的账户类型")
		}
		account.Type = *req.Type
	}
	if req.IsActive != nil {
		account.IsActive = *req.IsActive
	}

	if err := s.accountRepo.Update(account); err != nil {
		return nil, err
	}
	return account, nil
}

