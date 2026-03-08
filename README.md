# airflow_mwaa

Learning CI/CD with Airflow on Amazon MWAA.

## Project Structure

```text
dags/               Airflow DAG files
dags/dbt/           dbt project (Snowflake)
plugins/            Airflow plugins (zipped for MWAA)
requirements.txt    Python packages for MWAA
.github/workflows/  CI/CD pipelines
```

## Local Development

```bash
make install-dev    # Create .venv and install dependencies
make airflow-init   # Initialize local Airflow database (once)
make test-dag DAG=example_dag  # Test a DAG locally
```

## CI/CD

- **CI** (`build.yml`): Lints DAGs on every pull request
- **CD** (`deploy.yml`): On merge to main, syncs files to S3 for MWAA
  - Always syncs DAGs to S3 (MWAA picks up within 30s)
  - If infra files changed: uploads supporting files and updates MWAA environment

## AWS Prerequisites

The CI/CD pipeline uses OIDC (no stored secrets) to authenticate with AWS.
You need the following AWS resources before the pipeline will work:

| Resource | What it does |
| -------- | ------------ |
| S3 Bucket | Stores DAGs and requirements.txt for MWAA |
| OIDC Provider | Registers GitHub as a trusted identity provider in AWS |
| IAM Role | Temporary identity GitHub Actions assumes via OIDC |
| MWAA Environment | The managed Airflow environment that reads DAGs from S3 |

### Setup steps

1. **Create AWS resources** using Terraform (see the [AWS](../AWS) repo for reference):
   - S3 bucket with versioning enabled
   - IAM OIDC provider for `token.actions.githubusercontent.com`
   - IAM role with trust policy scoped to **your** GitHub repo and permissions for S3 + MWAA

2. **Update `deploy.yml` with your own values** (do not use the values in this repo as-is):
   - `BUCKET_NAME`: your S3 bucket name
   - `MWAA_NAME`: your MWAA environment name
   - `role-to-assume`: your IAM role ARN (from `terraform output github_actions_role_arn`)
   - `AWS_REGION`: your AWS region

   The values currently in `deploy.yml` are specific to this project's AWS account.
   You must replace them with your own.

3. **Push to main** and the pipeline will:
   - Assume the IAM role via OIDC (no secrets needed)
   - Sync DAGs to S3
   - Update MWAA if infra files changed

## Related Project

- [`AWS`](../AWS) - Terraform infrastructure (S3 bucket, OIDC provider, IAM role)
