package terraform_module_test_helper

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
	"github.com/thanhpk/randstr"
)

func VarsToFile(t *testing.T, vars map[string]any) string {
	cleanPath := filepath.Clean(fmt.Sprintf("%s/terraform%s.tfvars.json", os.TempDir(), randstr.Hex(8)))
	varFile, err := os.Create(cleanPath)
	require.Nil(t, err)
	c, err := json.Marshal(vars)
	require.Nil(t, err)
	_, err = varFile.Write(c)
	require.Nil(t, err)
	_ = varFile.Close()
	varFilePath, err := filepath.Abs(cleanPath)
	require.Nil(t, err)
	return varFilePath
}

