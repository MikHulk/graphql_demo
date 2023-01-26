import logging
from sqlalchemy import func
from sqlalchemy.future import select
from sqlalchemy.orm import joinedload
from customers import model


log = logging.getLogger(__name__)


async def add_new_building_for_site(session, label, position, site_id):
    stmt = select(model.Site).filter_by(id=site_id).options(joinedload(model.Site.owner))
    site = (await session.execute(stmt)).one()[0]
    if not site:
        raise RuntimeError("site does not exists.")
    log.debug(f"New building {label} for {site.owner}")
    building = model.Building(
        label=label,
        position=model.Position(position.long, position.lat) if position else None,
        site=site,
    )
    session.add(building)
    return building


async def add_new_customer(session, name):
    log.debug(f"New customer {name}")
    customer = model.Customer(name=name)
    session.add(customer)
    return customer


async def add_new_site_for_customer(
    session, label, area, address, zip_code, city, customer_id
):
    customer = await session.get(model.Customer, customer_id)
    if not customer:
        raise RuntimeError("customer does not exists.")

    log.debug(f"New site {label} for {customer}")
    site = model.Site(
        label=label,
        owner=customer,
        area=model.Area(
            bottom_corner=model.Position(
                area.bottom_corner.long, are.bottom_corner.lat
            ),
            top_corner=model.Position(area.top_corner.long, are.top_corner.lat),
        )
        if area
        else None,
    )
    session.add(site)
    return site


async def add_new_building_for_new_site(session, label, position, site, customer_id):
    site = await add_new_site_for_customer(
        session,
        site.label,
        site.area,
        site.address,
        site.zip_code,
        site.city,
        customer_id,
    )
    log.debug(f"New building {label} for {site}")
    building = model.Building(
        label=label,
        position=model.Position(position.long, position.lat) if position else None,
        site=site,
    )
    session.add(building)
    return building


async def add_new_building_for_new_customer(session, label, position, site, customer):
    customer = await add_new_customer(session, customer.name)
    await session.flush()
    site = await add_new_site_for_customer(
        session,
        site.label,
        site.area,
        site.address,
        site.zip_code,
        site.city,
        customer.id,
    )
    log.debug(f"New building {label} for {site}")
    building = model.Building(
        label=label,
        position=model.Position(position.long, position.lat) if position else None,
        site=site,
    )
    session.add(building)
    return building


async def delete_building(session, id):
    building = await session.get(model.Building, id)
    if not building:
        raise RuntimeError("building does not exists.")
    site_id = building.site_id
    log.debug(f"delete {building}")
    await session.delete(building)
    await session.flush()
    count_site_stmt = select(func.count(model.Building.id)).filter(
        model.Building.site_id == site_id
    )
    count_site, *_ = (await session.execute(count_site_stmt)).one()
    if count_site == 0:
        await delete_site(session, site_id)


async def delete_site(session, id):
    site = await session.get(model.Site, id)
    if not site:
        raise RuntimeError("site does not exists.")
    customer_id = site.customer_id
    log.debug(f"delete {site}")
    count_customer_stmt = select(func.count(model.Site.id)).filter(
        model.Site.customer_id == customer_id
    )
    await session.delete(site)
    await session.flush()
    if (await session.execute(count_customer_stmt)).one()[0] == 0:
        await delete_customer(session, customer_id)


async def delete_customer(session, id):
    customer = await session.get(model.Customer, id)
    if not customer:
        raise RuntimeError("customer does not exists.")
    log.debug(f"delete {customer}")
    await session.delete(customer)
    await session.flush()
