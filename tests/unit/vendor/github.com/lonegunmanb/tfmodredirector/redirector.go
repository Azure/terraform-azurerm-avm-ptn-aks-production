package tfmodredirector

import (
	"bytes"
	"fmt"
	"github.com/ahmetb/go-linq/v3"
	"github.com/minamijoyo/hcledit/editor"
	"strings"

	"github.com/magodo/hclgrep/hclgrep"
)

func GetModules(tfCode, expectedSource string) ([]string, error) {
	args := []string{"-x", "module $name {@*_}", "-g", fmt.Sprintf(`source = "%s"`, expectedSource), "-w", "name"}
	opts, _, err := hclgrep.ParseArgs(args)
	if err != nil {
		return nil, err
	}
	buf := bytes.NewBufferString("")
	opts = append(opts, hclgrep.OptionOutput(buf))
	m := hclgrep.NewMatcher(opts...)
	if err = m.File("", bytes.NewBufferString(tfCode)); err != nil {
		return nil, err
	}
	s := buf.String()
	r := strings.Split(s, "\n")
	linq.From(r).Where(func(i interface{}) bool {
		return i.(string) != ""
	}).ToSlice(&r)
	return r, nil
}

func RewriteModuleSource(tfCode, moduleName, newSource string) (string, error) {
	o := editor.NewEditOperator(editor.NewAttributeSetFilter(fmt.Sprintf("module.%s.source", moduleName), fmt.Sprintf(`"%s"`, newSource)))
	output, err := o.Apply([]byte(tfCode), "main.tf")
	if err != nil {
		return "", err
	}
	return string(output), nil
}

func RedirectModuleSource(tfCode, originSource, newSource string) (string, error) {
	names, err := GetModules(tfCode, originSource)
	if err != nil {
		return "", err
	}
	for _, n := range names {
		tfCode, err = RewriteModuleSource(tfCode, n, newSource)
		if err != nil {
			return "", err
		}
	}
	return tfCode, nil
}
