// +build unit

package test

import (
   "os"
   "github.com/gruntwork-io/terratest/modules/terraform"
   "github.com/stretchr/testify/assert"
   "testing"
)

func TestStaticSiteValidity(t *testing.T) {
   t.Parallel()
   gcpCreds := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")

	if gcpCreds == "" {
		t.Fatalf("GOOGLE_APPLICATION_CREDENTIALS environment variable cannot be empty.")
	}
   _fixturesDir := "../examples/single-controller"
   terratestOptions := &terraform.Options{
      TerraformDir: _fixturesDir,
      Vars: map[string]interface{}{},
   }
   t.Logf("Running in %s", _fixturesDir)
   output := terraform.InitAndPlan(t, terratestOptions)
   assert.Contains(t, output, "Plan OK")
}