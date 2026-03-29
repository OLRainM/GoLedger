package middleware

import (
	"strings"

	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/GoLedger/backend/internal/pkg/jwt"
	"github.com/GoLedger/backend/internal/pkg/response"
	"github.com/gin-gonic/gin"
	jwtv5 "github.com/golang-jwt/jwt/v5"
)

const ContextUserID = "user_id"

// Auth is a JWT authentication middleware.
// It extracts the token from the Authorization header, validates it,
// and injects user_id into the Gin context.
func Auth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			response.Fail(c, errs.ErrUnauthorized)
			c.Abort()
			return
		}

		// Expect format: "Bearer <token>"
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			response.Fail(c, errs.ErrUnauthorized)
			c.Abort()
			return
		}

		claims, err := jwt.ParseToken(parts[1])
		if err != nil {
			if isExpiredError(err) {
				response.Fail(c, errs.ErrTokenExpired)
			} else {
				response.Fail(c, errs.ErrUnauthorized)
			}
			c.Abort()
			return
		}

		c.Set(ContextUserID, claims.UserID)
		c.Next()
	}
}

// GetUserID extracts user_id from the Gin context. Must be called after Auth middleware.
func GetUserID(c *gin.Context) uint64 {
	val, exists := c.Get(ContextUserID)
	if !exists {
		return 0
	}
	uid, ok := val.(uint64)
	if !ok {
		return 0
	}
	return uid
}

func isExpiredError(err error) bool {
	return strings.Contains(err.Error(), jwtv5.ErrTokenExpired.Error())
}

