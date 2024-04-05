package terraform_module_test_helper

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"sync"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/testing"
)

var _ logger.TestLogger = new(StreamLogger)

var serializedLogger = func() *StreamLogger {
	l := NewStreamLogger(os.Stdout)
	l.outputProgress = false
	return l
}()

type StreamLogger struct {
	stream         io.ReadWriter
	mu             *sync.Mutex
	logCount       int
	outputProgress bool
}

func NewMemoryLogger() *StreamLogger {
	buff := new(bytes.Buffer)
	return NewStreamLogger(buff)
}

func NewStreamLogger(stream io.ReadWriter) *StreamLogger {
	return &StreamLogger{
		stream:         stream,
		mu:             new(sync.Mutex),
		outputProgress: true,
	}
}

func (s *StreamLogger) Logf(t testing.TestingT, format string, args ...interface{}) {
	log := fmt.Sprintf(format, args...)
	logger.DoLog(t, 3, s.stream, log)
	s.logCount++
	if s.outputProgress && s.logCount%50 == 0 {
		logger.Log(t, fmt.Sprintf("logging sample: %s", log))
	}
}

func (s *StreamLogger) PipeFrom(srcLogger *StreamLogger) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, err := io.Copy(s.stream, srcLogger.stream)
	return err
}

func (s *StreamLogger) Close() error {
	defer func() {
		c, ok := s.stream.(io.Closer)
		if ok {
			_ = c.Close()
		}
	}()
	return serializedLogger.PipeFrom(s)
}
