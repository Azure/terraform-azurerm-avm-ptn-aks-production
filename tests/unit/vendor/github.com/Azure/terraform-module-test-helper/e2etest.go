package terraform_module_test_helper

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	terratest "github.com/gruntwork-io/terratest/modules/testing"
	"github.com/stretchr/testify/require"
)

type TestOptions struct {
	TerraformOptions    terraform.Options
	Assertion           func(*testing.T, TerraformOutput)
	SkipIdempotentCheck bool
	SkipDestroy         bool
}

var copyLock = &KeyedMutex{}

type TerraformOutput = map[string]interface{}

type testExecutor interface {
	TearDown(t *testing.T, rootDir string, modulePath string)
	Logger() logger.TestLogger
}

var _ testExecutor = e2eTestExecutor{}

type e2eTestExecutor struct{}

func (e2eTestExecutor) TearDown(t *testing.T, rootDir string, modulePath string) {
	s := SuccessTestVersionSnapshot(rootDir, modulePath)
	if t.Failed() {
		s = FailedTestVersionSnapshot(rootDir, modulePath, "")
	}
	require.NoError(t, s.Save(t))
}

func (e2eTestExecutor) Logger() logger.TestLogger {
	l := NewMemoryLogger()
	return l
}

func RunE2ETest(t *testing.T, moduleRootPath, exampleRelativePath string, option terraform.Options, assertion func(*testing.T, TerraformOutput)) {
	initAndApplyAndIdempotentTest(t, moduleRootPath, exampleRelativePath, option, false, true, assertion, e2eTestExecutor{})
}

func RunE2ETestWithOption(t *testing.T, moduleRootPath, exampleRelativePath string, testOption TestOptions) {
	initAndApplyAndIdempotentTest(t, moduleRootPath, exampleRelativePath, testOption.TerraformOptions, false, testOption.SkipIdempotentCheck, testOption.Assertion, e2eTestExecutor{})
}

func initAndApplyAndIdempotentTest(t *testing.T, moduleRootPath string, exampleRelativePath string, option terraform.Options, skipDestroy bool, skipCheckIdempotent bool, assertion func(*testing.T, TerraformOutput), executor testExecutor) {
	tryParallel(t)
	defer executor.TearDown(t, moduleRootPath, exampleRelativePath)
	testDir := filepath.Join(moduleRootPath, exampleRelativePath)
	logger.Log(t, fmt.Sprintf("===> Starting test for %s, since we're running tests in parallel, the test log will be buffered and output to stdout after the test was finished.", testDir))

	tmpDir := copyTerraformFolderToTemp(t, moduleRootPath, exampleRelativePath)
	defer func() {
		_ = os.RemoveAll(filepath.Clean(tmpDir))
	}()
	option.TerraformDir = tmpDir

	l := executor.Logger()
	c, ok := l.(io.Closer)
	if ok {
		defer func() {
			_ = c.Close()
		}()
	}
	option.Logger = logger.New(l)
	option = setupRetryLogic(option)

	if !skipDestroy {
		defer destroy(t, option)
	}
	initAndApply(t, &option)
	var err error
	if !skipCheckIdempotent {
		err = initAndPlanAndIdempotentAtEasyMode(t, option)
	}
	if err != nil {
		t.Fatalf(err.Error())
	}
	if assertion != nil {
		assertion(t, terraform.OutputAll(t, removeLogger(option)))
	}
}

func copyTerraformFolderToTemp(t *testing.T, moduleRootPath string, exampleRelativePath string) string {
	unlock := copyLock.Lock(exampleRelativePath)
	defer unlock()
	tmpDir := test_structure.CopyTerraformFolderToTemp(t, moduleRootPath, exampleRelativePath)
	return tmpDir
}

func initAndApply(t terratest.TestingT, options *terraform.Options) string {
	tfInit(t, options)
	return terraform.Apply(t, options)
}

func tfInit(t terratest.TestingT, options *terraform.Options) {
	terraform.Init(t, options)
}

func destroy(t *testing.T, option terraform.Options) {
	path := option.TerraformDir
	if !files.IsExistingDir(path) || !files.FileExists(filepath.Join(path, "terraform.tfstate")) {
		return
	}

	option.MaxRetries = 5
	option.TimeBetweenRetries = time.Minute
	option.RetryableTerraformErrors = map[string]string{
		".*": "Retry destroy on any error",
	}
	_, err := terraform.RunTerraformCommandE(t, &option, terraform.FormatArgs(&option, "destroy", "-auto-approve", "-input=false", "-refresh=false")...)
	if err != nil {
		_, err = terraform.DestroyE(t, &option)
	}
	require.NoError(t, err)
}

func removeLogger(option terraform.Options) *terraform.Options {
	// default logger might leak sensitive data
	option.Logger = logger.Discard
	return &option
}

func retryableOptions(t *testing.T, options terraform.Options) terraform.Options {
	result := terraform.WithDefaultRetryableErrors(t, &options)
	result.RetryableTerraformErrors[".*Please try again.*"] = "Service side suggest retry."
	return *result
}
