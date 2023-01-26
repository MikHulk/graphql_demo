from sqlalchemy import (
    create_engine,
    Table,
    MetaData,
    Column,
    Integer,
    String,
    Boolean,
    LargeBinary,
)
from sqlalchemy.pool import StaticPool


def upgrade(eng, _):
    metadata = MetaData()
    users_table = Table(
        "users",
        metadata,
        Column("user_id", Integer, primary_key=True),
        Column("email", String, nullable=False, unique=True),
        Column("password", LargeBinary, nullable=False),
        Column("first_name", String, server_default=""),
        Column("last_name", String, server_default=""),
        Column("is_admin", Boolean, nullable=False, server_default="false"),
    )
    print("create table", users_table)
    metadata.create_all(eng)


def downgrade(eng, _):
    metadata = MetaData()
    users_table = Table(
        "users",
        metadata,
    )
    print("delete table", users_table)
    users_table.drop(eng)


if __name__ == "__main__":
    import sys
    from getpass import getpass
    from os import environ

    pwd = getpass("password: ")
    if not (db_url := environ.get("POSTGRES_URL", False)):
        print("Don't know where db is. Fill POSTGRES_URL.", file=sys.stderr)
        sys.exit(1)

    print(f"connect to {db_url}")
    eng = create_engine(db_url, connect_args={"password": pwd}, poolclass=StaticPool)

    if len(sys.argv) > 1 and sys.argv[1] == "--downgrade":
        downgrade(eng, pwd)
    else:
        upgrade(eng, pwd)
