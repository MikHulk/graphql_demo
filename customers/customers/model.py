import enum

from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    Numeric,
    Enum,
    ForeignKey,
    PrimaryKeyConstraint,
    types,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import declarative_base, validates, relationship, composite

from customers.geo import Area, Position, CoordComparator


Base = declarative_base()


class Role(enum.Enum):
    ADMIN = "Admin"
    WRITTER = "Writter"
    READER = "Reader"


class CustomerUserRole(Base):
    __tablename__ = "users_customers_rel"

    user_id = Column(ForeignKey("users.user_id"))
    customer_id = Column(ForeignKey("customers.customer_id"))
    role = Column(Enum(Role), nullable=False)
    user = relationship("User", back_populates="customer_roles", lazy="joined")
    customer = relationship("Customer", back_populates="user_roles", lazy="joined")
    __table_args__ = (
        PrimaryKeyConstraint("user_id", "customer_id", name="users_customers_rel_pk"),
    )

    def __str__(self):
        return f"{self.user} as {self.role} for {self.customer}"


class User(Base):
    __tablename__ = "users"

    id = Column("user_id", Integer, primary_key=True)
    email = Column(String, nullable=False, unique=True)
    customer_roles = relationship(CustomerUserRole, back_populates="user")

    def __str__(self):
        return f"User({self.id}):{self.email}"


class Customer(Base):
    __tablename__ = "customers"

    id = Column("customer_id", Integer, primary_key=True)
    name = Column(String, nullable=False, unique=True)
    location = Column(JSONB, nullable=False, server_default="{}")
    is_active = Column(Boolean, nullable=False, server_default="true")
    user_roles = relationship(CustomerUserRole, back_populates="customer")
    sites = relationship("Site", back_populates="owner", cascade="all, delete-orphan")

    def __str__(self):
        return f"Customer({self.id}):{self.name}"


class Site(Base):
    __tablename__ = "sites"

    id = Column("site_id", Integer, primary_key=True)
    customer_id = Column(
        Integer,
        ForeignKey(
            "customers.customer_id",
            onupdate="CASCADE",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    label = Column(String, nullable=False)
    address = Column(JSONB, server_default="[]")
    zip_code = Column(String)
    city = Column(String)
    bottom_corner_long = Column("long_1", Numeric(11, 8))
    bottom_corner_lat = Column("lat_1", Numeric(11, 8))
    top_corner_long = Column("long_2", Numeric(11, 8))
    top_corner_lat = Column("lat_2", Numeric(11, 8))

    owner = relationship(Customer, back_populates="sites")
    buildings = relationship("Building", back_populates="site", cascade="all, delete-orphan")

    area = composite(
        Area._generate,
        bottom_corner_long,
        bottom_corner_lat,
        top_corner_long,
        top_corner_lat,
    )

    @validates("buildings")
    def validate_building(self, _, building):
        """Check if building position is in site area."""
        if self.area and not (
            building.position and self.area.contains(building.position)
        ):
            raise ValueError("building coordinates are not in site area.")
        return building

    def __str__(self):
        return f"Site({self.id}):{self.label}"


class Building(Base):
    __tablename__ = "buildings"

    id = Column("building_id", Integer, primary_key=True)
    site_id = Column(Integer, ForeignKey("sites.site_id"), nullable=False)
    label = Column(String, nullable=False)
    lat = Column(Numeric(11, 8))
    long = Column(Numeric(11, 8))

    site = relationship(Site, back_populates="buildings")

    position = composite(
        Position._generate, long, lat, comparator_factory=CoordComparator
    )

    @validates("lat", "long")
    def check_pos(self, key, value):
        if self.site and self.position and not self.site.area.contains(self.position):
            raise ValueError("building coordinates are not in site area.")
        return value

    def __str__(self):
        return f"Building({self.id}):{self.label}"
