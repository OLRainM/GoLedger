package service

import (
	"github.com/GoLedger/backend/internal/model"
	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/GoLedger/backend/internal/repository"
)

type CategoryService struct {
	categoryRepo *repository.CategoryRepo
}

func NewCategoryService(categoryRepo *repository.CategoryRepo) *CategoryService {
	return &CategoryService{categoryRepo: categoryRepo}
}

type CreateCategoryRequest struct {
	Name string `json:"name" binding:"required,max=50"`
	Type string `json:"type" binding:"required"`
}

// Create creates a new user-defined category.
func (s *CategoryService) Create(userID uint64, req *CreateCategoryRequest) (*model.Category, error) {
	if req.Type != model.CategoryTypeIncome && req.Type != model.CategoryTypeExpense {
		return nil, errs.New(errs.ErrBadRequest, "分类类型必须是 income 或 expense")
	}

	cat := &model.Category{
		UserID:   userID,
		Name:     req.Name,
		Type:     req.Type,
		IsSystem: 0,
		IsActive: 1,
	}

	id, err := s.categoryRepo.Create(cat)
	if err != nil {
		// Check for duplicate key error (MySQL error 1062)
		if isDuplicateError(err) {
			return nil, errs.New(errs.ErrUnprocessable, "该分类名已存在")
		}
		return nil, err
	}

	cat.ID = id
	return cat, nil
}

// List returns categories for the user, optionally filtered by type.
func (s *CategoryService) List(userID uint64, catType string) ([]model.Category, error) {
	return s.categoryRepo.ListByUserID(userID, catType)
}

type UpdateCategoryRequest struct {
	Name     *string `json:"name" binding:"omitempty,max=50"`
	IsActive *int8   `json:"is_active"`
}

// Update modifies a category's name or active status.
func (s *CategoryService) Update(userID, categoryID uint64, req *UpdateCategoryRequest) (*model.Category, error) {
	cat, err := s.categoryRepo.GetByID(categoryID, userID)
	if err != nil {
		return nil, err
	}
	if cat == nil {
		return nil, errs.ErrNotFound
	}

	if req.Name != nil {
		cat.Name = *req.Name
	}
	if req.IsActive != nil {
		cat.IsActive = *req.IsActive
	}

	if err := s.categoryRepo.Update(cat); err != nil {
		if isDuplicateError(err) {
			return nil, errs.New(errs.ErrUnprocessable, "该分类名已存在")
		}
		return nil, err
	}
	return cat, nil
}

// isDuplicateError checks if the error is a MySQL duplicate entry error.
func isDuplicateError(err error) bool {
	return err != nil && (contains(err.Error(), "Duplicate entry") || contains(err.Error(), "1062"))
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && searchSubstring(s, substr)
}

func searchSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

