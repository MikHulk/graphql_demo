from customers.model import Building, Site, Customer, Position, Area

import pytest


def test_coordinates():
    assert not Position("6.0", "8.0") < Position("6.0", "8.0")
    assert Position("6.0", "8.0") <= Position("6.0", "8.0")
    assert Position("6.0", "8.0") <= Position("6.000001", "8.0")
    assert not Position("6.0", "8.0") < Position("6.000001", "8.0")
    assert not Position("5.0", "9.0") <= Position("6.0", "8.0")
    assert not Position("5.0", "9.0") >= Position("6.0", "8.0")
    assert not Position("5.0", "9.0") == Position("6.0", "8.0")
    assert not Position("5.0", "9.0") < Position("6.0", "8.0")
    assert not Position("5.0", "9.0") > Position("6.0", "8.0")
    assert Position("6.0", "8.0") < Position("7.0", "9.0")
    assert Position("7.01", "9.01") > Position("7.0", "9.0")


def test_area():
    c = Customer(name="test_1")
    site1 = Site(
        owner=c,
        label="test_site_2",
        area=Area(Position("5.6", "1.3"), Position("6.2", "1.6")),
    )
    assert site1.area.contains(Position(long=6.0, lat=1.4))
    assert not site1.area.contains(Position(long=6.0, lat=2))
    assert not site1.area.contains(Position(long=4.0, lat=2))
    assert not site1.area.contains(Position(long=4.0, lat=1.6))
    assert not site1.area.contains(Position(long=6.0, lat=1.6))
    assert site1.area.contains(Position(long="6.0", lat="1.6"))
    assert site1.area.contains(Position(long=6.0, lat=1.5))
    assert Position("6.0", "1.6").is_in(site1.area)
    assert not Position("6.0", "1.601").is_in(site1.area)
    assert not Position("5.5", "1.6").is_in(site1.area)
    building1 = Building(label="building_1", position=Position("6.0", "1.6"))
    site1.buildings.append(building1)
    Building(label="building_2", position=Position("6.0", "1.6"), site=site1)

    building3 = Building(label="building_3", position=Position("4.0", "6.6"))
    with pytest.raises(ValueError):
        site1.buildings.append(building3)
    with pytest.raises(ValueError):
        Building(label="building_3", position=Position("4.0", "6.6"), site=site1)
    assert len(site1.buildings) == 2
    assert site1.buildings[0].label == "building_1"
    assert site1.buildings[1].label == "building_2"
