# Lab 3

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 3 in this folder.
A real AWS account should use OpenID Connect (OIDC) to let GitHub Actions assume an IAM role and obtain temporary AWS credentials, rather than storing long-lived access keys as GitHub secrets, because OIDC reduces the risk of credential theft and exposure.

This course uses session-scoped secrets to provide temporary credentials for a limited lab session, and the damage from a leak is limited by their expiration, the IAM permissions granted to the session, and any applicable resource or account restrictions.
Terraform v1.10.3
## Experiments

1. Let the credentials die

The deploy workflow will likely fail at the AWS authentication or Terraform deployment step because the temporary session credentials have expired, with an error such as ExpiredToken: The security token included in the request is expired. After starting a new session and rerunning the refresh script, the workflow should succeed, and the number of repository files changed should be zero if the credentials are refreshed without modifying tracked files.

2. Remove the backend

After commenting out the S3 backend and running terraform init -migrate-state, Terraform may create a local terraform.tfstate file in lab3/ if state is migrated locally. The next CI plan may propose creating resources or show unexpected changes because CI uses the S3 remote state while the local configuration no longer declares that backend; restoring the backend and reinitializing returns the configuration to the intended remote-state setup.

3. Give the apply step a pull request

Changing the apply condition to if: always() could allow the apply step to run even when its normal safety conditions are not met, depending on the workflow's other dependencies and permissions. Someone able to open a pull request could potentially trigger unintended infrastructure changes using the workflow's AWS credentials, so the change must be reverted without merging it.

4. Race two applies

Setting cancel-in-progress: true suits a test suite because an older run can be cancelled when a newer commit arrives, saving time and resources, but it is risky for terraform apply because cancellation may interrupt an infrastructure change and leave resources partially updated. Terraform's use_lockfile provides S3 state locking to prevent concurrent operations against the same state, but without a concurrency group it does not prevent redundant workflow runs or serialize all workflow activity.
