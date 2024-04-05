# tfmodredirector

![master status](https://img.shields.io/github/workflow/status/lonegunmanb/tfmodredirector/push-check)

This helper function could rewrite `module`'s `source` attribute, given the following hcl:

```hcl
module "mod" {
  source = "../../"
}
```

Use the following code to redirect the module's source to a new address:

```go
actual, err := tfmodredirector.RedirectModuleSource(tf, "../../", "new_source")
```

The `actual` would be:

```hcl
module "mod" {
  source = "new_source"
}
```

The project is a simple glue between:

| Name                                             | Latest Version                                              |
|--------------------------------------------------|-------------------------------------------------------------|
| [hclgrep](https://github.com/magodo/hclgrep)     | ![](https://img.shields.io/github/v/tag/magodo/hclgrep)     |
| [hcledit](https://github.com/minamijoyo/hcledit) | ![](https://img.shields.io/github/v/tag/minamijoyo/hcledit) |
