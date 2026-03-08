from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime
from hello_plugin import HelloOperator

with DAG(
    dag_id="example_dag",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
) as dag:
    hello = BashOperator(
        task_id="say_hello",
        bash_command="echo 'Hello from MWAA!'",
    )

    greet = HelloOperator(
        task_id="custom_greeting",
        name="Mark",
    )

    goodbye = BashOperator(
        task_id="say_goodbye",
        bash_command="echo 'Goodbye from MWAA!'",
    )

    hello >> greet >> goodbye
