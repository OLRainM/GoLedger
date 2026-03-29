package repository

import (
	"github.com/GoLedger/backend/internal/model"
	"github.com/gocraft/dbr/v2"
)

type UserRepo struct {
	sess *dbr.Session
}

func NewUserRepo(sess *dbr.Session) *UserRepo {
	return &UserRepo{sess: sess}
}

// Create inserts a new user and returns the inserted ID.
func (r *UserRepo) Create(user *model.User) (uint64, error) {
	result, err := r.sess.InsertInto("users").
		Columns("email", "password_hash", "nickname").
		Values(user.Email, user.PasswordHash, user.Nickname).
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

// GetByEmail finds a user by email. Returns nil if not found.
func (r *UserRepo) GetByEmail(email string) (*model.User, error) {
	var user model.User
	err := r.sess.Select("*").
		From("users").
		Where("email = ?", email).
		LoadOne(&user)
	if err != nil {
		if err == dbr.ErrNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

// GetByID finds a user by ID. Returns nil if not found.
func (r *UserRepo) GetByID(id uint64) (*model.User, error) {
	var user model.User
	err := r.sess.Select("*").
		From("users").
		Where("id = ?", id).
		LoadOne(&user)
	if err != nil {
		if err == dbr.ErrNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

