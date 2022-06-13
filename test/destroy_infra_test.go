package test

import (
   "github.com/gruntwork-io/terratest/modules/terraform"
   test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
   "testing"
   "os"
)

func TestDeployment(t *testing.T) {
   t.Parallel()

   gcpCreds := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")

	if gcpCreds == "" {
		t.Fatalf("GOOGLE_APPLICATION_CREDENTIALS environment variable cannot be empty.")
	}
   siteType := os.Getenv("site_type")

   if siteType == "" {
		t.Fatalf("site_type environment variable cannot be empty. single-site or gslb are valid values")
	}

   TerraformDir := "../examples/" + siteType

   // Uncomment these when doing local testing if you need to skip any stages.
   //os.Setenv("SKIP_destroy", "true")

   // Destroy the infrastructure
   test_structure.RunTestStage(t, "destroy", func() {
      //terratestOptions := &terraform.Options{
         // The path to where your Terraform code is located
        // TerraformDir: TerraformDir,
         //Vars: terraVars,
      //}
      terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)
      terraform.Destroy(t, terraformOptions)
   })

}