Links are another fundamental component in a Data Vault, forming the core of the raw vault along with Hubs and Satellites. 

Links model an association or link, between two business keys.
A good example would be a list of all Orders and the Customers associated with those orders, for the whole business.

!!! note
    Due to the similarities in the load logic between Links and Hubs, most of this page will be familiar if you have already followed the
    [hubs](tut_hubs.md) page.
    
### Structure

#### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key. 
For Links, we take the natural keys (prior to hashing) represented by the foreign key columns below 
and create a hash on a concatenation of them. 

#### Foreign Keys (src_fk)
Foreign keys referencing the primary key for each Hub referenced in the Link (2 or more depending on the number of Hubs 
referenced) 

#### Load date (src_ldts)
A load date or load date timestamp. This identifies when the record was first loaded into the database.

#### Record Source (src_source)
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.

(i.e. `1` from the [staging section](tut_staging.md#adding-the-metadata), 
which is the code for `stg_customer`)

### Creating link models

Create a new dbt model as before. We'll call this one `link_customer_order`. 

=== "link_customer_order.sql"

    ```jinja
    {{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
    ```

To create a Link model, we simply copy and paste the above template into a model named after the Link we
are creating. dbtvault will generate a Link using metadata provided in the next steps.

#### Materialisation

The recommended materialisation for **Links** is `incremental`, as we load and add new records to the existing data set.

### Adding the metadata

Let's look at the metadata we need to provide to the [link macro](../macros.md#link).

We provide the column names which we would like to select from the staging area (`source_model`).

Using our [knowledge](#structure) of what columns we need in our `link_customer_order` table, we can identify columns in our
staging layer which map to them:

| Parameter      | Value                 | 
| -------------- | --------------------- | 
| source_model   | v_stg_orders          |
| src_pk         | CUSTOMER_ORDER_HK     |
| src_fk         | CUSTOMER_ID, ORDER_ID |
| src_ldts       | LOAD_DATETIME         | 
| src_source     | RECORD_SOURCE         |

When we provide the metadata above, our model should look like the following:

=== "link_customer_order.sql"

    ```jinja
    {{ config(materialized='incremental')         }}
    
    {%- set source_model = "v_stg_orders"        -%}
    {%- set src_pk = "CUSTOMER_ORDER_HK"         -%}
    {%- set src_fk = ["CUSTOMER_HK", "ORDER_HK"] -%}
    {%- set src_ldts = "LOAD_DATETIME"           -%}
    {%- set src_source = "RECORD_SOURCE"         -%}
    
    {{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                     src_source=src_source, source_model=source_model) }}
    ```

!!! Note
    See our [metadata reference](../metadata.md#links) for more detail on how to provide metadata to Links.

### Running dbt

With our metadata provided and our model complete, we can run dbt to create our `link_customer_order` Link, as follows:

=== "< dbt v0.20.x"
    `dbt run -m +link_customer_order`

=== "> dbt v0.21.0"
    `dbt run --select +link_customer_order`

And the resulting Link table will look like this:

| CUSTOMER_ORDER_HK  | CUSTOMER_HK  | ORDER_HK     | LOAD_DATETIME            | SOURCE |
| ------------------ | ------------ | ------------ | ------------------------ | ------ |
| 72A160...          | B8C37E...    | D89F3A...    | 1993-01-01 00:00:00.000  | 1      |
| .                  | .            | .            | .                        | 1      |
| .                  | .            | .            | .                        | 1      |
| 1CE6A9...          | FED333...    | D78382...    | 1993-01-01 00:00:00.000  | 1      |

### Loading links from multiple sources

In some cases, we may need to load Links from multiple sources, instead of a single source as we have seen so far.
This may be because we have multiple source staging tables, each of which contains a natural key for the Link. 
This would require multiple feeds into one table: dbt prefers one feed, 
so we perform a union operation on the separate sources together and load them as one. 

The data can and should be combined because these records have a truly identical key (same business meaning).
The `link` macro will perform a union operation to combine the tables using that key, and create a link containing
a complete record set.

The metadata needed to create a multi-source Link is identical to a single-source Link, we just provide a 
list of sources (usually multiple [staging areas](tut_staging.md)) rather than a single source, and the [link](../macros.md#link) macro 
will handle the rest:

!!! note
    If your primary key and natural key columns have different names across the different
    tables, they will need to be aliased to the same name in the respective staging layers 
    via a `derived column` configuration, using the [stage](../macros.md#stage) macro in the staging layer.



```jinja hl_lines="3 4 5"
{{ config(materialized='incremental') }}

{%- set source_model = ["v_stg_orders_web",   
                        "v_stg_orders_crm",   
                        "v_stg_orders_sap"]   -%}

{%- set src_pk = "CUSTOMER_ORDER_HK"          -%}
{%- set src_fk = ["CUSTOMER_HK", "ORDER_HK"]  -%}
{%- set src_ldts = "LOAD_DATETIME"            -%}
{%- set src_source = "RECORD_SOURCE"          -%}

{{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                 src_source=src_source, source_model=source_model) }}
```

See the [Link metadata reference](../metadata.md#links) for more examples.