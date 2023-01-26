import enum

from sqlalchemy import (
    create_engine,
    Table,
    MetaData,
    Column,
    Integer,
    Numeric,
    String,
    Boolean,
    JSON,
    ForeignKey,
    Enum,
    PrimaryKeyConstraint,
    CheckConstraint,
)
from sqlalchemy.pool import StaticPool


class Role(enum.Enum):
    ADMIN = "Admin"
    WRITTER = "Writter"
    READER = "Reader"


metadata = MetaData()

customers_table = Table(
    "customers",
    metadata,
    Column("customer_id", Integer, primary_key=True),
    Column("name", String, nullable=False, unique=True),
    Column("location", JSON, nullable=False, server_default="{}"),
    Column("is_active", Boolean, nullable=False, server_default="true"),
)

users_customers_rel_table = Table(
    "users_customers_rel",
    metadata,
    Column("user_id", Integer, ForeignKey("users.user_id")),
    Column("customer_id", Integer, ForeignKey("customers.customer_id")),
    PrimaryKeyConstraint("user_id", "customer_id", name="users_customers_rel_pk"),
    Column("role", Enum(Role), nullable=False),
)

users_table = Table(
    "users",
    metadata,
    Column("user_id", Integer, primary_key=True),
    Column("email", String, nullable=False, unique=True),
)

sites_table = Table(
    "sites",
    metadata,
    Column("site_id", Integer, primary_key=True),
    Column(
        "customer_id",
        Integer,
        ForeignKey(
            "customers.customer_id",
            onupdate="CASCADE",
            ondelete="CASCADE"
        ),
        nullable=False
    ),
    Column("label", String, nullable=False),
    Column("address", JSON, nullable=False, server_default="[]"),
    Column("zip_code", String),
    Column("city", String),
    Column("lat_1", Numeric(11, 8)),
    Column("long_1", Numeric(11, 8)),
    Column("lat_2", Numeric(11, 8)),
    Column("long_2", Numeric(11, 8)),
    CheckConstraint(
        "lat_1 IS NULL AND long_1 IS NULL AND lat_2 IS NULL AND long_2 IS NULL OR "
        "lat_1 IS NOT NULL AND long_1 IS NOT NULL AND lat_2 IS NOT NULL AND long_2 IS NOT NULL",
        name="sites_check_coordinates",
    ),
)

buildings_table = Table(
    "buildings",
    metadata,
    Column("building_id", Integer, primary_key=True),
    Column("site_id", Integer, ForeignKey("sites.site_id"), nullable=False),
    Column("label", String, nullable=False),
    Column("lat", Numeric(11, 8)),
    Column("long", Numeric(11, 8)),
    CheckConstraint(
        "Lat IS NULL AND long IS NULL OR lat IS NOT NULL AND long IS NOT NULL",
        name="buildings_check_coordinates",
    ),
)


def upgrade(eng, _):
    print("create tables")
    metadata.create_all(eng)


def downgrade(eng, _):
    print("delete tables")
    metadata.drop_all(eng)


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
