package terraform_module_test_helper

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

var _ testExecutor = unitTestExecutor{}

type unitTestExecutor struct{}

func (u unitTestExecutor) TearDown(t *testing.T, rootDir string, modulePath string) {}

func (u unitTestExecutor) Logger() logger.TestLogger {
	return logger.Discard
}

func RunUnitTest(t *testing.T, moduleRootPath, exampleRelativePath string, option terraform.Options, assertion func(*testing.T, TerraformOutput)) {
	initAndApplyAndIdempotentTest(t, moduleRootPath, exampleRelativePath, option, true, true, assertion, unitTestExecutor{})
}
