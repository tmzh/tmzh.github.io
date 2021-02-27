---
author: tmzh
comments: true
date: 2021-02-02 12:00:00+08:00
layout: post
slug: 2021-02-02-testing-terraform-code-using-terratest
title: Writing BDD tests for Terraform Code Using Terratest
categories:
- Cloud Computing
tags:
- terraform
- iac
image: /images/2020-09-26-meta-learning.png
---

Terratest is a popular library for testing Terraform code. Testing Infrastructure As Code (IAC) is not as widespread as it should be. The reasons are multi-fold, ranging from developer's attitude towards testing to the difficulty of writing unit tests because of inherent side effects of IAC. Nevertheless, testing is no less important, in particular under these scenarios:

1. When your module gets complicated, with medium to complex behaviour logic
2. When your module makes underlying assumptions of external dependencies (such as AWS SCPs at Organization level permitting certain actions)

In this post, we will take a look at using Terratest to test Terraform code. A typical Terratest testing pattern involves:
1. Deploying real infrastructure in real environment
2. Asserting that the deployed resources behaves as expected
3. Undeploy everything at the end of the test.

Behavior Driven Test (BDD) uses examples to describe the behavior of a system. It serves the dual purpose of testing the code and documenting it at the same time. Terratest is not a BDD testing framework, however it is possible to write BDD tests that executes Terratest code. In a later section of this post, we will see how this can be achieved using Godog which is a Go BDD testing library.

<!--more-->

## A Basic Test Scenario
### Terraform code

Let us start with a simple terraform module that deploys a Hello world lambda function. 

```terraform
terraform {
  required_version = ">= 0.12.26"
}

provider "archive" {
  version = "1.3"
}

data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/${var.function_name}.zip"
}

variable "function_name" {
  description = "The name of the function to provision"
  default = "test_lambda_function"
}

resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  function_name    = var.function_name
  handler          = "handler"
  runtime          = "go1.x"
}

output "lambda_function" {
	value = aws_lambda_function.lambda.id
}

```

