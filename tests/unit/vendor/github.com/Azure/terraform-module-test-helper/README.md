# Azure Verified Terraform Module Test Helper

![test](https://img.shields.io/github/actions/workflow/status/Azure/terraform-module-test-helper/test.yaml?branch=main)
![lint](https://img.shields.io/github/actions/workflow/status/Azure/terraform-module-test-helper/lint.yaml?branch=main&label=lint)

This repo contains two helper functions that were used to test Azure Verified Terraform Module.

For End-End test:

```go
func TestExamplesStartup(t *testing.T) {
	vars := map[string]interface{}{
		"client_id":     "",
		"client_secret": "",
	}
	managedIdentityId := os.Getenv("MSI_ID")
	if managedIdentityId != "" {
		vars["managed_identity_principal_id"] = managedIdentityId
	}
	test_helper.RunE2ETest(t, "../../", "examples/startup", terraform.Options{
		Upgrade: true,
		Vars:    vars,
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		aksId, ok := output["test_aks_id"].(string)
		assert.True(t, ok)
		assert.Regexp(t, regexp.MustCompile("/subscriptions/.+/resourceGroups/.+/providers/Microsoft.ContainerService/managedClusters/.+"), aksId)
	})
}
```

The `RunE2ETest` function accept module's root path, sub-folder to example code that our test want to apply, a `terraform.Options` argument, and an assertion callback.

In E2E test we apply the example code,then we execute `terraform output` and pass the json format output to this assertion callback, you can assert whether the output meets your spec there.

For Version-Upgrade Test:

```go
func TestExampleUpgrade_startup(t *testing.T) {
	currentRoot, err := test_helper.GetCurrentModuleRootPath()
	if err != nil {
		t.FailNow()
	}
	currentMajorVersion, err := test_helper.GetCurrentMajorVersionFromEnv()
	if err != nil {
		t.FailNow()
	}
	vars := map[string]interface{}{
		"client_id":     "",
		"client_secret": "",
	}
	managedIdentityId := os.Getenv("MSI_ID")
	if managedIdentityId != "" {
		vars["managed_identity_principal_id"] = managedIdentityId
	}
	test_helper.ModuleUpgradeTest(t, "Azure", "terraform-azurerm-aks", "examples/startup", currentRoot, terraform.Options{
		Upgrade: true,
		Vars:    vars,
	}, currentMajorVersion)
}
```

The `ModuleUpgradeTest` function accept your Github repo's owner name (could be username or org name), repo name, sub-folder to example code, and module's current major version (eg: v3.0.0 major version is 3).

The `ModuleUpgradeTest` function will clone and checkout the latest released tag version within the major version you've passed, apply the code in a temp directory, then modify the module's source to the current path, then execute `terraform plan` to see if there would be any drift in the plan.