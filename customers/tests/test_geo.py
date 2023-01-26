from decimal import Decimal

from customers.geo import Position, Area


def test_position_syntax():
    p = Position("3.14", "7.2")
    assert p.long == Decimal("3.14")
    assert p.lat == Decimal("7.2")
    assert Position("1.2", "4.5") == Position._generate("1.2", "4.5")
    assert Position._generate(None, None) == None


def test_position_arithmetic():
    p1 = Position("3.1", "7.2")
    assert p1 == p1
    p2 = Position("3.1", "7.3")
    assert p2 == p2

    assert not p1 == p2
    assert not p1 > p2
    assert not p1 < p2

    p3 = Position("3.2", "7.3")

    assert not p3 == p2
    assert not p3 > p2
    assert not p3 < p2

    assert not p3 == p1
    assert p3 > p1
    assert not p3 < p1
    assert p1 < p3


def test_area_syntax():
    bottom = Position("3.14", "7.2")
    top = Position("4.1", "9.8")
    area = Area(bottom, top)
    assert area.bottom_corner == bottom
    assert area.top_corner == top


def test_area_inclusion():
    bottom = Position("3.14", "7.2")
    top = Position("4.1", "9.8")
    area = Area(bottom, top)

    assert area.contains(Position("3.9", "8.004"))
    assert not area.contains(Position("3.9", "9.800000001"))
    assert area.contains(Position("4.1", "7.2"))
    assert not area.contains(Position("4.11", "9.7"))
