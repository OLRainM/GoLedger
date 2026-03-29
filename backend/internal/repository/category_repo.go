package repository

import (
	"github.com/GoLedger/backend/internal/model"
	"github.com/gocraft/dbr/v2"
)

type CategoryRepo struct {
	sess *dbr.Session
}

func NewCategoryRepo(sess *dbr.Session) *CategoryRepo {
	return &CategoryRepo{sess: sess}
}

// Create inserts a new category and returns the inserted ID.
func (r *CategoryRepo) Create(c *model.Category) (uint64, error) {
	result, err := r.sess.InsertInto("categories").
		Columns("user_id", "name", "type", "is_system", "is_active").
		Values(c.UserID, c.Name, c.Type, c.IsSystem, c.IsActive).
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

// CreateDefaults batch-inserts all default categories for a new user.
func (r *CategoryRepo) CreateDefaults(tx *dbr.Tx, userID uint64) error {
	// Insert expense defaults
	for _, name := range model.DefaultExpenseCategories {
		_, err := tx.InsertInto("categories").
			Columns("user_id", "name", "type", "is_system", "is_active").
			Values(userID, name, model.CategoryTypeExpense, 1, 1).
			Exec()
		if err != nil {
			return err
		}
	}
	// Insert income defaults
	for _, name := range model.DefaultIncomeCategories {
		_, err := tx.InsertInto("categories").
			Columns("user_id", "name", "type", "is_system", "is_active").
			Values(userID, name, model.CategoryTypeIncome, 1, 1).
			Exec()
		if err != nil {
			return err
		}
	}
	return nil
}

// ListByUserID returns categories for a user, optionally filtered by type.
func (r *CategoryRepo) ListByUserID(userID uint64, catType string) ([]model.Category, error) {
	var categories []model.Category
	q := r.sess.Select("*").
		From("categories").
		Where("user_id = ?", userID)
	if catType != "" {
		q = q.Where("type = ?", catType)
	}
	_, err := q.OrderAsc("id").Load(&categories)
	return categories, err
}

// GetByID returns a single category by ID and user_id.
func (r *CategoryRepo) GetByID(id, userID uint64) (*model.Category, error) {
	var c model.Category
	err := r.sess.Select("*").
		From("categories").
		Where("id = ? AND user_id = ?", id, userID).
		LoadOne(&c)
	if err != nil {
		if err == dbr.ErrNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &c, nil
}

// Update modifies category name and is_active.
func (r *CategoryRepo) Update(c *model.Category) error {
	_, err := r.sess.Update("categories").
		Set("name", c.Name).
		Set("is_active", c.IsActive).
		Where("id = ? AND user_id = ?", c.ID, c.UserID).
		Exec()
	return err
}

