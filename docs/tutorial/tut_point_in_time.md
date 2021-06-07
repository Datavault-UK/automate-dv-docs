A Point-In-Time table is one of two business-vault query-helper tables (the other being Bridge tables) designed for loading and creating the presentation marts.
The PIT table will the bolster the query performance of the raw vault when the satellites do not have the same cadence.
It will act as 'window in time' which references data valid at a specific point in time in history listed in an 
[as of dates table](../macros.md#as-of-date-table-structures). To create a PIT table, a minimum of two satellites will be required, though PIT tables are more 
beneficial when referencing a greater number of satellites. 

#### Structure

Our point-in-time structures will contain:

##### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key. This will be the primary key used
by the Hub.

##### as_of_dates_table 
The as_of_dates_table describes the history needed to construct the PIT table as a list of dates. This is where you would 
supply the name of your as of date table.

##### Satellites
This is a dictionary of the satellites that is used to define their metadata. Each satellite entry will be its name exactly and will contain
two nested dictionaries pk and ldts. which will define the satellite key and the date column used to compare to the as of table. 
These will contain a key pair described below.

The satellite_key is the hashed key in the satellite that directly corresponds to the Hub_PK. These should be the exact same.
The only difference being the key may not be defined as the primary_key in the satellite it could be defined as a foreign key
or a hashed key. It is described by a key pair, 'the suffix desired for this key (eg:PK, FK, HK)' : 'name of the key in the satellite'

The satellite_date_column. This is the column used to compare to the as of dates column when deciding what is the valid entry.
Typically, the Load_date is used, but the effective_from can also be used. You must keep in mind however when using effective from
although the entry may be the most valid for that date it may not have been a representation of the data vault on that day as the load date could be
further in the future. The key pair will be defined by 'the suffix for date type column used (eg: LDTS, EF)' : 'name of the date column you want to use'

##### source_model
This is the name of the Hub that contains the primary key (src_pk) and that the satellites are connected to. 


### Setting up PIT models

Create a new dbt model as before. We'll call this one `pit_customer`. 

`pit_customer.sql`
```jinja
{{ {{ dbtvault.pit({src_pk}, {as_of_dates_table}, {satellites}, 
    {source_model}) }} }}
```

To create a PIT model, we simply copy and paste the above template into a model named after the PIT we
are creating. dbtvault will generate a PIT using parameters provided in the next steps.

PITS should use the pit_incremental materialization, as the pit is remade with every new as of dates table. 

We recommend setting the `pit_incremental` materialization on all of your pits using the `dbt_project.yml` file:

`dbt_project.yml`
```yaml
models:
  my_dbtvault_project:
   pit:
    materialized: pit_incremental
    tags:
      - pit
    pit_customer:
      vars:
        ...
```

### Adding the metadata

Let's look at the metadata we need to provide to the [pit](../macros.md#pit) macro.

#### Source table
Here we will define the metadata for the source_model. We will use the HUB_CUSTOMER that we built before.

`dbt_project.yml`
```yaml
PIT_CUSTOMER:
    vars:
        source_model: HUB_CUSTOMER
```
#### Source columns

Next we need to choose which source columns we will use but also what satellites to incorporate in our `PIT_CUSTOMER` :

1. The primary key of the parent hub, which is a hashed natural key. 
The `CUSTOMER_PK` we created earlier in the [hub](tut_hubs.md) section will be used for `PIT_CUSTOMER`.

2. `AS_OF_DATE` column which represents the date the row is valid for. This is obtained by giving the source information of the [as of dates table](../macros.md#As-Of-Date-Table-Structures).

3. `satellite_key` is the `src_pk` taken from the satellite and aliased as the satellite name_ the type of key it is (eg: PK, HK, FK)
there is a column for each satellite included in the PIT.

4. `satellite_LDTS` is the column chosen from the satellite to denote the date column that is being used as to determine when the entry is
valid from and is aliased as satellite name suffixed with an identifier of the date column, usually load date but can also be the effective from (LDTS or EF). This will be paired 
with its respective `satellite_key` 
   
The dbt_project.yml below only defines one satellite but to add others you would follow the same method inside of satellites.
It can be seen where the SAT_ORDERS_LOGIN would begin.

`dbt_project.yml`
```yaml hl_lines="6 7 8 9 10 11 12"
    PIT_CUSTOMER:
      vars:
        source_model: HUB_CUSTOMER
        as_of_date_table: AS_OF_DATES
        src_pk: CUSTOMER_PK
        satellites: 
            - SAT_CUSTOMER_DETAILS
                -pk
                    'PK': 'CUSTOMER_PK'
                -ldts
                    'LDTS': 'LOAD_DATE'
            - SAT_ORDER_LOGIN
            ...
```

### Running dbt

`dbt run -m +pit_customer`

### Next steps

That is all for now. More table types will be coming in future! See our [roadmap](../roadmap.md) for more details.

If you want a more realistic real-world example, with real data to work with, take a look at our [worked example](../worked_example/we_worked_example.md).