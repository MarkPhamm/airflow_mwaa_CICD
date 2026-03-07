# AWS Setup for MWAA CI/CD

## What You Need from Your Manager

Before you can start, get the following from your manager:

1. **AWS Access Key + Secret Key** — so you can run `aws configure` and use the CLI
2. **AWS Account ID** (12-digit number) — to fill in `<ACCOUNT_ID>` in the trust policy
3. **IAM permissions** — your user needs to be able to create OIDC providers, IAM roles, S3 buckets, and MWAA environments

## Overview

Once you have the above, follow these steps in order:

```text
aws configure (one-time local setup)
    ↓
Create S3 bucket (Step 1)
    ↓
Create OIDC provider (Step 2) — tells AWS "trust GitHub"
    ↓
Create IAM role with trust + permissions policies (Steps 3-4)
    ↓
Create MWAA environment (Step 5)
    ↓
Update deploy.yml with real values (Step 6)
    ↓
Merge a PR → CD pipeline works automatically
```

## Prerequisites

- An AWS account with IAM admin access
- AWS CLI installed (`brew install awscli`)
- AWS CLI configured (`aws configure`)
- Your AWS Account ID (12-digit number)

## Step 1: Create S3 Bucket

Create an S3 bucket with **versioning enabled** (MWAA needs version IDs for supporting files).

> **Important:** The bucket name must start with `airflow-` (MWAA requirement).

```bash
aws s3api create-bucket --bucket airflow-my-mwaa-bucket --region us-east-1
aws s3api put-bucket-versioning --bucket airflow-my-mwaa-bucket --versioning-configuration Status=Enabled
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

> Edit `docs/iam/permissions-policy.json` first — replace `airflow-my-mwaa-bucket` with your bucket name.

## Step 5: Create MWAA Environment

Create the MWAA environment pointing at your S3 bucket (or do this via the AWS console):

```bash
aws mwaa create-environment \
  --name my-mwaa-environment \
  --source-bucket-arn arn:aws:s3:::airflow-my-mwaa-bucket \
  --dag-s3-path dags \
  --execution-role-arn arn:aws:iam::<ACCOUNT_ID>:role/mwaa-execution-role \
  --network-configuration SubnetIds=subnet-xxx,SecurityGroupIds=sg-xxx
```

## Step 6: Update deploy.yml with Real Values

Replace the placeholders in `.github/workflows/deploy.yml`:

- `my-mwaa-environment` → your MWAA environment name
- `airflow-my-mwaa-bucket` → your S3 bucket name (must start with `airflow-`)
- `123456789012` → your AWS account ID
- `mwaa-deploy-role` → the IAM role name from Step 3

## Step 7: Test

Merge a PR to `main` and check the GitHub Actions tab. The deploy job should:

1. Authenticate to AWS via OIDC
2. Sync DAGs to S3
3. MWAA picks them up within 30 seconds

## Flow once configured

```text
Merge PR → GitHub gets JWT → trades it for AWS creds via OIDC → uploads to S3 → updates MWAA
```
