from decimal import Decimal
from sqlalchemy import sql
from sqlalchemy.orm.properties import CompositeProperty


class CoordComparator(CompositeProperty.Comparator):
    def __gt__(self, other):
        return sql.and_(
            *[
                a > b
                for a, b in zip(
                    self.__clause_element__().clauses,
                    other.__composite_values__(),
                )
            ]
        )

    def __lt__(self, other):
        return sql.and_(
            *[
                a < b
                for a, b in zip(
                    self.__clause_element__().clauses,
                    other.__composite_values__(),
                )
            ]
        )

    def __ge__(self, other):
        return sql.and_(
            *[
                a >= b
                for a, b in zip(
                    self.__clause_element__().clauses,
                    other.__composite_values__(),
                )
            ]
        )

    def __le__(self, other):
        return sql.and_(
            *[
                a < b
                for a, b in zip(
                    self.__clause_element__().clauses,
                    other.__composite_values__(),
                )
            ]
        )

    def in_(self, other):
        if not isinstance(other, Area):
            raise ValueError()
        return sql.and_(
            self >= other.bottom_corner,
            self <= other.top_corner,
        )


class Position:
    def __init__(self, long, lat):
        self.long = Decimal(long)
        self.lat = Decimal(lat)

    @classmethod
    def _generate(cls, long, lat):
        if not all((long, lat)):
            return None
        return Position(long, lat)

    def __composite_values__(self):
        return self.long, self.lat

    def __repr__(self):
        return f"Position(longitude={self.long!r}, latitude={self.lat!r})"

    def __eq__(self, other):
        return (
            isinstance(other, Position)
            and other.lat == self.lat
            and other.long == self.long
        )

    def __lt__(self, other):
        return (
            isinstance(other, Position)
            and other.lat > self.lat
            and other.long > self.long
        )

    def __gt__(self, other):
        return (
            isinstance(other, Position)
            and other.lat < self.lat
            and other.long < self.long
        )

    def __le__(self, other):
        return (
            isinstance(other, Position)
            and other.lat >= self.lat
            and other.long >= self.long
        )

    def __ge__(self, other):
        return (
            isinstance(other, Position)
            and other.lat <= self.lat
            and other.long <= self.long
        )

    def __ne__(self, other):
        return not self.__eq__(other)

    def is_in(self, other):
        return isinstance(other, Area) and other.contains(self)


class Area:
    def __init__(self, bottom_corner, top_corner):
        self.bottom_corner = bottom_corner
        self.top_corner = top_corner
        if (
            self.bottom_corner.lat > self.top_corner.lat
            or self.bottom_corner.long > self.top_corner.long
        ):
            raise ValueError("inconsistent area.")

    @classmethod
    def _generate(
        cls, bottom_corner_long, bottom_corner_lat, top_corner_long, top_corner_lat
    ):
        if not all(
            (bottom_corner_long, bottom_corner_lat, top_corner_long, top_corner_lat)
        ):
            return None
        return Area(
            Position(bottom_corner_long, bottom_corner_lat),
            Position(top_corner_long, top_corner_lat),
        )

    def __composite_values__(self):
        return (
            self.bottom_corner.long,
            self.bottom_corner.lat,
            self.top_corner.long,
            self.top_corner.lat,
        )

    def __repr__(self):
        return f"Area(bottom_corner={self.bottom_corner!r}, top_corner={self.top_corner!r})"

    def __eq__(self, other):
        return (
            isinstance(other, Area)
            and other.top_corner == self.top_corner
            and other.bottom_corner == self.bottom_corner
        )

    def __ne__(self, other):
        return not self.__eq__(other)

    def contains(self, point):
        return (
            isinstance(point, Position)
            and point <= self.top_corner
            and point >= self.bottom_corner
        )
