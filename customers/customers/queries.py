import logging
import typing

from sqlalchemy import and_
from sqlalchemy.orm import joinedload
from sqlalchemy.future import select
from strawberry.types import Info

from customers import model
from customers.schema import Building, AreaInput


log = logging.getLogger(__name__)


def get_buildings_query(
    info: Info,
    label: typing.Optional[str] = None,
    area: typing.Optional[AreaInput] = None,
    customer_name: typing.Optional[str] = None,
):

    stmt = select(model.Building).order_by(model.Building.id)

    if "site" in (field.name for field in info.selected_fields[0].selections):
        log.debug("join site")
        load_site_stmt = joinedload(model.Building.site)
        site_fields = (
            field
            for field in info.selected_fields[0].selections
            if field.name == "site"
        )
        for site_field in site_fields:
            if "owner" in (field.name for field in site_field.selections):
                log.debug("join owner")
                load_site_stmt = load_site_stmt.subqueryload(model.Site.owner)
                break
        stmt = stmt.options(load_site_stmt)

    if area:
        stmt = stmt.filter(
            and_(
                model.Building.lat > area.bottom_corner.lat,
                model.Building.long > area.bottom_corner.long,
                model.Building.lat < area.top_corner.lat,
                model.Building.long < area.top_corner.long,
            )
        )

    if label:
        stmt = stmt.filter(model.Building.label.ilike(label))

    if customer_name:
        stmt = (
            stmt.join(model.Building.site)
            .join(model.Site.owner)
            .filter(model.Customer.name.ilike(customer_name))
        )
    return stmt


def get_sites_query(
    info: Info,
    label: typing.Optional[str] = None,
    customer_name: typing.Optional[str] = None,
):

    stmt = select(model.Site).order_by(model.Site.id)

    if "owner" in (field.name for field in info.selected_fields[0].selections):
        log.debug("join owner")
        load_site_stmt = joinedload(model.Site.owner)
        stmt = stmt.options(load_site_stmt)

    if label:
        stmt = stmt.filter(model.Site.label.ilike(label))

    if customer_name:
        stmt = stmt.join(model.Site.owner).filter(
            model.Customer.name.ilike(customer_name)
        )
    return stmt


def get_customer_query(info, name):
    stmt = select(model.Customer).order_by(model.Customer.id)
    if name:
        stmt = stmt.filter(model.Customer.name.ilike(name))
    return stmt
