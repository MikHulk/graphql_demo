import sys

from sqlalchemy import create_engine
from sqlalchemy.exc import OperationalError
from sqlalchemy.pool import StaticPool


def database_exists(eng):
    _, connect_args = eng.dialect.create_connect_args(eng.url)
    con = None
    try:
        con = eng.execution_options(isolation_level="READ UNCOMMITTED").connect()
    except OperationalError as e:

        if str(e.orig).endswith(
            f"FATAL:  database \"{connect_args.get('database', '')}\" does not exist\n"
        ):
            return False
        else:
            raise e
    finally:
        eng.dispose()
    return True


def create_database(eng, pwd=None):
    _, connect_args = eng.dialect.create_connect_args(eng.url)
    if pwd:
        adm_eng = create_engine(
            eng.url,
            connect_args={"database": "postgres", "password": pwd},
            poolclass=StaticPool,
        )
    else:
        adm_eng = create_engine(
            eng.url,
            connect_args={"database": "postgres"},
            poolclass=StaticPool,
        )

    with adm_eng.execution_options(isolation_level="AUTOCOMMIT").connect() as con:
        con.execute(
            f'CREATE DATABASE {connect_args["database"]} '
            "WITH "
            f'OWNER = {connect_args["user"]} '
            "ENCODING = 'UTF8' "
            "LC_COLLATE = 'en_US.utf8' "
            "LC_CTYPE = 'en_US.utf8' "
            "TABLESPACE = pg_default "
            "CONNECTION LIMIT = -1 "
            " IS_TEMPLATE = False; "
        )


def drop_database(eng, pwd=None):
    _, connect_args = eng.dialect.create_connect_args(eng.url)
    if pwd:
        adm_eng = create_engine(
            eng.url,
            connect_args={"database": "postgres", "password": pwd},
            poolclass=StaticPool,
        )
    else:
        adm_eng = create_engine(
            eng.url,
            connect_args={"database": "postgres"},
            poolclass=StaticPool,
        )

    with adm_eng.execution_options(isolation_level="AUTOCOMMIT").connect() as con:
        con.execute(
            f"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='{connect_args['database']}';"
        )
        con.execute(f'DROP DATABASE {connect_args["database"]};')


def upgrade(eng, pwd):
    if database_exists(eng):
        raise RuntimeError("database exists")
    create_database(eng, pwd=pwd)
    if not database_exists(eng):
        raise RuntimeError("database was not created as expected.")


def downgrade(eng, pwd):
    if not database_exists(eng):
        raise RuntimeError("database doesn't exists", file=sys.stderr)
    drop_database(eng, pwd=pwd)
    if database_exists(eng):
        raise RuntimeError("database was not destroyed as expected")
