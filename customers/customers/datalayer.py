import json
import os
import logging

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from customers.lib import Singleton


log = logging.getLogger(__name__)


class DbService(metaclass=Singleton):
    def __init__(self, config):
        log.debug("initialize db service")
        self.db_url = config["db_url"]
        self.eng_config = config.get("db_engine", {})
        self.eng = create_async_engine(self.db_url, **self.eng_config)
        self.session = sessionmaker(
            self.eng, expire_on_commit=False, class_=AsyncSession
        )
