import logging
import typing


from sqlalchemy.future import select
import strawberry
from strawberry.types import Info

from customers import model, mutations
from customers.lib import get_config
from customers.datalayer import DbService
from customers.queries import (
    get_buildings_query,
    get_customer_query,
    get_sites_query,
)
from customers.schema import (
    Building,
    Site,
    Customer,
    AreaInput,
    PositionInput,
    SiteInput,
    CustomerInput,
)


config = get_config()

log = logging.getLogger(__name__)


@strawberry.type
class Query:
    @strawberry.field
    async def buildings(
        self,
        info: Info,
        label: typing.Optional[str] = None,
        area: typing.Optional[AreaInput] = None,
        customer_name: typing.Optional[str] = None,
    ) -> typing.List[Building]:

        stmt = get_buildings_query(info, label, area, customer_name)

        async with DbService(config).session() as s:
            try:
                result = await s.execute(stmt)
                return result.scalars().all()
            except Exception as e:
                await s.rollback()

    @strawberry.field
    async def sites(
        self,
        info: Info,
        label: typing.Optional[str] = None,
        customer_name: typing.Optional[str] = None,
    ) -> typing.List[Site]:

        stmt = get_sites_query(info, label, customer_name)

        async with DbService(config).session() as s:
            try:
                result = await s.execute(stmt)
                return result.scalars().all()
            except Exception as e:
                await s.rollback()

    @strawberry.field
    async def customers(
        self,
        info: Info,
        name: typing.Optional[str] = None,
    ) -> typing.List[Customer]:
        stmt = get_customer_query(info, name)

        async with DbService(config).session() as s:
            try:
                result = await s.execute(stmt)
                return result.scalars().all()
            except Exception as e:
                await s.rollback()


@strawberry.type
class Mutation:
    @strawberry.mutation
    async def add_new_building_for_site(
        self, label: str, site_id: int, position: typing.Optional[PositionInput] = None
    ) -> Building:
        async with DbService(config).session() as s:
            building = await mutations.add_new_building_for_site(
                s, label, position, site_id
            )
            await s.commit()
            s.expunge(building)
            return building

    @strawberry.mutation
    async def add_new_building_for_new_site(
        self,
        label: str,
        site: SiteInput,
        customer_id: int,
        position: typing.Optional[PositionInput] = None,
    ) -> Building:
        async with DbService(config).session() as s:
            building = await mutations.add_new_building_for_new_site(
                s, label, position, site, customer_id
            )
            await s.commit()
            s.expunge(building)
            return building

    @strawberry.mutation
    async def add_new_building_for_new_customer(
        self,
        label: str,
        site: SiteInput,
        customer: CustomerInput,
        position: typing.Optional[PositionInput] = None,
    ) -> Building:
        async with DbService(config).session() as s:
            building = await mutations.add_new_building_for_new_customer(
                s, label, position, site, customer
            )
            await s.commit()
            s.expunge(building)
            return building

    @strawberry.mutation
    async def delete_building(self, id: int) -> None:
        async with DbService(config).session() as s:
            await mutations.delete_building(s, id)
            await s.commit()


schema = strawberry.Schema(query=Query, mutation=Mutation)