Here is the lambda script that we plan to deploy. It is a slightly modified version taken from terratest [examples](https://github.com/gruntwork-io/terratest/tree/master/examples/terraform-aws-lambda-example) repo.

```golang
package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
)

func HandleRequest(ctx context.Context, name string) (string, error) {
	return fmt.Sprintf("Hello %s", name), fmt.Errorf("Failed to handle %#v", evnt)
}

func main() {
	lambda.Start(HandleRequest)
}
```

### Terratest code

To test this using Terratest, we need to write tests using Go's built-in package [testing](https://golang.org/pkg/testing/). This means that we create a file ending with `_test.go` which implements test cases in a function with name `TestXxxx`. In our case, the test script is called `main_test.go` and test function is called `TestTerraformAwsLambdaFunction`. Here is the folder structure:

```
📁 lambda_basic
   ├ 📁 src
   │   ├ 📄 handler.go
   ├ 📁 test
   │   ├ 📄 main_test.go
   ├ 📄 main.tf
```

The content of the test case is:

```go
package test

import (
	"fmt"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraformAwsLambdaFunction(t *testing.T) {
	t.Parallel()

	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "..",
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
	functionName := terraform.Output(t, terraformOptions, "lambda_function")

	response := aws.InvokeFunction(t, awsRegion, functionName, "World")

	assert.Equal(t, `"hi!"`, string(response))
}

```
To test the module, simply run `go test` command under the test directory. 

```
cd test
go test -v
```

This performs the following steps:
1. Setup the root directory of the terraform code. This is specified using `TerraformDir` option.
2. Deploy Lambda function using `terraform init` and `terraform apply` code. This is done by calling `terraform.InitAndApply` function.
3. Retrieve the resources that have been deployed using `terraform.Output` method. This is handy when we need to use generated attributes such as resource arn in the subsequent test statements. These attributes have to be exported using `terraform output` resource for this to work.
4. Terratest provisions real resources and it will cost money. To avoid incurring cost, we always follow up the test cases by a deferred call to `terraform.Destroy` method. This statement executes last after all test cases and it cleans up the test resources.

If you have multiple test functions, you can run a specific test as well.

```
go test -run TestLambdaFunction
```

You can get the complete code for this scenario [here](https://github.com/tmzh/terratest-examples/tree/main/lambda_basic)

### Testing multiple behaviours

Now, it is possible to test more than one test scenarios simply by adding more lines or functions for test cases. For example, we can send an erraneous input to lambda function and expect that it fails with a particular error message.

```go
// Invoke the function, this time causing it to error and capturing the error
response, err := aws.InvokeFunctionE(t, awsRegion, functionName, ExampleFunctionPayload{ShouldFail: true, Echo: "hi!"})

// Function-specific errors have their own special return
functionError, ok := err.(*aws.FunctionError)
require.True(t, ok)
```

At some pointo of time, adding more test cases like this is going to become unwieldy. Later in the post we will see how to make the test cases more readable and self-documenting by writing BDD style test cases.

### Passing other terraform options
We can also pass custom options to the test code. For example, if we want to override the `function_name` variable, we can pass it as a Vars parameter to terraform options.  

```
terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
Vars: map[string]interface{}{
	"function_name": "test_lambda_function_v2",
},
```

This would be same as calling `terraform` command with `-var` options. This would take [precedence](https://www.terraform.io/docs/language/values/variables.html#variable-definition-precedence) over any variable set in terraform code. These are the available [options](https://pkg.go.dev/github.com/gruntwork-io/terratest/modules/terraform#Options) that can be used in terratest as of the time of writing:

```go
type Options struct {
	TerraformBinary string // Name of the binary that will be used
	TerraformDir    string // The path to the folder where the Terraform code is defined.

	// The vars to pass to Terraform commands using the -var option. Note that terraform does not support passing `null`
	// as a variable value through the command line. That is, if you use `map[string]interface{}{"foo": nil}` as `Vars`,
	// this will translate to the string literal `"null"` being assigned to the variable `foo`. However, nulls in
	// lists and maps/objects are supported. E.g., the following var will be set as expected (`{ bar = null }`:
	// map[string]interface{}{
	//     "foo": map[string]interface{}{"bar": nil},
	// }
	Vars map[string]interface{}

	VarFiles                 []string               // The var file paths to pass to Terraform commands using -var-file option.
	Targets                  []string               // The target resources to pass to the terraform command with -target
	Lock                     bool                   // The lock option to pass to the terraform command with -lock
	LockTimeout              string                 // The lock timeout option to pass to the terraform command with -lock-timeout
	EnvVars                  map[string]string      // Environment variables to set when running Terraform
	BackendConfig            map[string]interface{} // The vars to pass to the terraform init command for extra configuration for the backend
	RetryableTerraformErrors map[string]string      // If Terraform apply fails with one of these (transient) errors, retry. The keys are a regexp to match against the error and the message is what to display to a user if that error is matched.
	MaxRetries               int                    // Maximum number of times to retry errors matching RetryableTerraformErrors
	TimeBetweenRetries       time.Duration          // The amount of time to wait between retries
	Upgrade                  bool                   // Whether the -upgrade flag of the terraform init command should be set to true or not
	NoColor                  bool                   // Whether the -no-color flag will be set for any Terraform command or not
	SshAgent                 *ssh.SshAgent          // Overrides local SSH agent with the given in-process agent
	NoStderr                 bool                   // Disable stderr redirection
	OutputMaxLineSize        int                    // The max size of one line in stdout and stderr (in bytes)
	Logger                   *logger.Logger         // Set a non-default logger that should be used. See the logger package for more info.
	Parallelism              int                    // Set the parallelism setting for Terraform
	PlanFilePath             string                 // The path to output a plan file to (for the plan command) or read one from (for the apply command)
}
```

## BDD Testing using GoDog
Let us add more behaviors to our Terraform code. For instance, suppose we want to want to assign an IAM role to the lambda function that grants permission to log to Cloudwatch.

```terraform
resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  function_name    = var.function_name
  role             = aws_iam_role.lambda.arn
  handler          = "handler"
  runtime          = "go1.x"
}

resource "aws_iam_role" "lambda" {
  name               = var.function_name
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}
```

Now, when we deploy this, not only do we need to assert that all resources are deployed properly (Lambda function, IAM role etc.,) but we also need to assert that the Lambda function can send logs to Cloudwatch. This is where BDD tests can be useful.

First we need to specify our expected behavior using a gherkin Feature file. Create a file called `features/Smoke.feature`

```gherkin
Feature: Simple test to confirm lambda function behavior
	Confirms that given a valid terraform variable
	Lambda resources are deployed
	The Lambda function executes as intended
	Scenario: Deploy a Lambda function
		Given Terraform code is deployed with these variables:
			|function_name | random_name|
		Then For given inputs Lambda function output is as expected:
			|world | "Hello world!"|
		Then Cloudwatch log stream is generated
```

To test this, we will use a [godog](https://github.com/cucumber/godog) BDD framework for Golang. Let us create a Godog test function and call it `bdd_test.go`.

```go
type godogFeaturesScenario struct {
	testing          *testing.T
	terraformOptions *terraform.Options
	stepValues       map[string]string
}

func TestLambdaFunctionBDD(t *testing.T) {
	t.Parallel()

	opts := godog.Options{
		Format:    "progress",
		Paths:     []string{"features"},
		Randomize: time.Now().UTC().UnixNano(),
	}

	o := &godogFeaturesScenario{}
	o.testing = t

	godog.TestSuite{
		Name:                 "LambdaTest",
		TestSuiteInitializer: InitializeTestSuite,
		ScenarioInitializer:  o.InitializeScenario,
		Options:              &opts,
	}.Run()

}
```

Here we pass our Feature file location in the option `godog.Options{Paths: []string{"features"}}`. We also need to pass `TestSuiteInitializer` and `ScenarioInitializer` as part of the TestSuite specs. These functions allows us to hook to events such as `BeforeScenario`, `AfterScenario`. For those coming from a BDD framework like Behave will notice that godog doesn't support a mutable context object. So it cannot be used to pass values between each step. Instead we have to create a struct called `godogFeaturesScenario` on which we implement a `ScenarioInitializer` function. This allows us to pass objects like `Testing.T`, `terraform.Options` which are shared across multiple steps. We have also added a `stepValues` parameter which can be used to capture values from intermediate steps (like getting resource ARN from `terraform.Output`)

Next step would be to map the Step definitions to go functions.

```golang
func (o *godogFeaturesScenario) InitializeScenario(ctx *godog.ScenarioContext) {
	o.stepValues = make(map[string]string)

	ctx.Step(`^Terraform code is deployed with these variables:$`, o.terraformIsDeployedWithVariables)
	ctx.Step(`^For given inputs Lambda function output is as expected:$`, o.givenInputsLambdaReturnsValuesAsExpected)
	ctx.Step(`^Cloudwatch log stream is generated$`, o.cloudwatchLogIsGenerated)
	ctx.AfterScenario(o.destroyTerraform)
}
```

Here we also add an `AfterScenario` event hook which always makes sure that we destroy Terraform resources at the end of the test. 

Next we implement the functions. Note that Terratest also provides us some helper functions like `github.com/gruntwork-io/terratest/modules/aws` which makes it simpler to perform actions like `aws.InvokeFunction`. In other case, we need to use AWS Go SDK to make calls such as `cloudwatch.DescribeLogGroups`

```golang
func (o *godogFeaturesScenario) terraformIsDeployedWithVariables(tbl *godog.Table) error {
	tfVars := make(map[string]interface{})
	for _, row := range tbl.Rows {
		tfVars[row.Cells[0].Value] = row.Cells[1].Value
	}
	o.stepValues["awsRegion"] = "us-east-1"

	terraformOptions := terraform.WithDefaultRetryableErrors(o.testing, &terraform.Options{
		TerraformDir: "..",
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": o.stepValues["awsRegion"],
		},
	})

	o.terraformOptions = terraformOptions
	terraform.InitAndApply(o.testing, terraformOptions)
	return nil
}

func (o *godogFeaturesScenario) givenInputsLambdaReturnsValuesAsExpected(tbl *godog.Table) error {
	o.stepValues["functionName"] = terraform.Output(o.testing, o.terraformOptions, "lambda_function")
	for _, row := range tbl.Rows[1:] {
		input := row.Cells[0].Value
		expected := row.Cells[1].Value
		response := aws.InvokeFunction(o.testing, o.stepValues["awsRegion"], o.stepValues["functionName"], Payload{Name: input})
		actual := string(response)
		if expected != actual {
			return fmt.Errorf("Not equal: \n"+
				"expected: %s\n"+
				"actual  : %s", expected, actual)
		}
	}
	return nil
}

func (o *godogFeaturesScenario) cloudwatchLogIsGenerated() error {
	logGroupName := fmt.Sprintf("/aws/lambda/%s", o.stepValues["functionName"])
	client := aws.NewCloudWatchLogsClient(o.testing, o.stepValues["awsRegion"])
	output, _ := client.DescribeLogGroups(&cloudwatchlogs.DescribeLogGroupsInput{
		LogGroupNamePrefix: &logGroupName,
	})
	if len(output.LogGroups) < 1 {
		return fmt.Errorf("Expected at least one log group. Found %d log groups", len(output.LogGroups))
	}
	return nil
}

func (o *godogFeaturesScenario) destroyTerraform(sc *godog.Scenario, err error) {
	terraform.Destroy(o.testing, o.terraformOptions)
}
```

Now we are ready to run the test.  You should see the below output indicating that 1 scenario was executed with 3 succesful steps.

```
1 scenarios (1 passed)
3 steps (3 passed)
48.024014744s

Randomized with seed: 1614398736564936647
```

You can get the complete code for this scenario [here](https://github.com/tmzh/terratest-examples/tree/main/lambda_bdd)

## Tips for testing with terratest
### Testing in random folder
Terraform init and apply steps leaves behind a bunch of artifacts like state file and `.terraform` directory, even after performing a terraform destory. Sometimes it is a mild inconvenience, sometimes it can causes artifacts from past test runs leak into the current run. 

To avoid this scenario, terratest can copy the terraform files to a random temp directory and execute the test cases from there. This ensures that each run of terratest test cases are independent of each other.

```golang
exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "temp_terraform_test_dir")

terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: exampleFolder,
})
```

> WARNING: If terratest fails abruptly during execution, either through uncaught exceptions or through errors lower down in the stack (os, network etc.,) this can leave behind resources. Executing test cases in random directory makes it trickier to hunt down these orphaned resourrces and clean them up. 

### Testing in random regions
Sometimes it is better to run your test cases in random AWS regions to ensure that the test scenarios doesn't make any unknown assumptions about the pre-existing resources.  

```go
awsRegion := aws.GetRandomStableRegion(t, nil, nil)

terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
	EnvVars: map[string]string{
		"AWS_DEFAULT_REGION": awsRegion,
	},
})
```
