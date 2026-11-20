# ACS730 Lab 6 — Infrastructure Automation and Golden AMI

## Overview

This lab demonstrates infrastructure provisioning, configuration management, automated machine-image creation, and CI/CD validation using AWS.

The implementation uses Terraform to provision EC2 web servers, Ansible to configure them through AWS Systems Manager (SSM), and Packer to build a reusable golden Amazon Machine Image (AMI). A GitHub Actions workflow validates the Terraform configuration and can optionally apply infrastructure changes and run Ansible.

## Architecture and Tools

- **AWS EC2:** Hosts the web server instances.
- **Terraform:** Provisions EC2 instances and their security group.
- **Amazon S3:** Stores remote Terraform state with encryption and state locking.
- **AWS Systems Manager:** Provides instance management and Ansible connectivity without requiring SSH access or long-lived SSH keys.
- **Ansible:** Installs the required packages, creates a dedicated application user, deploys the website, and manages the systemd service.
- **Packer:** Builds a golden AMI with the web application and service configuration already installed.
- **GitHub Actions:** Runs Terraform validation and planning, with optional infrastructure deployment and Ansible configuration.

## Terraform

Terraform provisions two Amazon Linux 2023 EC2 instances in the default VPC.

The web security group allows inbound HTTP traffic on TCP port 80. SSH access on port 22 is not required for the configuration workflow. Instances use the `LabInstanceProfile` IAM instance profile to communicate with AWS Systems Manager.

The Terraform state is stored remotely in the S3 bucket `acs730-tfstate-770670908864`, using the key `lab6/terraform.tfstate`. State encryption and S3 lock-file support are configured in the backend.

The `.gitignore` file excludes Terraform state, local Terraform metadata, credentials, and private key files.

## Ansible Configuration

Ansible uses the AWS EC2 dynamic inventory plugin to discover running instances tagged for Lab 6 and group them by their `Role` tag.

The web server role performs the following tasks:

1. Installs Python 3.
2. Creates a dedicated system user named `acs730web`.
3. Creates the application directory.
4. Deploys the website from a Jinja2 template.
5. Installs the `acs730-web` systemd service.
6. Enables the service at boot and ensures it is started.

Ansible connects through AWS Systems Manager rather than SSH.

### Idempotency

The role was executed more than once to check whether repeated configuration runs produce unnecessary changes.

The second run completed with no changes, demonstrating that the managed configuration was already in the desired state.

Evidence:
- `evidence/idempotency-run1.txt`
- `evidence/idempotency-run2.txt`
- `evidence/idempotency-role-run2.txt`

## Packer Golden AMI

Packer builds a reusable Amazon Linux 2023 image. During the image build, Ansible configures the web server and Packer copies an additional static page into the image at `/baked.html`.

The final image used for validation was:

- AMI ID: `ami-0f2c7fe4085237835`
- AMI name: `acs730-lab6-web-20261120-082645`
- Region: `us-east-1`

The first golden AMI test exposed an issue: the systemd service was installed and running during image creation but was not enabled to start automatically after a fresh boot.

The Ansible role was corrected by adding a systemd task with `enabled: true` and `state: started`. The image was rebuilt and tested on a new EC2 instance.

## Golden AMI Validation

A fresh EC2 instance was launched from the corrected AMI without running Ansible after launch.

Both HTTP requests succeeded:

| Test | Result |
|---|---|
| GET `/` | HTTP 200 OK |
| GET `/baked.html` | HTTP 200 OK |

The root page displayed the `golden-ami` build identifier. The second page confirmed that Packer had copied the static file into the image at build time.

The web service started automatically after launch.

Evidence:
- `evidence/packer-build.txt`
- `evidence/packer-manifest.json`
- `evidence/golden-ami.png`
- `evidence/boot-to-ready-golden.txt`

**Note:** The root page contains the hostname and private IP gathered during the image build. These values are baked into the page and therefore do not dynamically represent the new instance.

## Boot-to-Ready Measurements

The recorded measurements are:

| Deployment approach | Recorded time |
|---|---:|
| Ansible configuration after launch | 222 seconds (3 minutes 42 seconds) |
| Golden AMI | 282 seconds (4 minutes 42 seconds) |

The Ansible measurement includes the configuration-on-boot workflow. The golden AMI measurement records the interval from the launch timestamp to successful HTTP verification.

These measurements were collected in separate runs and are not a controlled performance comparison. The golden AMI test confirms that the application was available without post-launch Ansible configuration; it does not establish that this particular launch was faster.

## Experiments and Observations

### Experiment 1 — Ansible Idempotency

The Ansible role was executed repeatedly against the managed web servers.

The first run applied the required configuration. A subsequent run reported no changes because the instances already matched the desired state.

**Observation:** Idempotency makes configuration management repeatable and reduces unnecessary changes during subsequent deployments.

### Experiment 2 — Golden AMI Fresh-Boot Test

A new EC2 instance was launched from the rebuilt golden AMI. The instance passed its EC2 health checks, and both the main website and the Packer-baked page returned HTTP 200.

**Observation:** The corrected image starts the web service automatically without requiring Ansible to configure the instance after launch. Enabling the systemd service was essential to achieving this result.

## GitHub Actions Workflow

The workflow is stored at `.github/workflows/lab6-configure.yml`.

It:
1. Checks out the repository.
2. Installs Ansible and the required AWS collections.
3. Installs the AWS Systems Manager Session Manager plugin.
4. Configures AWS credentials from GitHub Secrets.
5. Initializes Terraform.
6. Runs Terraform plan.
7. Runs Terraform apply and Ansible configuration only when the workflow is manually dispatched with the `apply` input enabled.

The default workflow behavior is plan-only. The apply option is explicit because creating AWS resources can incur costs.

## Comparison and Lessons Learned

### Configuration after launch

**Advantages**
- Changes can be applied without rebuilding an AMI.
- The same Ansible role can maintain existing instances.
- Configuration remains easier to update centrally.

**Considerations**
- New instances must wait for SSM connectivity and configuration tasks.
- Package installation depends on network access and package repositories.
- Configuration must complete before the application is ready.

### Golden AMI

**Advantages**
- Required software and configuration are already present at launch.
- Reduces the need for post-launch configuration.
- Provides a reusable baseline for multiple instances.

**Considerations**
- Changes to the application or operating system require rebuilding and validating the image.
- Images can become outdated if they are not maintained.
- Image creation adds a separate build and validation process.

### Overall Lesson

Ansible and Packer solve related but different problems. Ansible manages the desired configuration of systems, while Packer creates reusable machine images. Combining them supports both repeatable configuration and consistent image creation.

AWS Systems Manager also provides a way to manage EC2 instances without opening SSH access or distributing SSH private keys.

## Evidence

The `evidence/` directory contains the inventory, idempotency, Packer build, golden AMI, and boot-to-ready test results.
