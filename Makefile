# Install production dependencies only
install:
	pip install -r requirements.txt

# Create local venv with Python 3.12 (required by Airflow 2.x) and install all dev dependencies
install-dev:
	python3.12 -m venv .venv
	.venv/bin/pip install --upgrade pip
	.venv/bin/pip install -r requirements-dev.txt

# Initialize local Airflow database (run once after install-dev)
airflow-init:
	AIRFLOW_HOME=$(PWD)/airflow_home .venv/bin/airflow db init

# Test a DAG locally — usage: make test-dag DAG=example_dag
test-dag:
	AIRFLOW_HOME=$(PWD)/airflow_home \
	AIRFLOW__CORE__DAGS_FOLDER=$(PWD)/dags \
	.venv/bin/airflow dags test $(DAG) 2024-01-01

# Check code formatting and linting with ruff
lint:
	ruff format --diff
	ruff check

# Run all tests
test:
	pytest .

# Zip the plugins/ directory into plugins.zip for MWAA upload
# MWAA expects plugins as a single zip file in S3
package-plugins:
	@mkdir -p plugins
	@cd plugins && zip -r ../plugins.zip .

# Build plugins.zip and show what files are ready to upload to S3
deploy: package-plugins
	@echo "Built plugins.zip"
	@echo "Ready to upload:"
	@echo "  - plugins.zip"
	@echo "  - requirements.txt"
	@echo "  - startup.sh"
