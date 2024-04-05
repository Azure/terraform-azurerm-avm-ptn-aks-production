package terraform_module_test_helper

import (
	"fmt"
	"os"

	"github.com/ahmetb/go-linq/v3"
	"github.com/hashicorp/hcl/v2"
	"github.com/r3labs/diff/v3"
	"github.com/spf13/afero"
)

type ChangeCategory = string

const (
	variable ChangeCategory = "Variables"
	output   ChangeCategory = "Outputs"
)

type Change struct {
	diff.Change
	Category  ChangeCategory `json:"category"`
	Name      *string        `json:"name"`
	Attribute *string        `json:"attribute"`
}

func (c Change) ToString() string {
	var name string
	if c.Name != nil {
		name = *c.Name
	}
	var attribute string
	if c.Attribute != nil {
		attribute = *c.Attribute
	}
	return fmt.Sprintf(`[%s] "%s.%s.%s" from '%v' to '%v'`, c.Type, c.Category, name, attribute, c.From, c.To)
}

func BreakingChangesDetect(currentModulePath, owner, repo string, tag *string) (string, error) {
	tmpDirForLatestDefaultBranch, err := cloneGithubRepo(owner, repo, tag)
	if err != nil {
		return "", err
	}
	defer func() {
		_ = os.RemoveAll(tmpDirForLatestDefaultBranch)
	}()
	return CompareTwoModules(tmpDirForLatestDefaultBranch, currentModulePath)
}

func CompareTwoModules(dir1 string, dir2 string) (string, error) {
	fs := afero.Afero{Fs: afero.OsFs{}}
	oldModule, err := NewModule(dir1, fs)
	if err != nil {
		return "", err
	}
	currentModule, err := NewModule(dir2, fs)
	if err != nil {
		return "", err
	}
	changes, err := BreakingChanges(oldModule, currentModule)
	if err != nil {
		return "", err
	}
	aggregated := linq.From(changes).Select(func(i interface{}) interface{} {
		return i.(Change).ToString()
	}).Aggregate(func(i interface{}, i2 interface{}) interface{} {
		return fmt.Sprintf("%v\n%v", i, i2)
	})
	if r, ok := aggregated.(string); ok {
		return r, nil
	}
	return "", nil
}

func BreakingChanges(m1 *Module, m2 *Module) ([]Change, error) {
	err := m1.Load()
	if err != nil {
		return nil, err
	}
	err = m2.Load()
	if err != nil {
		return nil, err
	}

	variableChangeLogs, err := changeLog(m1.VariableExts, m2.VariableExts, variable)
	if err != nil {
		return nil, err
	}
	outputChangeLogs, err := changeLog(m1.OutputExts, m2.OutputExts, output)
	if err != nil {
		return nil, err
	}
	changelog := append(variableChangeLogs, outputChangeLogs...)
	return filterBreakingChanges(convert(changelog)), nil
}

func changeLog(i1, i2 interface{}, category ChangeCategory) (diff.Changelog, error) {
	logs, err := diff.Diff(i1, i2)
	if err != nil {
		return nil, err
	}
	linq.From(logs).Select(func(i interface{}) interface{} {
		l := i.(diff.Change)
		l.Path = append([]string{category}, l.Path...)
		return l
	}).ToSlice(&logs)
	return logs, nil
}

func convert(cl diff.Changelog) (r []Change) {
	linq.From(cl).Select(func(i interface{}) interface{} {
		c := i.(diff.Change)
		var name, attribute *string
		if len(c.Path) > 1 {
			name = &c.Path[1]
		}
		if len(c.Path) > 2 {
			attribute = &c.Path[2]
		}
		return Change{
			Change: diff.Change{
				Type: c.Type,
				Path: c.Path,
				From: c.From,
				To:   c.To,
			},
			Category:  c.Path[0],
			Name:      name,
			Attribute: attribute,
		}
	}).ToSlice(&r)
	return
}

func filterBreakingChanges(cl []Change) []Change {
	variables := linq.From(cl).Where(func(i interface{}) bool {
		return i.(Change).Category == variable
	})
	variableChanges := breakingVariables(variables)
	outputs := linq.From(cl).Where(func(i interface{}) bool {
		return i.(Change).Category == output
	})
	outputChanges := breakingOutputs(outputs)
	return append(variableChanges, outputChanges...)
}

