# Lab 5 — Terraform Infrastructure and CI with LocalStack

Put your work for Lab 5 in this folder.

## What I built

In this lab, I built and tested AWS network infrastructure using Terraform and LocalStack.

The configuration includes:

- A Virtual Private Cloud (VPC).
- Multiple public subnets.
- An internet gateway.
- Route tables and subnet associations.
- Security groups and ingress/egress rules.
- Terraform variables and reusable resource definitions.
- An optional S3 artifact bucket.

I used LocalStack to simulate AWS services and test the Terraform configuration without creating infrastructure in the real AWS account.

I also created a GitHub Actions workflow to automate Terraform formatting, initialization, validation, planning, applying, and destroying resources against LocalStack.

The workflow uses two jobs:

1. **Formatting and validation:** Checks Terraform formatting, initializes the configuration without a backend, and validates the Terraform files.
2. **LocalStack plan and apply:** Runs only after the first job succeeds. It starts LocalStack, initializes Terraform, creates a plan, applies the configuration, and runs Terraform destroy for cleanup.

## Why for_each here and count there

### Why subnets use for_each

Subnets are distinct resources with stable names, so `for_each` is the better choice. Each subnet is identified by a key in a map, which gives it a stable Terraform resource address.

- Adding key `c` creates only one new subnet: 1 to add, 0 to change, 0 to destroy.
- Removing key `a` destroys only that subnet. Subnet `b` remains untouched.

This makes changes predictable and avoids unnecessary replacement of resources.

### Why count would be a trap for subnets

Using `count` would assign numeric addresses such as `[0]`, `[1]`, and `[2]`. If the middle entry were removed, Terraform could associate the remaining list positions with different subnet configurations. This could result in unnecessary updates or resource replacement.

For distinct resources, `for_each` provides more stable and meaningful resource addresses.

### Why the bucket uses count

The artifact bucket is optional: the input is a yes/no decision about one resource. `count` is appropriate because there are only two possible outcomes:

- `create_artifact_bucket = false`: 0 buckets added.
- `create_artifact_bucket = true`: 1 bucket added.

There is no need for a map of named resources when the configuration only controls whether one bucket exists.

In short: **use count when the question is how many, and for_each when the question is which ones.**

## Experiments

The experiments compare Terraform behavior and CI validation under different configuration changes. Predictions should be written before running each experiment. After observing the result, the configuration should be restored to its original state.

### Experiment 1 — Swap for_each for count on the subnets

**Prediction:** Using `count` with a list of three subnet CIDRs assigns numeric indexes to the resources. Removing the middle CIDR shifts the index of the remaining subnet. Terraform may therefore propose updating or replacing resources instead of simply removing the intended subnet.

**Observation and explanation:** With `count`, Terraform identifies subnet instances by numeric position. Removing an item from the middle of a list can change the configuration associated with the remaining indexes. With `for_each`, each subnet retains its own key, so removing one key targets only that subnet. This demonstrates why `for_each` is more suitable for distinct resources.

### Experiment 2 — Delete depends_on

**Prediction:** Removing the explicit `depends_on` may not change the Terraform plan because Terraform can still build a valid dependency graph from the references in the configuration.

**Observation and explanation:** A valid dependency graph does not always guarantee that an EC2 instance has working internet connectivity. The instance may be created before the required network configuration is fully ready if the dependency is not represented in the graph. LocalStack does not boot a real EC2 instance or verify actual internet connectivity, so this problem may not be visible in its tests. A real AWS test would be needed to verify the behavior.

### Experiment 3 — Break only the formatting

**Prediction:** Adding unnecessary spaces before a closing brace should cause the Terraform formatting check to fail. Because the LocalStack job depends on the formatting and validation job, it should be skipped when the first job fails.

**Observation and explanation:** The formatting check catches style problems before the more expensive LocalStack job starts. This ordering saves the time that would otherwise be spent starting the container and running Terraform operations. Running `terraform fmt -recursive` restores the formatting, and `git diff` can be used to inspect the correction.

### Experiment 4 — Turn the bucket off

**Prediction:** Setting `create_artifact_bucket = false` should remove the optional bucket from the Terraform configuration. The behavior of `terraform output artifact_bucket` depends on how the output is defined. Using `one()` on an empty collection returns `null`, while indexing an empty collection with `[0]` produces an error.

