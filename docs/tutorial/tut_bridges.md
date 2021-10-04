Bridge tables are query assistant tables that form part of the Business Vault. Similar to PIT tables, their purpose is
to improve performance of queries on the Raw Data Vault by reducing the number of required joins for such queries to 
simple equi-joins. 

A bridge table spans across a hub and one or more associated links. This means that it is essentially 
a specialised form of link table, containing hash keys from the hub and the links its spans. It does not contain 
information from satellites, however, it may contain computations and aggregations (according to grain) to increase 
query performance upstream when creating virtualised data marts. 

Bridge tables provide a timeline for valid sets of 
hub and link relationships for a given set of dates described in an [as of dates table](../macros.md#As-Of-Date-Table-Structures)

A basic bridge table model for a hub and two links:

![alt text](../assets/images/bridge_diagram.png "A basic bridge table model for a hub and two links")

### Structure

Our bridge structures will contain:

#### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key. This will be the primary 
key used by the hub.

#### AS_OF Table (as_of_dates_table) 
The as_of_dates_table describes the history needed to construct the bridge table as a list of dates. This is where you 
would supply the name of your as of date table.

#### Bridge Table Parameters (bridge_walk)
This is a dictionary of bridge table metadata subdivided into dictionaries for each link relationship. The metadata for 
each link relationship includes bridge table column aliases (bridge_xxxxx), link table name and foreign key column names 
(link_xxxxx), and the related effectivity satellite table details (eff_sat_xxxxx).

#### Hub Table Name (source_model)
This is the name of the hub that contains the primary key (src_pk) and that the links are connected to. 

#### Stage Load Date Timestamps (stage_tables_ldts)
List of stage table load date timestamp columns. These are used to find the waterlevel, i.e. the latest date that hasn't 
yet been impacted by the stage table.

#### Hub Load Date Timestamp (src_ldts)
Hub load date timestamp column. This is used to distinguish new key relationships when compared to the waterlevel.

### Creating Bridge models

Create a new dbt model as before. We'll call this one `bridge_customer_order`. 

=== "bridge_customer_order.sql"

    ``` jinja
    {{ dbtvault.bridge(source_model=source_model, src_pk=src_pk,
                            bridge_walk=bridge_walk,
                            as_of_dates_table=as_of_dates_table,
                            stage_tables=stage_tables,src_ldts=src_ldts) }}
    ```


To create a bridge model, we simply copy and paste the above template into a model named after the bridge table we
are creating. dbtvault will generate a bridge table using parameters provided in the following steps.

ADD METADATA SECTION

### Adding the metadata

Let's look at the metadata we need to provide to the [bridge](../macros.md#bridge) macro.

### Running dbt

In order to finalise the creation of the `bridge_customer_order` table we use the following dbt command:

`dbt run -m +bridge_customer_order`

The resulting table should look like this:

 | CUSTOMER_PK | AS_OF_DATE              | LINK_CUSTOMER_ORDER_PK | LINK_ORDER_PRODUCT_PK |
 | ----------- | ----------------------- | ---------------------- | --------------------- |
 | ED5984...   | 2018-06-01 00:00:00.000 | A77BA1...              | 8A2CQA...             |
 | .           | .                       | .                      | .                     |
 | .           | .                       | .                      | .                     |
 | M67Y0U...   | 2018-06-01 12:00:00.000 | 1FA79C...              | BH5674...             |
