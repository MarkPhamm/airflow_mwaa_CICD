# AWS Setup for MWAA CI/CD

## 1. S3 Bucket (where your files go)

Create an S3 bucket with **versioning enabled** (MWAA needs version IDs for supporting files):

```bash
aws s3api create-bucket --bucket my-mwaa-bucket --region us-east-1
aws s3api put-bucket-versioning --bucket my-mwaa-bucket --versioning-configuration Status=Enabled
```

## 2. GitHub OIDC → AWS IAM Role (how GitHub authenticates)

This lets GitHub Actions get temporary AWS credentials without storing secrets.

### Step A: Create the OIDC identity provider in AWS

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Step B: Create an IAM role with a trust policy that only allows your repo

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:MarkPhamm/airflow_mwaa:*"
      }
    }
  }]
}
```

### Step C: Attach a policy to that role allowing S3 and MWAA access

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::my-mwaa-bucket",
        "arn:aws:s3:::my-mwaa-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetBucketVersioning", "s3api:HeadObject"],
      "Resource": "arn:aws:s3:::my-mwaa-bucket"
    },
    {
      "Effect": "Allow",
      "Action": ["airflow:UpdateEnvironment", "airflow:GetEnvironment"],
      "Resource": "*"
    }
  ]
}
```

## 3. Update deploy.yml with real values

Replace the placeholders with your actual values:

- `my-mwaa-environment` → your MWAA environment name
- `my-mwaa-bucket` → your S3 bucket name
- `123456789012` → your AWS account ID
- `my-mwaa-deploy-role` → the IAM role name you created

## Flow once configured

```
Merge PR → GitHub gets JWT → trades it for AWS creds via OIDC → uploads to S3 → updates MWAA
```
