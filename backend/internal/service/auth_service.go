package service

import (
	"github.com/GoLedger/backend/internal/model"
	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/GoLedger/backend/internal/pkg/jwt"
	"github.com/GoLedger/backend/internal/repository"
	"github.com/gocraft/dbr/v2"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	userRepo    *repository.UserRepo
	categoryRepo *repository.CategoryRepo
	sess        *dbr.Session
}

func NewAuthService(userRepo *repository.UserRepo, categoryRepo *repository.CategoryRepo, sess *dbr.Session) *AuthService {
	return &AuthService{userRepo: userRepo, categoryRepo: categoryRepo, sess: sess}
}

type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=8"`
	Nickname string `json:"nickname"`
}

type RegisterResponse struct {
	ID       uint64 `json:"id"`
	Email    string `json:"email"`
	Nickname string `json:"nickname"`
}

// Register creates a new user account and default categories.
func (s *AuthService) Register(req *RegisterRequest) (*RegisterResponse, error) {
	// Check duplicate email
	existing, err := s.userRepo.GetByEmail(req.Email)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return nil, errs.New(errs.ErrUnprocessable, "该邮箱已被注册")
	}

	// Hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), 10)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		Email:        req.Email,
		PasswordHash: string(hash),
		Nickname:     req.Nickname,
	}

	// Use transaction: create user + default categories
	tx, err := s.sess.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.RollbackUnlessCommitted()

	// Insert user via raw tx
	result, err := tx.InsertInto("users").
		Columns("email", "password_hash", "nickname").
		Values(user.Email, user.PasswordHash, user.Nickname).
		Exec()
	if err != nil {
		return nil, err
	}
	id, _ := result.LastInsertId()
	userID := uint64(id)

	// Create default categories
	if err := s.categoryRepo.CreateDefaults(tx, userID); err != nil {
		return nil, err
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return &RegisterResponse{
		ID:       userID,
		Email:    req.Email,
		Nickname: req.Nickname,
	}, nil
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	Token     string `json:"token"`
	ExpiresAt string `json:"expires_at"`
}

// Login validates credentials and returns a JWT token.
func (s *AuthService) Login(req *LoginRequest) (*LoginResponse, error) {
	user, err := s.userRepo.GetByEmail(req.Email)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errs.ErrUnauthorized
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, errs.ErrUnauthorized
	}

	token, expiresAt, err := jwt.GenerateToken(user.ID)
	if err != nil {
		return nil, err
	}

	return &LoginResponse{
		Token:     token,
		ExpiresAt: expiresAt.Format("2006-01-02T15:04:05Z"),
	}, nil
}

