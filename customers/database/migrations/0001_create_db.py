from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool

from common.database import bootstrap


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

    try:
        if len(sys.argv) > 1 and sys.argv[1] == "--downgrade":
            bootstrap.downgrade(eng, pwd)
            print("db was destroyed")
        else:
            bootstrap.upgrade(eng, pwd)
            print("db was created")
    except RuntimeError as e:
        print(str(e), file=sys.stderr)
        sys.exit(2)
