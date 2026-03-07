#!/bin/bash

# Only run on worker nodes
if [[ "${MWAA_AIRFLOW_COMPONENT}" != "worker" ]]; then
    exit 0
fi

echo "Installing dbt into virtual environment..."

python3 -m venv /tmp/dbt-env
source /tmp/dbt-env/bin/activate
pip install dbt-core==1.10.5 dbt-snowflake==1.9.2
deactivate

echo "dbt installation complete."
