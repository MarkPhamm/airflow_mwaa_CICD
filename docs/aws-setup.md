# AWS Setup for MWAA CI/CD

## Prerequisites

- An AWS account with IAM admin access
- AWS CLI installed (`brew install awscli`)
- AWS CLI configured (`aws configure`)
- Your AWS Account ID (12-digit number)

## Step 1: Create S3 Bucket

Create an S3 bucket with **versioning enabled** (MWAA needs version IDs for supporting files):

```bash
aws s3api create-bucket --bucket my-mwaa-bucket --region us-east-1
aws s3api put-bucket-versioning --bucket my-mwaa-bucket --versioning-configuration Status=Enabled
```

## Step 2: Create GitHub OIDC Identity Provider

Tell AWS to trust GitHub as an identity provider (one-time setup):

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com
```

## Step 3: Create IAM Role with Trust Policy

Create a role that only your GitHub repo can assume. The trust policy is in `docs/iam/trust-policy.json`:

```bash
aws iam create-role \
  --role-name mwaa-deploy-role \
  --assume-role-policy-document file://docs/iam/trust-policy.json
```

> Edit `docs/iam/trust-policy.json` first — replace `<ACCOUNT_ID>` with your AWS account ID.

## Step 4: Attach Permissions to the Role

Give the role access to S3 and MWAA. The policy is in `docs/iam/permissions-policy.json`:

```bash
aws iam put-role-policy \
  --role-name mwaa-deploy-role \
  --policy-name mwaa-deploy-permissions \
  --policy-document file://docs/iam/permissions-policy.json
```

> Edit `docs/iam/permissions-policy.json` first — replace `my-mwaa-bucket` with your bucket name.

## Step 5: Create MWAA Environment

Create the MWAA environment pointing at your S3 bucket (or do this via the AWS console):

```bash
aws mwaa create-environment \
  --name my-mwaa-environment \
  --source-bucket-arn arn:aws:s3:::my-mwaa-bucket \
  --dag-s3-path dags \
  --execution-role-arn arn:aws:iam::<ACCOUNT_ID>:role/mwaa-execution-role \
  --network-configuration SubnetIds=subnet-xxx,SecurityGroupIds=sg-xxx
```

## Step 6: Update deploy.yml with Real Values

Replace the placeholders in `.github/workflows/deploy.yml`:

- `my-mwaa-environment` → your MWAA environment name
- `my-mwaa-bucket` → your S3 bucket name
- `123456789012` → your AWS account ID
- `my-mwaa-deploy-role` → the IAM role name from Step 3

## Step 7: Test

Merge a PR to `main` and check the GitHub Actions tab. The deploy job should:

1. Authenticate to AWS via OIDC
2. Sync DAGs to S3
3. MWAA picks them up within 30 seconds

## Flow once configured

```text
Merge PR → GitHub gets JWT → trades it for AWS creds via OIDC → uploads to S3 → updates MWAA
```
