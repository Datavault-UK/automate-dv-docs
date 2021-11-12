A Point-In-Time table is a query assistant structure, part of the Business Vault, meant to improve the performance of loading and creating the information marts.
Given a supplied list of dates/timestamps in an [as of dates table](../macros.md#as-of-date-table-structures), the PIT table
will identify the relevant records from each Satellite for that specific date/timestamp and record the Hash Key and the LDTS value
of that Satellite record. By identifying the "coordinates" of the relevant records at each point-in-time a priori,
the information marts queries can make use of equi joins which offer a significant boost in performance.    

The recommendation is to use the PIT table when referencing at least two Satellites and especially when the Satellites
have different rates of update. 

#### Structure

Our point-in-time structures will contain:

##### Source Model (source_model)
This is the name of the parent Hub that contains the primary key (src_pk) and to which the Satellites are connected to. 

##### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key. This will be the primary key used
by the parent Hub.

##### As-of Dates Table (as_of_dates_table) 
The as_of_dates_table describes the history needed to construct the PIT table as a list of dates. This is where you would 
supply the name of your as of date table.

##### Satellites (satellites)
This is a dictionary that contains the metadata for the Satellites in subject. It will have three levels of keys. 

The first level key is the name of the Satellite in uppercase.

The second level keys will be _pk_ and _ldts_.

The third level key will be _'PK'_ and _'LDTS'_. The expected value for the _'PK'_ key is the Hash Key column name of the Satellite (e.g. CUSTOMER_PK). 
The expected value for the _'LDTS'_ key is the Load Date/Timestamp column name of the Satellite (e.g. LOAD_DATE).

##### Load Date/Timestamp (src_ldts)
This is a string with the name of the Hub's Load Date/Timestamp column 

##### Stage Models (stage_tables)
This is a dictionary that contains the names of the Load Date/Timestamp columns for each stage table sourcing the Satellites.

The keys in the dictionary will be the stage table names (e.g. 'STG_CUSTOMER_DETAILS), whereas the values will be 
the name of the Load Date/Timestamp column for that stage table (e.g. 'LOAD_DATE')

!!! tip
    To see a full example of how the metadata needs to be defined for a PIT object, please check the PIT section on the [metadata](metadata.md#point-in-time-tables-pits) page.


### Setting up PIT models

Create a new dbt model as before. We'll call this one `pit_customer`. 

=== "pit_customer.sql"

    ``` jinja
    {{ dbtvault.pit(source_model=source_model, src_pk=src_pk,
                    as_of_dates_table=as_of_dates_table,
                    satellites=satellites,
                    stage_tables=stage_tables,
                    src_ldts=src_ldts) }}
    ```

To create a PIT model, we simply copy and paste the above template into a model named after the PIT we
are creating. dbtvault will generate a PIT using parameters provided in the next steps.

PIT tables should use the *pit_incremental* materialization, as they will be remade with every new As-of Dates table. 

We recommend setting the `pit_incremental` materialization on all of your pits using the `dbt_project.yml` file:

=== "dbt_project.yml"

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

Let's look at the metadata we need to provide to the [pit](../metadata.md#point-in-time-tables-pits) macro.

#### Source table

Here we will define the metadata for the source_model. We will use the HUB_CUSTOMER that we built before.

=== "dbt_project.yml"

    ```yaml
    pit_customer:
      vars:
        source_model: HUB_CUSTOMER
        ...
    ```

#### Primary Key

Next we need add the Hub's Primary Key column 

=== "dbt_project.yml"

    ```yaml
    pit_customer:
      vars:
        source_model: HUB_CUSTOMER
        src_pk: CUSTOMER_PK
        ...
    ```

#### As-of Date Table 

Next, we provide the PIT's column name for the as-of dates.

=== "dbt_project.yml"

    ```yaml
    pit_customer:
      vars:
        source_model: HUB_CUSTOMER
        src_pk:CUSTOMER_PK
        as_of_dates_table: AS_OF_DATE
        ...
    ```

#### Satellites metadata

Here we add the Satellite related details (i.e. the Primary/Hash Key and the Load Date/Timestamp column names)

=== "dbt_project.yml"

    ```yaml
    pit_customer:
      vars:
        source_model: HUB_CUSTOMER
        src_pk:CUSTOMER_PK
        as_of_dates_table: AS_OF_DATE
        satellites: 
            SAT_CUSTOMER_DETAILS
              pk
                'PK': 'CUSTOMER_PK'
              ldts
                'LDTS': 'LOAD_DATE'
            SAT_CUSTOMER_LOGIN:
              pk:
                'PK': 'CUSTOMER_PK'
              ldts:
                'LDTS': 'LOAD_DATE'
        ...
    ```

#### Stage metadata 

Here we add Satellites' stage table names and their Load Date/Timestamp column names

=== "dbt_project.yml"

    ```yaml
    pit_customer:
      vars:
        source_model: HUB_CUSTOMER
        src_pk:CUSTOMER_PK
        as_of_dates_table: AS_OF_DATE
        satellites: 
            SAT_CUSTOMER_DETAILS
              pk
                'PK': 'CUSTOMER_PK'
              ldts
                'LDTS': 'LOAD_DATE'
            SAT_CUSTOMER_LOGIN:
              pk:
                'PK': 'CUSTOMER_PK'
              ldts:
                'LDTS': 'LOAD_DATE'
        stage_tables: 
            'STG_CUSTOMER_DETAILS': 'LOAD_DATE'
            'STG_CUSTOMER_LOGIN': 'LOAD_DATE'      
        ...
    ```

#### Load Date/Timestamp

Finally, we add the Load Date/Timestamp column name of the parent Hub 

=== "dbt_project.yml"

    ```yaml hl_lines="6 7 8 9 10 11 12"
        pit_customer:
          vars:
            source_model: HUB_CUSTOMER
            src_pk: CUSTOMER_PK
            as_of_date_table: AS_OF_DATE
            satellites: 
                SAT_CUSTOMER_DETAILS
                  pk
                    'PK': 'CUSTOMER_PK'
                  ldts
                    'LDTS': 'LOAD_DATE'
                SAT_CUSTOMER_LOGIN:
                  pk:
                    'PK': 'CUSTOMER_PK'
                  ldts:
                    'LDTS': 'LOAD_DATE'
            stage_tables:
                'STG_CUSTOMER_DETAILS': 'LOAD_DATE'
                'STG_CUSTOMER_LOGIN': 'LOAD_DATE'
            src_ldts: 'LOAD_DATE'        
    ```

The dbt_project.yml above only defines one PIT. To add others you would follow the same method, by adding another entry under the 
_models > my_dbtvault_project > pit_ section inside `dbt_project.yml` (see [above](tut_point_in_time.md#setting-up-pit-models)). 

### Running dbt

With our model complete and our YAML written, we can run dbt to create our `pit_customer` table.

=== "< dbt v0.20.x"
    `dbt run -m +pit_customer`

=== "> dbt v0.21.0"
    `dbt run --select +pit_customer`

And our PIT table would look like this:

| CUSTOMER_PK  | AS_OF_DATE | SAT_CUSTOMER_DETAILS_PK | SAT_CUSTOMER_DETAILS_LDTS | SAT_CUSTOMER_LOGIN_PK  | SAT_CUSTOMER_LOGIN_LDTS |
| ------------ | ---------- | ----------------------- | ------------------------- | ---------------------- | ----------------------- |
| HY67OE...    | 2021-11-01 | HY67OE...               | 2020-06-05                | 000000...              | 1900-01-01              |
| RF57V3...    | 2021-11-01 | RF57V3...               | 2017-04-24                | RF57V3...              | 2021-04-01              |
| .            | .          | .                       | .                         | .                      | .                       |
| .            | .          | .                       | .                         | .                      | .                       |
| HY67OE...    | 2021-11-15 | HY67OE...               | 2021-11-09                | HY67OE...              | 2021-11-14              |
| RF57V3...    | 2021-11-15 | RF57V3...               | 2017-04-24                | RF57V3...              | 2021-04-01              |
| .            | .          | .                       | .                         | .                      | .                       |
| .            | .          | .                       | .                         | .                      | .                       |
| HY67OE...    | 2021-11-31 | HY67OE...               | 2021-11-09                | HY67OE...              | 2021-11-30              |
| RF57V3...    | 2021-11-31 | RF57V3...               | 2021-11-20                | RF57V3...              | 2021-04-01              |