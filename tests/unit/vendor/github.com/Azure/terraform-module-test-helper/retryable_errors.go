package terraform_module_test_helper

import (
	"encoding/json"
	"testing"
)

func ReadRetryableErrors(retryableCfg []byte, t *testing.T) map[string]string {
	cfg := struct {
		RetryableErrors []string `json:"retryable_errors"`
	}{}

	err := json.Unmarshal(retryableCfg, &cfg)
	if err != nil {
		t.Fatalf("cannot unmarshal retryable config, must be and valid terragrunt `retryable_errors` config in json format.")
	}
	retryableRegexes := cfg.RetryableErrors
	retryableErrors := make(map[string]string)
	for _, r := range retryableRegexes {
		retryableErrors[r] = "retryable errors set by test"
	}
	return retryableErrors
}
