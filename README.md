# GitOps AWS IAM Admin Access Management

Automated self-service workflow to grant AWS Account Administrator access (`sts:AssumeRole`) to IAM users using **GitHub Issues**, **GitHub Actions**, and **Terraform**.

---

## Architecture & Workflow

1. **Access Request (GitHub Issue):** A user or administrator opens an issue using the **Request AWS Admin Role Access** template and enters the target AWS IAM username.
2. **Event Trigger (GitHub Actions):** Opening an issue with the `iam-access` label automatically triggers the `Grant AWS Admin Role Access` workflow.
3. **State Update:** The workflow parses the IAM username from the issue body, appends it to `terraform/users.tfvars.json` (deduplicated via `jq`), and commits the updated configuration back to `main`.
4. **Infrastructure Provisioning (Terraform):** GitHub Actions initializes Terraform with an S3 remote backend and runs `terraform apply` to update the **Trust Policy** (`assume_role_policy`) of `GitOps-Admin-Role`.
5. **Feedback & Closure:** Once applied, the workflow comments confirmation on the issue and closes it automatically.

---

## Repository Structure

```text
.
├── .github
│   ├── ISSUE_TEMPLATE
│   │   └── grant_admin_access.yml   # Structured Issue Form for IAM username input
│   └── workflows
│       └── grant_access.yml         # CI/CD pipeline to parse issue, commit & run Terraform
└── terraform
    ├── main.tf                      # IAM Role, Admin Policy, Trust Policy & S3 Backend
    └── users.tfvars.json            # Dynamic list of allowed IAM usernames


Prerequisites & Setup
1. AWS Configuration
S3 Remote Backend: Create an S3 bucket (e.g., your-terraform-state-bucket173173 in us-east-1) to store iam-admin-role/terraform.tfstate.

IAM Permissions: Ensure the AWS credentials used by GitHub Actions have permissions to manage IAM roles/policies (iam:CreateRole, iam:UpdateAssumeRolePolicy, iam:CreatePolicy, iam:AttachRolePolicy, iam:GetRole) and read/write to the Terraform state S3 bucket.

2. GitHub Repository Settings
Repository Secrets (Settings -> Secrets and variables -> Actions):

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

Workflow Permissions (Settings -> Actions -> General):

Enable Read and write permissions so GitHub Actions can push updates to terraform/users.tfvars.json and comment/close issues.

Usage
Navigate to the Issues tab and click New issue.

Select Request AWS Admin Role Access.

Enter the exact existing AWS IAM Username (e.g., mostafa) and click Create.

Monitor progress in the Actions tab. Once completed, the user can assume GitOps-Admin-Role in AWS.
