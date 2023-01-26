from getpass import getpass
import os
import sys

from sqlalchemy import create_engine
from sqlalchemy.exc import NoResultFound
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from auth.model import User


if __name__ == "__main__":
    email = input("email(required):")
    db_password = getpass("db password:")

    if not (db_url := os.environ.get("POSTGRES_URL", False)):
        print("Don't know where db is. Fill POSTGRES_URL.", file=sys.stderr)
        sys.exit(1)

    print(f"connect to {db_url}")
    eng = create_engine(
        db_url, connect_args={"password": db_password}, poolclass=StaticPool
    )
    with Session(eng) as s:
        try:
            user = s.query(User).filter(User.email == email).one()
        except NoResultFound:
            print("user does net exist", file=sys.stderr)
            sys.exit(2)
        print(user.generate_token())

    sys.exit(0)
