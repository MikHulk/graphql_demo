from datetime import datetime, timedelta
import os
from hashlib import scrypt

from email_validator import validate_email, EmailNotValidError
import jwt
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    LargeBinary,
)
from sqlalchemy.orm import declarative_base, validates


Base = declarative_base()

_SCRYPT_N = 8
_SCRYPT_R = 16384
_SCRYPT_P = 1


class User(Base):
    __tablename__ = "users"

    id = Column("user_id", Integer, primary_key=True)
    email = Column(String, nullable=False)
    password = Column(LargeBinary, nullable=False)
    first_name = Column(String)
    last_name = Column(String)
    is_admin = Column(Boolean)

    @classmethod
    def check_pw_syntax(cls, pw):
        if len(pw) < 4:
            raise ValueError("Password must have a length greater than 4")
        return pw

    @classmethod
    def make_new(cls, email, password, first_name=None, last_name=None, is_admin=False):
        salt = os.urandom(16)
        cls.check_pw_syntax(password)
        hpwd = scrypt(password, salt=salt, n=_SCRYPT_N, r=_SCRYPT_R, p=_SCRYPT_P)
        return User(
            email=email,
            password=salt + hpwd,
            first_name=first_name,
            last_name=last_name,
            is_admin=is_admin,
        )

    @validates("email")
    def validate_email(self, _, email):
        try:
            validate_email(email, check_deliverability=False)
        except EmailNotValidError as e:
            raise ValueError(str(e)) from e
        return email

    @property
    def audience_urn(self):
        if self.is_admin:
            return "urn:admin"
        else:
            return "urn:user"

    def check_password(self, pw):
        salt = self.password[:16]
        hpwd = self.password[16:]
        return scrypt(pw, salt=salt, n=_SCRYPT_N, r=_SCRYPT_R, p=_SCRYPT_P) == hpwd

    def generate_token(self):
        if not (secret_path := os.environ.get("AUTH_SERVER_SECRET_PATH", False)):
            raise RuntimeError("no path to secret. please set AUTH_SERVER_SECRET_PATH.")
        with open(secret_path) as f:
            secret = f.readline()
        payload = {
            "exp": (datetime.utcnow() + timedelta(minutes=1)).timestamp(),
            "nbf": (datetime.utcnow() - timedelta(minutes=1)).timestamp(),
            "aud": self.audience_urn,
            "email": self.email,
        }
        return jwt.encode(payload, secret, algorithm="HS256")
