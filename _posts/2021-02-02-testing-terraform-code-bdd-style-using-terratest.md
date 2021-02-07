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

Testing terraform code is a tricky thing. Terratest is often used to test terraform module. 

<!--more-->

## A simple test scenario
Suppose we have a terraform module that deploys a lamda function like below.

```terraform
terraform {
  required_version = ">= 0.12.26"
}

provider "aws" {
  region = "us-east-2"
}

provider "archive" {
  version = "1.3"
}

data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_example.zip"
}

resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  function_name    = "lambda_example"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda"
  runtime          = "go1.x"
}

resource "aws_iam_role" "lambda" {
  name               = "lambda_example_role"
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
```

Here is the lambda function code which simply returns a greeting for the input term:

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

To test this, create a test case file called `main_test.go` with the following folder structure:

```
📁 lambda_example 
   ├ 📁 src
   │   ├ 📄 handler.go
   ├ 📁 test
   │   ├ 📄 main_test.go
   ├ 📄 main.tf
```

The contents of the test case is:

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

	// Invoke the function, so we can test its output
	response := aws.InvokeFunction(t, awsRegion, functionName, "World")

	assert.Equal(t, `"hi!"`, string(response))


}

```

To test the module, simply run `go test` command under the test directory.

```
cd test
go test -v
```

If you you have multiple tests, you can run a specific test as well

```
go test -run TestTerraformAwsLambdaFunction
```

Note that terratest provisions real resources and it is going to cost money. We follow up the test cases by a deferred call to `terraform.Destroy` method which takes care of cleaning the resources which we just created.


## Tips for testing with terratest
### Testing in random folder
Terraform init and apply steps leaves behind a bunch of artifacts like state file and `.terraform` directory, even if after we perform a terraform destory. Sometimes it is a mild inconvenience, sometimes it can causes the current test cases to be affected by left over state from past runs. To avoid this scenario, terratest can copy the terraform files to a random temp directory and execute the test cases from there. This ensures that each run of terratest test cases are independent of each other

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
