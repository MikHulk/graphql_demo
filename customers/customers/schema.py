from decimal import Decimal
import logging
import typing

import strawberry


log = logging.getLogger(__name__)


@strawberry.type
class Position:
    long: Decimal
    lat: Decimal


@strawberry.input
class PositionInput:
    long: Decimal
    lat: Decimal


@strawberry.type
class Area:
    bottom_corner: Position
    top_corner: Position


@strawberry.input
class AreaInput:
    bottom_corner: PositionInput
    top_corner: PositionInput


@strawberry.type
class Customer:
    id: int
    name: str


@strawberry.input
class CustomerInput:
    name: str


@strawberry.type
class Site:
    id: int
    label: str
    area: typing.Optional[Area]
    address: typing.Optional[list[str]]
    zip_code: typing.Optional[str]
    city: typing.Optional[str]
    owner: Customer


@strawberry.input
class SiteInput:
    label: str
    area: typing.Optional[AreaInput] = None
    address: typing.Optional[list[str]] = None
    zip_code: typing.Optional[str] = None
    city: typing.Optional[str] = None


@strawberry.type
class Building:
    id: int
    label: str
    position: typing.Optional[Position] = None
    site: Site
