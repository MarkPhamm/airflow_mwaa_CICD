from airflow.plugins_manager import AirflowPlugin
from airflow.models import BaseOperator


class HelloOperator(BaseOperator):
    """A simple custom operator that logs a greeting."""

    def __init__(self, name, greeting="Hello", **kwargs):
        super().__init__(**kwargs)
        self.name = name
        self.greeting = greeting

    def execute(self, context):
        self.log.info(f"{self.greeting} {self.name} from our custom plugin!")


class HelloPlugin(AirflowPlugin):
    name = "hello_plugin"
    operators = [HelloOperator]
