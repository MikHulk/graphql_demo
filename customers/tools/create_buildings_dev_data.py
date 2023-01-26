from decimal import Decimal
from getpass import getpass
from random import randint, random, choice
import os
import sys

from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from customers import model


if __name__ == "__main__":
    db_password = getpass("db password:")

    if not (db_url := os.environ.get("POSTGRES_URL", False)):
        print("Don't know where db is. Fill POSTGRES_URL.", file=sys.stderr)
        sys.exit(1)

    print(f"connect to {db_url}")
    eng = create_engine(
        db_url, connect_args={"password": db_password}, poolclass=StaticPool
    )
    with Session(eng) as s:
        for customer in s.query(model.Customer):
            print(customer)
            for i in range(randint(1, 4)):
                x_pos = Decimal(str(round(random() * 177 * choice((1, -1)), 5)))
                y_pos = Decimal(str(round(random() * 65 * choice((1, -1)), 5)))
                site = model.Site(
                    label=f"{customer.name}_site_{i + 1}",
                    area=model.Area(
                        model.Position(x_pos, y_pos),
                        model.Position(
                            x_pos + Decimal("0.0002"), y_pos + Decimal("0.0002")
                        ),
                    ),
                )
                customer.sites.append(site)
                s.add(site)
                print(site, site.area)
                for j in range(randint(1, 4)):
                    x_range = Decimal("0.0002")
                    y_range = Decimal("0.0002")
                    building = model.Building(
                        label=f"{site.label}_bat_{j + 1}",
                        position=model.Position(
                            x_pos + Decimal(str(round(float(x_range) * random(), 8))),
                            y_pos + Decimal(str(round(float(y_range) * random(), 8))),
                        ),
                    )
                    site.buildings.append(building)
                    s.add(building)
                    print(building, building.position)
        s.commit()
