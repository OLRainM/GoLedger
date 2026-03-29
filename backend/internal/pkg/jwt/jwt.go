package jwt

import (
	"time"

	jwtv5 "github.com/golang-jwt/jwt/v5"
)

var jwtSecret []byte
var expireDuration time.Duration

// Init sets the JWT secret and expiration duration. Must be called at startup.
func Init(secret string, expire time.Duration) {
	jwtSecret = []byte(secret)
	expireDuration = expire
}

// Claims holds the JWT payload.
type Claims struct {
	UserID uint64 `json:"user_id"`
	jwtv5.RegisteredClaims
}

// GenerateToken creates a new JWT token for the given user ID.
func GenerateToken(userID uint64) (string, time.Time, error) {
	expiresAt := time.Now().Add(expireDuration)
	claims := Claims{
		UserID: userID,
		RegisteredClaims: jwtv5.RegisteredClaims{
			ExpiresAt: jwtv5.NewNumericDate(expiresAt),
			IssuedAt:  jwtv5.NewNumericDate(time.Now()),
		},
	}

	token := jwtv5.NewWithClaims(jwtv5.SigningMethodHS256, claims)
	tokenStr, err := token.SignedString(jwtSecret)
	if err != nil {
		return "", time.Time{}, err
	}
	return tokenStr, expiresAt, nil
}

// ParseToken validates and parses a JWT token string.
func ParseToken(tokenStr string) (*Claims, error) {
	token, err := jwtv5.ParseWithClaims(tokenStr, &Claims{}, func(t *jwtv5.Token) (interface{}, error) {
		return jwtSecret, nil
	})
	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}
	return nil, jwtv5.ErrSignatureInvalid
}

