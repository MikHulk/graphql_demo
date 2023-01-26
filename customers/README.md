# Customers GraphQL backend

## requirements

In order to run this app you need a working postgres server with a login "postgres" database (his is the default).

All command given here will must be done from the folder where this README is located.

You can install python requirements with pip:

```
pip install -r requirements.txt
```


## build database

Database can be build playing migration scripts in `database/migrations`. Scripts need a valid postgres url. An environment variable is used for this purpose. The password is not mandatory in the URL because it will be asked during the migration process:

```
customers % POSTGRES_URL=postgresql+psycopg2://postgres@localhost:5432/customers_2 PYTHONPATH=.:.. python database/migrations/0001_create_db.py
password: 
connect to postgresql+psycopg2://postgres@localhost:5432/customers_2
db was created
customers % POSTGRES_URL=postgresql+psycopg2://postgres@localhost:5432/customers_2 PYTHONPATH=.:.. python database/migrations/0002_create_tables.py 
password: 
connect to postgresql+psycopg2://postgres@localhost:5432/customers_2
create tables
```

The app need the `common` package from the project's root. That's the reason why you need to specify not only the working dir but the project's root in your `PYTHONPATH`.

## Populate the development database

The script `tools/create_buildings_dev_data` create for a pre-existent list of customers in the `customers_table` a list of site and related buildings.

To use this facility, **first you need to fill the `customers` table with some customers** and then run the script:

```
% POSTGRES_URL=postgresql+psycopg2://postgres@localhost:5432/customers_2 PYTHONPATH=.:.. python tools/create_buildings_dev_data.py      
db password:
connect to postgresql+psycopg2://postgres@localhost:5432/customers_2
Customer(1):foo
Site(None):foo_site_1 Area(bottom_corner=Position(longitude=Decimal('123.05159'), latitude=Decimal('45.45597')), top_corner=Position(longitude=Decimal('123.05179'), latitude=Decimal('45.45617')))
Building(None):foo_site_1_bat_1 Position(longitude=Decimal('123.05175484'), latitude=Decimal('45.45616688'))
Customer(2):bar
Site(None):bar_site_1 Area(bottom_corner=Position(longitude=Decimal('26.22202'), latitude=Decimal('39.93467')), top_corner=Position(longitude=Decimal('26.22222'), latitude=Decimal('39.93487')))
Building(None):bar_site_1_bat_1 Position(longitude=Decimal('26.22221823'), latitude=Decimal('39.93470615'))
Building(None):bar_site_1_bat_2 Position(longitude=Decimal('26.22220281'), latitude=Decimal('39.93474222'))
Site(None):bar_site_2 Area(bottom_corner=Position(longitude=Decimal('-4.19683'), latitude=Decimal('-11.55097')), top_corner=Position(longitude=Decimal('-4.19663'), latitude=Decimal('-11.55077')))
Building(None):bar_site_2_bat_1 Position(longitude=Decimal('-4.19679585'), latitude=Decimal('-11.55084021'))
Site(None):bar_site_3 Area(bottom_corner=Position(longitude=Decimal('-93.93912'), latitude=Decimal('-15.72468')), top_corner=Position(longitude=Decimal('-93.93892'), latitude=Decimal('-15.72448')))
Building(None):bar_site_3_bat_1 Position(longitude=Decimal('-93.93906829'), latitude=Decimal('-15.724651'))
Building(None):bar_site_3_bat_2 Position(longitude=Decimal('-93.93897379'), latitude=Decimal('-15.72449118'))
Building(None):bar_site_3_bat_3 Position(longitude=Decimal('-93.93898609'), latitude=Decimal('-15.72460503'))
Building(None):bar_site_3_bat_4 Position(longitude=Decimal('-93.93894178'), latitude=Decimal('-15.72466397'))
```

In this example, the script created one site for customer "foo" and 3 sites for customer "bar".

## run the server

After the database build you can run the graphql server:

```
PYTHONPATH=.:.. CUSTOMERS_APP_CONFIG=./customers/config.json strawberry server customers.api
Running strawberry on http://0.0.0.0:8000/graphql 🍓
```

A path toward a configuration json file must be given. An example of this file is given in `./config.json`. It should be convenient for dev purpose, once the url of the database has been adapted.

The graphQL framework is [Strawberry](https://strawberry.rocks/).

Once the server up, you can reach it from the url given at the startup.


## Tests

Tests are run with pytest, on a specific database, which is specifically created during the tests and destroyed after. So you need to provide a valid postgres url to a database which doesn't exist at the time the tests began. **Password in url is mandatory this time**.

```
(beebryte) mickaelviey@studio customers % POSTGRES_TEST_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/customers_test PYTHONPATH=.:.. pytest                 
============================================= test session starts ==============================================
platform darwin -- Python 3.10.3, pytest-7.2.0, pluggy-1.0.0
rootdir: /Users/mickaelviey/Dev/beebryte/customers
plugins: anyio-3.6.2
collected 9 items                                                                                              

tests/test_customers.py ...                                                                              [ 33%]
tests/test_geo.py ....                                                                                   [ 77%]
tests/test_sites_area.py ..                                                                              [100%]

============================================== 9 passed in 0.56s ===============================================
(beebryte) mickaelviey@studio customers % 
```
