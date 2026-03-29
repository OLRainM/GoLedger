package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// Logger is a request logging middleware using Zap.
// It logs method, path, status, latency, user_id, and client IP for each request.
func Logger(logger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		status := c.Writer.Status()
		clientIP := c.ClientIP()
		method := c.Request.Method

		// Extract user_id (0 if not authenticated)
		userID := GetUserID(c)

		fullPath := path
		if query != "" {
			fullPath = path + "?" + query
		}

		fields := []zap.Field{
			zap.String("method", method),
			zap.String("path", fullPath),
			zap.Int("status", status),
			zap.Duration("latency", latency),
			zap.Uint64("user_id", userID),
			zap.String("client_ip", clientIP),
		}

		// Log errors from Gin context if any
		if len(c.Errors) > 0 {
			fields = append(fields, zap.String("errors", c.Errors.ByType(gin.ErrorTypePrivate).String()))
		}

		switch {
		case status >= 500:
			logger.Error("request", fields...)
		case status >= 400:
			logger.Warn("request", fields...)
		default:
			logger.Info("request", fields...)
		}
	}
}

