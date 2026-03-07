from airflow.plugins_manager import AirflowPlugin
from airflow.models import BaseOperator


class HelloOperator(BaseOperator):
    """A simple custom operator that logs a greeting."""

    def __init__(self, name, **kwargs):
        super().__init__(**kwargs)
        self.name = name

    def execute(self, context):
        self.log.info(f"Hello {self.name} from our custom plugin!")


class HelloPlugin(AirflowPlugin):
    name = "hello_plugin"
    operators = [HelloOperator]
