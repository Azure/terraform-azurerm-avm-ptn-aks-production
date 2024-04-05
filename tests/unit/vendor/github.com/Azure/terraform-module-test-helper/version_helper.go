package terraform_module_test_helper

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

var initE = terraform.InitE
var runTerraformCommandE = terraform.RunTerraformCommandE
var recordFileLocks = &KeyedMutex{}

type KeyedMutex struct {
	mutexes sync.Map // Zero value is empty and ready for use
}

func (m *KeyedMutex) Lock(key string) func() {
	value, _ := m.mutexes.LoadOrStore(key, &sync.Mutex{})
	mtx := value.(*sync.Mutex)
	mtx.Lock()
	return func() { mtx.Unlock() }
}

type TestVersionSnapshot struct {
	ModuleRootFolder        string
	SubModuleRelativeFolder string
	Time                    time.Time
	Success                 bool
	Versions                string
	ErrorMsg                string
}

func SuccessTestVersionSnapshot(rootFolder, exampleRelativePath string) *TestVersionSnapshot {
	return &TestVersionSnapshot{
		ModuleRootFolder:        rootFolder,
		SubModuleRelativeFolder: exampleRelativePath,
		Time:                    time.Now(),
		Success:                 true,
	}
}

func FailedTestVersionSnapshot(rootFolder, exampleRelativePath, errMsg string) *TestVersionSnapshot {
	return &TestVersionSnapshot{
		ModuleRootFolder:        rootFolder,
		SubModuleRelativeFolder: exampleRelativePath,
		Time:                    time.Now(),
		Success:                 false,
		ErrorMsg:                errMsg,
	}
}

func (s *TestVersionSnapshot) ToString() string {
	return fmt.Sprintf(`## %s

Success: %t

### Versions

%s

### Error

%s

---

`, s.Time.Format(time.RFC822), s.Success, s.Versions, s.ErrorMsg)
}

func (s *TestVersionSnapshot) Save(t *testing.T) error {
	path, err := filepath.Abs(filepath.Clean(filepath.Join(s.ModuleRootFolder, s.SubModuleRelativeFolder, "TestRecord.md.tmp")))
	if err != nil {
		return err
	}
	unlock := recordFileLocks.Lock(path)
	defer unlock()
	s.load(t)
	err = s.saveToLocal(path)
	if err != nil {
		return err
	}
	return s.copyForUploadArtifact(path)
}

func (s *TestVersionSnapshot) copyForUploadArtifact(localPath string) error {
	_, dir := filepath.Split(filepath.Join(s.ModuleRootFolder, s.SubModuleRelativeFolder))
	pathForUpload := filepath.Join(s.ModuleRootFolder, "TestRecord", dir, "TestRecord.md.tmp")
	return copyFile(localPath, pathForUpload)
}

func (s *TestVersionSnapshot) saveToLocal(path string) error {
	return writeStringToFile(path, s.ToString())
}

func copyFile(src, dst string) error {
	cleanedSrc := filepath.Clean(src)
	cleanedDst := filepath.Clean(dst)
	if _, err := os.Stat(cleanedSrc); os.IsNotExist(err) {
		return fmt.Errorf("source file does not exist: %s", src)
	}

	dstDir := filepath.Dir(cleanedDst)
	if _, err := os.Stat(dstDir); os.IsNotExist(err) && os.MkdirAll(dstDir, os.ModePerm) != nil {
		return fmt.Errorf("failed to create destination folder: %s", dstDir)
	}
	if _, err := os.Stat(cleanedDst); !os.IsNotExist(err) && os.Remove(cleanedDst) != nil {
		return fmt.Errorf("failed to delete destination file: %s", dst)
	}
	srcFile, err := os.Open(cleanedSrc)
	if err != nil {
		return fmt.Errorf("failed to open source file: %s", src)
	}
	defer func() { _ = srcFile.Close() }()

	dstFile, err := os.Create(cleanedDst)
	if err != nil {
		return fmt.Errorf("failed to create destination file: %s", dst)
	}
	defer func() { _ = dstFile.Close() }()

	if _, err = io.Copy(dstFile, srcFile); err != nil {
		return fmt.Errorf("failed to copy file: %s", err)
	}
	return nil
}

func writeStringToFile(filePath, str string) error {
	cleanedFilePath := filepath.Clean(filePath)
	if files.FileExists(cleanedFilePath) {
		if err := os.Remove(cleanedFilePath); err != nil {
			return err
		}
	}
	f, err := os.Create(cleanedFilePath)
	if err != nil {
		return err
	}
	defer func() { _ = f.Close() }()
	_, err = f.WriteString(str)
	return err
}

func (s *TestVersionSnapshot) load(t *testing.T) {
	tmpDir := test_structure.CopyTerraformFolderToTemp(t, s.ModuleRootFolder, s.SubModuleRelativeFolder)
	defer func() {
		_ = os.RemoveAll(tmpDir)
	}()
	opts := terraform.Options{
		TerraformDir: tmpDir,
		NoColor:      true,
		Logger:       logger.Discard,
	}
	if output, err := initE(t, &opts); err != nil {
		s.Success = false
		s.ErrorMsg = output
		return
	}
	output, err := runTerraformCommandE(t, &opts, "version")
	if err != nil {
		s.Success = false
		s.ErrorMsg = output
		return
	}
	s.Versions = output
}