func breakingOutputs(outputs linq.Query) []Change {
	var r []Change
	deletedOutputs := outputs.Where(isDeletedOutput)
	valueChangedOutputs := outputs.Where(valueChangedOutput)
	sensitiveChangedOutputs := outputs.Where(sensitiveChangeToTrueVariable)
	deletedOutputs.
		Concat(valueChangedOutputs).
		Concat(sensitiveChangedOutputs).ToSlice(&r)
	return r
}

func sensitiveChangeToTrueVariable(i interface{}) bool {
	c := i.(Change)
	isSensitive := c.Type == "update" && c.Attribute != nil && *c.Attribute == "Sensitive"
	if !isSensitive {
		return false
	}
	s, ok := c.To.(string)
	return ok && s == "true"
}

func valueChangedOutput(i interface{}) bool {
	c := i.(Change)
	return c.Type == "update" && c.Attribute != nil && (*c.Attribute == "Value")
}

func isDeletedOutput(i interface{}) bool {
	c := i.(Change)
	return c.Type == "delete" && c.Attribute != nil && *c.Attribute == "Name"
}

func breakingVariables(variables linq.Query) []Change {
	var r []Change
	newVariables := variables.Where(isNewVariable)
	requiredNewVariables := groupByName(newVariables).Where(noDefaultValue)
	deletedVariables := variables.Where(isDeletedVariable)
	typeChangedVariables := variables.Where(typeChanged)
	defaultValueBreakingChangeVariables := variables.Where(newDefaultValue)
	nullableChangeVariables := variables.Where(nullableChanged)
	sensitiveBrokenVariables := variables.Where(func(i interface{}) bool {
		c := i.(Change)
		return c.Type == "update" && c.Attribute != nil && *c.Attribute == "Sensitive" && c.From == "true" && (c.To == "" || c.To == "false")
	})
	requiredNewVariables.Select(recordForName).
		Concat(deletedVariables).
		Concat(typeChangedVariables).
		Concat(defaultValueBreakingChangeVariables).
		Concat(nullableChangeVariables).
		Concat(sensitiveBrokenVariables).
		ToSlice(&r)
	return r
}

func nullableChanged(i interface{}) bool {
	c := i.(Change)
	return c.Type == "update" && c.Attribute != nil && *c.Attribute == "Nullable"
}

func newDefaultValue(i interface{}) bool {
	c := i.(Change)
	return c.Type == "update" && c.Attribute != nil && (*c.Attribute == "Default" && c.From != "")
}

func typeChanged(i interface{}) bool {
	c := i.(Change)
	return c.Type == "update" && c.Attribute != nil && (*c.Attribute == "Type" && !isStringNilOrEmpty(c.To))
}

func isDeletedVariable(i interface{}) bool {
	c := i.(Change)
	return c.Type == "delete" && c.Attribute != nil && *c.Attribute == "Name"
}

func recordForName(g interface{}) interface{} {
	return linq.From(g.(linq.Group).Group).FirstWith(func(i interface{}) bool {
		return i.(Change).Attribute != nil && *i.(Change).Attribute == "Name"
	})
}

func groupByName(newVariables linq.Query) linq.Query {
	return newVariables.GroupBy(func(i interface{}) interface{} {
		return *i.(Change).Name
	}, func(i interface{}) interface{} {
		return i
	})
}

func noDefaultValue(g interface{}) bool {
	return linq.From(g.(linq.Group).Group).All(func(i interface{}) bool {
		return i.(Change).Attribute == nil || *i.(Change).Attribute != "Default"
	})
}

func isNewVariable(i interface{}) bool {
	return i.(Change).Type == "create"
}

func isStringNilOrEmpty(i interface{}) bool {
	if i == nil {
		return true
	}
	s, ok := i.(string)
	return !ok || s == ""
}

func attributeValueString(a *hcl.Attribute, f *hcl.File) string {
	return string(a.Expr.Range().SliceBytes(f.Bytes))
}
