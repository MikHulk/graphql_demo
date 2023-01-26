import os
import json
import logging
import logging.config


class Singleton(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super(Singleton, cls).__call__(*args, **kwargs)
        return cls._instances[cls]


def get_config():
    config_path = os.environ["CUSTOMERS_APP_CONFIG"]
    with open(config_path) as f:
        config = json.load(f)
    return config


if logging_config := get_config().get("logging"):
    logging.config.dictConfig(logging_config)
