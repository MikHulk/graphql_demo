from getpass import getpass
import os
import sys

from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from auth.model import User


if __name__ == "__main__":
    email = input("email(required):")
    last_name = input("last name:")
    first_name = input("first name:")
    is_admin = input("is administrator(y/N):").lower() == "Y" or False
    password = getpass("password:").encode()
    db_password = getpass("db password:")

    if not (db_url := os.environ.get("POSTGRES_URL", False)):
        print("Don't know where db is. Fill POSTGRES_URL.", file=sys.stderr)
        sys.exit(1)

    print(f"connect to {db_url}")
    eng = create_engine(
        db_url, connect_args={"password": db_password}, poolclass=StaticPool
    )
    try:
        new_user = User.make_new(
            email,
            password=password,
            last_name=last_name,
            first_name=first_name,
            is_admin=is_admin,
        )
    except ValueError as e:
        print(e, file=sys.stderr)
        sys.exit(2)
    with Session(eng) as s:
        s.add(new_user)
        s.commit()
