# airflow_mwaa

Learning CI/CD with Airflow on Amazon MWAA.

## Project Structure

```
dags/               Airflow DAG files
dags/dbt/           dbt project (Snowflake)
plugins/            Airflow plugins (zipped for MWAA)
startup.sh          Runs on MWAA worker startup (installs dbt)
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
