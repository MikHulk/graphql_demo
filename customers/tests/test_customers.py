import os

import pytest

from sqlalchemy import create_engine, delete
from sqlalchemy.orm import Session, joinedload
from sqlalchemy.pool import StaticPool

from common.database.bootstrap import create_database, drop_database
from customers.model import Base, Customer, Building, Site, Area, Position


@pytest.fixture(scope="module")
def db():
    if not (db_url := os.environ.get("POSTGRES_TEST_URL", False)):
        raise RuntimeError(
            f"cannot perform {__file__} without a db connexion. set POSTGRES_TEST_URL env variable"
        )
    eng = create_engine(db_url, echo=True, poolclass=StaticPool)
    create_database(eng)
    Base.metadata.create_all(eng)
    yield eng
    Base.metadata.drop_all(eng)
    drop_database(eng)


@pytest.fixture(scope="function")
def load_customer(db):
    c = Customer(name="test_1")
    site1 = Site(owner=c, label="test_site_1")
    site2 = Site(
        owner=c,
        label="test_site_2",
        area=Area(Position("5.6", "1.3"), Position("6.2", "1.6")),
    )
    building_1 = Building(label="building_1")
    site1.buildings.append(building_1)
    building_2 = Building(label="building_2", position=Position("7.0", "1.5"))
    site1.buildings.append(building_2)
    building_3 = Building(label="building_3", position=Position("6.0", "1.5"))
    site2.buildings.append(building_3)
    with Session(db) as s:
        s.add(c)
        s.add(site1)
        s.add(site2)
        s.add(building_1)
        s.add(building_2)
        s.add(building_3)
        s.commit()
        c_id = c.id
    print(c_id)
    yield
    with Session(db) as s:
        print("delete")
        c = s.query(Customer).filter_by(id=c_id).one()
        s.delete(c)
        s.commit()


@pytest.mark.usefixtures("load_customer")
def test_error_when_change_for_bad_pos(db):
    with Session(db) as s:
        building = s.query(Building).filter_by(label="building_3").one()
        assert building.position == Position("6.0", "1.5")
        assert building.site.area == Area(
            Position("5.6", "1.3"), Position("6.2", "1.6")
        )
        with pytest.raises(ValueError):
            building.position = Position("-1.0", "-4.0")
        building.position = Position("5.9", "1.4")


@pytest.mark.usefixtures("load_customer")
def test_error_when_out_of_area(db):
    with Session(db) as s:
        c = (
            s.query(Customer)
            .options(joinedload(Customer.sites).subqueryload(Site.buildings))
            .one()
        )
        assert len(c.sites) == 2
        site = c.sites[1]

        building = Building(label="bad", position=Position("6.201", "1.60001"))
        with pytest.raises(ValueError):
            site.buildings.append(building)
        s.commit()

        building = Building(label="bad", position=Position("5.59999", "1.29999"))
        with pytest.raises(ValueError):
            site.buildings.append(building)
        s.commit()

        building = Building(label="bad", position=Position("6.1", "1.60001"))
        with pytest.raises(ValueError):
            site.buildings.append(building)
        s.commit()

        building = Building(label="bad", position=Position("6.1", "1.29999"))
        with pytest.raises(ValueError):
            site.buildings.append(building)
        s.commit()

        building = Building(label="bad", position=Position("6.201", "1.5"))
        with pytest.raises(ValueError):
            site.buildings.append(building)
        s.commit()

        building = Building(label="bad", position=Position("6.59999", "1.5"))
        with pytest.raises(ValueError):
            site.buildings.append(building)
        s.commit()


@pytest.mark.usefixtures("load_customer")
def test_ok_in_area(db):
    with Session(db) as s:
        c = (
            s.query(Customer)
            .options(joinedload(Customer.sites).subqueryload(Site.buildings))
            .one()
        )
        assert len(c.sites) == 2
        site = c.sites[1]
        print(site, site.area)
        building = Building(label="ok", position=Position("5.7", "1.5"))
        site.buildings.append(building)
        s.commit()
        assert s.query(Building).filter_by(label="ok").one()

        building = Building(label="ok", position=Position("5.6", "1.3"))
        site.buildings.append(building)
        s.commit()

        building = Building(label="ok", position=Position("6.2", "1.6"))
        site.buildings.append(building)
        s.commit()

        building = Building(label="ok", position=Position("5.6", "1.5"))
        site.buildings.append(building)
        s.commit()

        building = Building(label="ok", position=Position("5.7", "1.6"))
        site.buildings.append(building)
        s.commit()

        building = Building(label="ok", position=Position("5.6", "1.6"))
        site.buildings.append(building)
        s.commit()

        building = Building(label="ok", position=Position("6.2", "1.3"))
        site.buildings.append(building)
        s.commit()