**Observation and explanation:** This experiment demonstrates why optional resources need outputs that safely handle both zero and one instances. The `one()` function is suitable for an optional resource because it returns `null` when the collection is empty. Direct indexing assumes an element exists and is therefore unsafe when the bucket is disabled.

### Experiment 5 — Point at real AWS on purpose, plan only

**Prediction:** Running Terraform without the LocalStack variable file changes the provider target to the configured real AWS environment, assuming the default provider configuration is AWS. The resulting plan depends on the variables, credentials, existing infrastructure, and AMI data available in that account.

**Observation and explanation:** A plan without the LocalStack variable file can target real AWS rather than the local simulation. The provider target output or warning should be checked before running Terraform. This experiment must remain plan-only. No real AWS infrastructure should be applied or created as part of this test.

**Safety:** Never run `terraform apply` during this experiment. Always verify the provider endpoint and variable file before executing Terraform operations.

## Why not plan and apply against real AWS on every pull request

Running Terraform plan and apply against real AWS on every pull request is not a practical approach for this course. LocalStack provides a more suitable environment for frequent automated testing.

### Cost

Real infrastructure can incur charges every time a pull request creates resources. With 27 students making several changes, repeated creation and destruction could result in thousands of infrastructure cycles against the course's fixed $50 budget. LocalStack does not incur AWS infrastructure charges and allows testing without leaving real AWS resources behind.

### Credentials and security

Running Terraform apply against real AWS through GitHub Actions requires AWS credentials to be stored as GitHub repository secrets. Long-lived access keys introduce security risks because they could be exposed and need to be rotated.

In the AWS Academy environment, IAM write permissions are restricted. This makes it difficult to create narrowly scoped credentials, meaning that a working access key could require broader permissions than necessary.

### Expiring Academy sessions

AWS Academy credentials are temporary and generally last only a few hours. A pull request opened on Saturday night could fail on Sunday morning because its credentials have expired, even if the Terraform configuration has not changed.

These failures are unrelated to code quality. When developers repeatedly encounter misleading failures, they may stop trusting or paying attention to CI results. A check that developers ignore is less useful than a reliable check.

### Speed and reliability

Real AWS operations take time to create and destroy infrastructure. They can also encounter API rate limits, eventual-consistency delays, and failures unrelated to the configuration being tested.

When multiple students use the same AWS account, concurrent pull requests can also create conflicts involving resource names, shared infrastructure, or Terraform state.

LocalStack makes these tests faster and more isolated.

### Limitations of LocalStack

A successful LocalStack run confirms that the Terraform configuration is syntactically valid, that the resource dependency graph can be planned, and that the supported resources can be applied and destroyed in the simulated environment.

However, a green LocalStack result does not prove everything will work in real AWS. LocalStack does not fully enforce AWS IAM permissions, and it does not boot a real EC2 instance to verify that its `user_data` script works.

Therefore, real AWS validation is still important. It should be performed separately, such as after merging or on a scheduled basis, rather than on every pull request.

## CI failure and recovery test

As part of Part 10, I deliberately introduced an incorrect Terraform variable reference in the network configuration.

The GitHub Actions workflow detected the undeclared variable during Terraform validation. The validation job failed, and the LocalStack job was skipped because it depends on the successful completion of the validation job.

After correcting the variable reference, I pushed the fix and ran the workflow again. This demonstrated how required status checks prevent an invalid Terraform configuration from passing the pull request checks.

The pull request was subsequently merged after the required merge conditions were satisfied.

## Cleanup and validation

The Terraform resources were tested against LocalStack, and the cleanup process was used to destroy the simulated infrastructure.

The final validation includes:

- Terraform formatting and validation.
- Terraform plan and apply against LocalStack.
- Terraform destroy against LocalStack.
- Verification that the test VPC resources were removed.
- GitHub Actions results showing the deliberate failure and successful corrected run.
- Verification that no Lab 5 resources remain in the real AWS account.
- Git history checks for accidentally committed Terraform state files, private keys, or credentials.

The purpose of this lab was to build reproducible Terraform infrastructure and a CI workflow that catches configuration errors early while keeping routine testing isolated from the real AWS environment.
