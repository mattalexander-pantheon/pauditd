package output

import (
	"encoding/json"
	"io"
	"time"

	"github.com/pantheon-systems/pauditd/pkg/parser"
	"github.com/pantheon-systems/pauditd/pkg/slog"
)

// AuditWriter is the class that encapsulates the io.Writer for output
type AuditWriter struct {
	e        *json.Encoder
	w        io.Writer
	attempts int
}

// NewAuditWriter creates a generic auditwriter which encapsulates a io.Writer
func NewAuditWriter(w io.Writer, attempts int) *AuditWriter {
	return &AuditWriter{
		e:        json.NewEncoder(w),
		w:        w,
		attempts: attempts,
	}
}

func (a *AuditWriter) Write(msg *parser.AuditMessageGroup) (err error) {
	for i := 0; i < a.attempts; i++ {
		err = a.e.Encode(msg)
		if err == nil {
			break
		}

		if i != a.attempts {
			// We have to reset the encoder because write errors are kept internally and can not be retried
			a.e = json.NewEncoder(a.w)
			slog.Error.Println("Failed to write message, retrying in 1 second. Error:", err)
			time.Sleep(time.Second * 1)
		}
	}

	return err
}
