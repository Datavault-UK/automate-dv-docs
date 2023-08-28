# Macros

## Global usage notes

### source_model syntax

dbt itself supports references to data via
the `ref()` [function](https://docs.getdbt.com/reference/dbt-jinja-functions/ref/) for models, and the `source()`
[function](https://docs.getdbt.com/reference/dbt-jinja-functions/source)
for [dbt sources](https://docs.getdbt.com/docs/building-a-dbt-project/using-sources/).

AutomateDV provides the means for specifying sources for Data Vault structures with a `source_model` argument.

This behaves differently for the [stage](#stage) macro, which supports either style, shown below:

#### ref style

```yaml
stg_customer:
  source_model: 'raw_customer'
```

#### source style

=== "stage configuration"

    ```yaml
    stg_customer:
      source_model:
        tpch_sample: 'LINEITEM'
    ```

=== "source definition (schema.yml)"

    ```yaml
    version: 2
    
    sources:
      - name: tpch_sample
        database: SNOWFLAKE_SAMPLE_DATA
        schema: TPCH_SF10
        tables:
          - name: LINEITEM
          - name: CUSTOMER
          - name: ORDERS
          - name: PARTSUPP
          - name: SUPPLIER
          - name: PART
          - name: NATION
          - name: REGION
    ```

The mapping provided for the source style is in the form `source_name: table_name` which mimics the syntax for
the `source()` macro.

For all other structures (Hub, Link, Satellite, etc.) the `source_model` argument must be a string to denote a single
staging source, or a list of strings to denote multiple staging sources, which must be names of models (minus
the `.sql`).

## Global variables

AutomateDV provides
user-overridable [global variables](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-variables#defining-variables-in-dbt_projectyml)
which allow you to configure different aspects of AutomateDV. These variables will be expanded in future versions of
AutomateDV.

### Hashing configuration 

```yaml
vars:
  hash: MD5
  concat_string: '||'
  null_placeholder_string: '^^'
  hash_content_casing: 'UPPER'
```

#### hash

Configure the type of hashing.

This can be one of:

- MD5
- SHA

[Read more](../best_practises/hashing.md#choosing-a-hashing-algorithm)

#### concat_string

Configure the string value to use for concatenating strings together when hashing. By default, this is two pipe
characters: '`||`'

[Read more](../best_practises/hashing.md#multi-column-hashing)

#### null_placeholder_string

Configure the string value to use for replacing `NULL` values when hashing. By default, this is two caret
characters: '`^^`'

#### hash_content_casing

This variable configures whether hashed columns are normalised with `UPPER()` when calculating the hash value.

This can be one of:

- UPPER
- DISABLED

=== "UPPER Example"
    === "YAML config input"
        ```yaml
        source_model: raw_source
        hashed_columns:
          CUSTOMER_HK: CUSTOMER_ID
        ```
    === "SQL Output"
        ```sql
        CAST((MD5_BINARY(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''))) AS BINARY(16)) AS CUSTOMER_HK
        ```
=== "DISABLED Example"
    === "YAML config input"
        ```yaml
        source_model: raw_source
        hashed_columns:
          CUSTOMER_HK: CUSTOMER_ID
        ```
    === "SQL Output"
        ```sql
        CAST((MD5_BINARY(NULLIF(TRIM(CAST(CUSTOMER_ID AS VARCHAR)), ''))) AS BINARY(16)) AS CUSTOMER_HK
        ```

!!! info
    We've added this config to give you more options when hashing. If there is logical difference between uppercase
    and lowercase values in your data, set this to `DISABLED` otherwise, the standard approach is to use `UPPER` 

### Ghost Record configuration

```yaml
vars:
  enable_ghost_records: false
  system_record_value: 'AUTOMATE_DV_SYSTEM'
```

#### How Ghost Records work

In the Data Vault standards, ghost records are intended to provide equi-join capabilities for PIT tables when queries on a satellite
at a point in time would otherwise return no records. Instead of having to handle NULLs and incur performance penalties for joins which
do not return records, the ghost record is a single record inserted into a Satellite upon its first creation which can be used instead.

In AutomateDV this is implemented as an optional CTE which only gets created in the above circumstances and when the `enable_ghost_records` global variable is set to `true`.

A Ghost Record does not inherently mean anything (it is for performance only), and so the value of each column is set to `NULL` or a sensible meaningless value. 

The below tables describe what a ghost record will look like:

=== "Parameters"

    | Parameter                        | Value                            |
    |----------------------------------|----------------------------------|
    | src_pk Binary MD5/SHA256)        | 0000..(x32) / 0000..(x64)        |
    | src_hashdiff (Binary MD5/SHA256) | 0000..(x32) / 0000..(x64)        |
    | src_payload (Any)                | NULL                             |
    | src_extra_columns (Any)          | NULL                             |
    | src_eff (Date/Timestamp)         | 1900-01-01 / 1900-01-01 00:00:00 |
    | src_ldts (Date/Timestamp)        | 1900-01-01 / 1900-01-01 00:00:00 |
    | src_source (String)              | AUTOMATE_DV_SYSTEM (default)     |

=== "Data"

    | CUSTOMER_HK | HASHDIFF  | CUSTOMER_NAME | CUSTOMER_DOB | CUSTOMER_PHONE | EFFECTIVE_FROM      | LOAD_DATETIME       | RECORD_SOURCE      |
    |-------------|-----------|---------------|--------------|----------------|---------------------|---------------------|--------------------|
    | 000000...   | 000000... | _NULL_        | _NULL_       | _NULL_         | 1900-01-01 00:00:00 | 1900-01-01 00:00:00 | AUTOMATE_DV_SYSTEM |

!!! note "Ghost record source code"
    Check out how this works [under-the-hood](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/supporting/ghost_records/create_ghost_record.sql)

#### enable_ghost_records

Enable the use of ghost records in your project. This can either be true or false, `true` will enable the configuration and `false` will disable it.

This will insert a ghost record to a satellite table whether it is a new table or pre-existing. 

Before adding the ghost record, the satellite macro will check there is not already one loaded.

!!! note
    If this is enabled on an existing project, the ghost-records will be inserted into the satellite on the first dbt run after enabling **_only_**

#### system_record_value

This will set the record source system for the ghost record. The default is `AUTOMATE_DV_SYSTEM` and can be changed to any string.

!!! note
    If this is changed on an existing project, the source system of already loaded ghost records will not be changed unless you `--full-refresh`.

### NULL Key configurations

```yaml
vars:
  null_key_required: '-1'
  null_key_optional: '-2'
```

#### null_key_required

Configure the string value to use for replacing `NULL` values found in keys where a value is required, e.g. prior to
hashing.
By default, this is '-1'.

#### null_key_optional

Configure the string value to use for replacing `NULL` values found in optional keys. By default, this is '-2'.

[Read more](../best_practises/null_handling.md)

### Other global variables

```yaml
vars:
  escape_char_left: '"'
  escape_char_right: '"'
  max_datetime: '9999-12-31 23:59:59.999999'
```

#### max_datetime

Configure the value for the maximum datetime.

This value will be used for showing that a record's effectivity is 'open' or 'current' in certain circumstances.

The default is variations on `9999-12-31 23:59:59.999999` where there is more or less nanosecond precision (9's after the .) depending on platform.

#### escape_char_left/escape_char_right

Configure the characters to use to delimit SQL column names when [escaping](../best_practises/escaping.md). 
Column names are delimited when using the [escaping](../best_practises/escaping.md) feature of AutomateDV, 
and by default both the delimiting characters are double quotes following the SQL:1999 standard.

Here are some examples for different platforms:

=== "Google BigQuery"

    ```yaml
    ...
    vars:
      escape_char_left: '`'
      escape_char_right: '`'
    ```

=== "MS SQL Server"

    ```yaml
    ...
    vars:
      escape_char_left: '['
      escape_char_right: ']'
    ```

=== "MS SQL Server with QUOTED_IDENTIFIER ON"

    ```yaml
    ...
    vars:
      escape_char_left: '"'
      escape_char_right: '"'
    ```

## Platform Support

The table below indicates which macros and templates are officially available for each platform.

AutomateDV is primarily developed on Snowflake, and we release support for other platforms as and when possible.
Most of the time this will be at the same time as the Snowflake release unless it is snowflake-only functionality
with no equivalent in another platform.

Thanks for your patience and continued support!

| Macro/Template | Snowflake                                     | Google BigQuery                               | MS SQL Server                                 | Databricks                                    | Postgres                                      | Redshift**                                        |
|----------------|-----------------------------------------------|-----------------------------------------------|-----------------------------------------------|-----------------------------------------------|-----------------------------------------------|---------------------------------------------------|
| hash           | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| stage          | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| hub            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| link           | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| sat            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| t_link         | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| eff_sat        | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| ma_sat         | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| xts            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| pit            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |
| bridge         | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } |

!!! note "**"
    These platforms are either planned or actively being worked on by the community and/or internal AutomateDV team.
    See the issues below for more information:

    - [Redshift](https://github.com/Datavault-UK/automate-dv/issues/86)

## Table templates

###### (macros/tables)

These macros are the core of the package and can be called in your models to build the different types of tables needed
for your Data Vault 2.0 Data Warehouse.

### hub

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/snowflake/hub.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/bigquery/hub.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/sqlserver/hub.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/databricks/hub.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/postgres/hub.sql)

Generates SQL to build a Hub table using the provided parameters.

#### Usage

``` jinja

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_extra_columns=src_extra_columns,
                   src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter         | Description                                 | Type                | Required?                                         |
|-------------------|---------------------------------------------|---------------------|---------------------------------------------------|
| src_pk            | Source primary key column                   | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |
| src_nk            | Source natural key column                   | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |
| src_extra_columns | Select arbitrary columns from the source    | List[String]/String | :fontawesome-solid-circle-minus:{ .not-required } |
| src_ldts          | Source load date timestamp column           | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_source        | Name of the column containing the source ID | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |
| source_model      | Staging model name                          | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |

??? video "Video Tutorial"
    <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/DDc0hS_XCpo" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

!!! tip
    [Read the tutorial](../tutorial/tut_hubs.md) for more details

#### Example Metadata

[See examples](../metadata.md#hubs)

#### Example Output

=== "Snowflake"

    === "Single-Source (Base Load)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/hubs/hub_customer.sql"
        ```
    
    === "Single-Source (Incremental Loads)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/hubs/hub_customer_incremental.sql"
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/hubs/hub_orders_multi_source.sql"
        ```
    
    === "Multi-Source (Incremental Loads)"
 
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/hubs/hub_orders_multi_source_incremental.sql"
        ```

=== "Google BigQuery"

    === "Single-Source (Base Load)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/hubs/hub_customer.sql"
        ```
    
    === "Single-Source (Incremental Loads)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/hubs/hub_customer_incremental.sql"
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/hubs/hub_orders_multi_source.sql"
        ```
    
    === "Multi-Source (Incremental Loads)"
 
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/hubs/hub_orders_multi_source_incremental.sql"
        ```

=== "MS SQL Server"

    === "Single-Source (Base Load)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/hubs/hub_customer.sql"
        ```
    
    === "Single-Source (Incremental Loads)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/hubs/hub_customer_incremental.sql"
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/hubs/hub_orders_multi_source.sql"
        ```
    
    === "Multi-Source (Incremental Loads)"
 
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/hubs/hub_orders_multi_source_incremental.sql"
        ```

=== "Postgres"

    === "Single-Source (Base Load)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/hubs/hub_customer.sql"
        ```
    
    === "Single-Source (Incremental Loads)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/hubs/hub_customer_incremental.sql"
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/hubs/hub_orders_multi_source.sql"
        ```
    
    === "Multi-Source (Incremental Loads)"
 
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/hubs/hub_orders_multi_source_incremental.sql"
        ```

=== "Databricks"

    === "Single-Source (Base Load)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/hubs/hub_customer.sql"
        ```
    
    === "Single-Source (Incremental Loads)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/hubs/hub_customer_incremental.sql"
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/hubs/hub_orders_multi_source.sql"
        ```
    
    === "Multi-Source (Incremental Loads)"
 
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/hubs/hub_orders_multi_source_incremental.sql"
        ```
___

### link

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/snowflake/link.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/bigquery/link.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/sqlserver/link.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/databricks/link.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/postgres/link.sql)

Generates SQL to build a Link table using the provided parameters.

#### Usage

``` jinja
{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_extra_columns=src_extra_columns,
                    src_source=src_source, source_model=source_model) }}
```                                             

#### Parameters

| Parameter         | Description                                 | Type                | Required?                                         |
|-------------------|---------------------------------------------|---------------------|---------------------------------------------------|
| src_pk            | Source primary key column                   | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |
| src_fk            | Source foreign key column(s)                | List[String]        | :fontawesome-solid-circle-check:{ .required }     |
| src_extra_columns | Select arbitrary columns from the source    | List[String]/String | :fontawesome-solid-circle-minus:{ .not-required } |
| src_ldts          | Source load date timestamp column           | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_source        | Name of the column containing the source ID | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |
| source_model      | Staging model name                          | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |

??? video "Video Tutorial"
    <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/ztvvaYOcTvc" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

!!! tip
    [Read the tutorial](../tutorial/tut_links.md) for more details

#### Example Metadata

[See examples](../metadata.md#links)

#### Example Output

=== "Snowflake"

    === "Single-Source (Base Load)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/links/link_customer_order.sql"
        ```
    
    === "Single-Source (Incremental Loads)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/links/link_customer_order_incremental.sql"
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/links/link_customer_order_multi_source.sql"
        ```
    
    === "Multi-Source (Incremental Loads)"
 
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/links/link_customer_order_multi_source_incremental.sql"
        ```

=== "Google BigQuery"

    === "Single-Source (Base Load)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/links/link_customer_order.sql"
        ```
    
    === "Single-Source (Incremental Loads)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/links/link_customer_order_incremental.sql"
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/links/link_customer_order_multi_source.sql"
        ```
    
    === "Multi-Source (Incremental Loads)"
 
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/links/link_customer_order_multi_source_incremental.sql"
        ```

=== "MS SQL Server"

    === "Single-Source (Base Load)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/links/link_customer_order.sql"
        ```
    
    === "Single-Source (Incremental Loads)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/links/link_customer_order_incremental.sql"
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/links/link_customer_order_multi_source.sql"
        ```
    
    === "Multi-Source (Incremental Loads)"
 
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/links/link_customer_order_multi_source_incremental.sql"
        ```

=== "Postgres"

    === "Single-Source (Base Load)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/links/link_customer_order.sql"
        ```
    
    === "Single-Source (Incremental Loads)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/links/link_customer_order_incremental.sql"
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/links/link_customer_order_multi_source.sql"
        ```
    
    === "Multi-Source (Incremental Loads)"
 
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/links/link_customer_order_multi_source_incremental.sql"
        ```

=== "Databricks"

    === "Single-Source (Base Load)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/links/link_customer_order.sql"
        ```
    
    === "Single-Source (Incremental Loads)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/links/link_customer_order_incremental.sql"
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/links/link_customer_order_multi_source.sql"
        ```
    
    === "Multi-Source (Incremental Loads)"
 
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/links/link_customer_order_multi_source_incremental.sql"
        ```
___

### t_link

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/snowflake/t_link.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/bigquery/t_link.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/sqlserver/t_link.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/databricks/t_link.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/postgres/t_link.sql)

Generates SQL to build a Transactional Link table using the provided parameters.

#### Usage

``` jinja
{{ automate_dv.t_link(src_pk=src_pk, src_fk=src_fk, src_payload=src_payload,
                   src_extra_columns=src_extra_columns,
                   src_eff=src_eff, src_ldts=src_ldts, 
                   src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter         | Description                                 | Type                | Required?                                         |
|-------------------|---------------------------------------------|---------------------|---------------------------------------------------|
| src_pk            | Source primary key column                   | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |
| src_fk            | Source foreign key column(s)                | List[String]        | :fontawesome-solid-circle-check:{ .required }     |
| src_payload       | Source payload column(s)                    | List[String]        | :fontawesome-solid-circle-minus:{ .not-required } |
| src_extra_columns | Select arbitrary columns from the source    | List[String]/String | :fontawesome-solid-circle-minus:{ .not-required } |
| src_eff           | Source effective from column                | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_ldts          | Source load date timestamp column           | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_source        | Name of the column containing the source ID | String              | :fontawesome-solid-circle-check:{ .required }     |
| source_model      | Staging model name                          | String              | :fontawesome-solid-circle-check:{ .required }     |

!!! tip
    [Read the tutorial](../tutorial/tut_t_links.md) for more details

#### Example Metadata

[See examples](../metadata.md#transactional-links)

#### Example Output
=== "Snowflake"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/t_links/t_link_transactions.sql"
        ```
    
    === "Incremental Loads"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/t_links/t_link_transactions_incremental.sql"
        ```

=== "Google BigQuery"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/t_links/t_link_transactions.sql"
        ```
    
    === "Incremental Loads"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/t_links/t_link_transactions_incremental.sql"
        ```

=== "MS SQL Server"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/t_links/t_link_transactions.sql"
        ```
    
    === "Incremental Loads"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/t_links/t_link_transactions_incremental.sql"
        ```

=== "Postgres"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/t_links/t_link_transactions.sql"
        ```
    
    === "Incremental Loads"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/t_links/t_link_transactions_incremental.sql"
        ```

=== "Databricks"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/t_links/t_link_transactions.sql"
        ```
    
    === "Incremental Loads"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/t_links/t_link_transactions_incremental.sql"
        ```


___

### sat

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/snowflake/`sat`.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/bigquery/sat.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/sqlserver/sat.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/databricks/sat.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/postgres/sat.sql)

Generates SQL to build a Satellite table using the provided parameters.

#### Usage

``` jinja
{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff, src_payload=src_payload,
                   src_extra_columns=src_extra_columns,
                   src_eff=src_eff, src_ldts=src_ldts, 
                   src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter         | Description                                 | Type                | Required?                                         |
|-------------------|---------------------------------------------|---------------------|---------------------------------------------------|
| src_pk            | Source primary key column                   | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |
| src_hashdiff      | Source hashdiff column                      | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_payload       | Source payload column(s)                    | List[String]        | :fontawesome-solid-circle-check:{ .required }     |
| src_extra_columns | Select arbitrary columns from the source    | List[String]/String | :fontawesome-solid-circle-minus:{ .not-required } |
| src_eff           | Source effective from column                | String              | :fontawesome-solid-circle-minus:{ .not-required } |
| src_ldts          | Source load date timestamp column           | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_source        | Name of the column containing the source ID | String              | :fontawesome-solid-circle-check:{ .required }     |
| source_model      | Staging model name                          | String              | :fontawesome-solid-circle-check:{ .required }     |

??? video "Video Tutorial"
    <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/9-5ibeTbT80" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

!!! tip
    [Read the tutorial](../tutorial/tut_satellites.md) for more details

#### Satellite Behaviour Flags

This section covers global variables ([var](https://docs.getdbt.com/docs/build/project-variables)) and [config](https://docs.getdbt.com/reference/model-configs#configuring-models) options that affect the behaviour of satellites.

| Parameter            | Description                                             | Type    | Flag type | Required?                                         |
|----------------------|---------------------------------------------------------|---------|-----------|---------------------------------------------------|
| apply_source_filter  | Adds additional logic to filter the `source_model` data | Boolean | config    | :fontawesome-solid-circle-minus:{ .not-required } |
| enable_ghost_records | Adds a single ghost record to the satellite             | Boolean | var       | :fontawesome-solid-circle-minus:{ .not-required } |


=== "apply_source_filter (config)"

    !!! tip "Added in v0.10.1"
    
    This config option adds a WHERE clause (in incremental mode) using an additional CTE in the SQL code to filter the `source_model`'s data
    
    This ensures that records in the source data are filtered so that only records with `src_ldts` after the MAX ldts in the existing Satellite
    are processed during the satellite load.
    
    **It is intended for this config option to be used if you cannot guarantee atomic/idempotent batches i.e. only data which has not been loaded yet in your stage data.**

    === "Example (model file)"
    
        ```sql

        -- sat_customer_details.sql
        {{
          config(
            apply_source_filter = true
          )
        }}

        {% set src_pk = ... %}
        ...

        {{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff, src_payload=src_payload,
                           src_extra_columns=src_extra_columns,
                           src_eff=src_eff, src_ldts=src_ldts, 
                           src_source=src_source, source_model=source_model) }}
        
        ```
    
=== "enable_ghost_records (var)"

    This global variable option enables additional logic to add a ghost record **_upon first creation_** OR **_once when running in incremental mode_** 
    if a ghost record has not already been added.
    
    [Read more](#ghost-record-configuration) about ghost records. 

#### Example Metadata

[See examples](../metadata.md#satellites)

#### Example Output

=== "Snowflake"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/satellites/satellite.sql"
        ```
    
    === "Incremental Loads"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/satellites/satellite_incremental.sql"
        ```

    === "Base Load with Ghost Record"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/satellites/satellite_ghost.sql"
        ```

    === "Incremental Loads with Ghost Record"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/satellites/satellite_ghost_incremental.sql"
        ```

=== "Google BigQuery"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/satellites/satellite.sql"
        ```
    
    === "Incremental Loads"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/satellites/satellite_incremental.sql"
        ```

    === "Base Load with Ghost Record"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/satellites/satellite_ghost.sql"
        ```

    === "Incremental Loads with Ghost Record"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/satellites/satellite_ghost_incremental.sql"
        ```

=== "MS SQL Server"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/satellites/satellite.sql"
        ```
    
    === "Incremental Loads"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/satellites/satellite_incremental.sql"
        ```

    === "Base Load with Ghost Record"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/satellites/satellite_ghost.sql"
        ```

    === "Incremental Loads with Ghost Record"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/satellites/satellite_ghost_incremental.sql"
        ```

=== "Postgres"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/satellites/satellite.sql"
        ```
    
    === "Incremental Loads"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/satellites/satellite_incremental.sql"
        ```

    === "Base Load with Ghost Record"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/satellites/satellite_ghost.sql"
        ```

    === "Incremental Loads with Ghost Record"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/satellites/satellite_ghost_incremental.sql"
        ```

=== "Databricks"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/satellites/satellite.sql"
        ```
    
    === "Incremental Loads"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/satellites/satellite_incremental.sql"
        ```

    === "Base Load with Ghost Record"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/satellites/satellite_ghost.sql"
        ```

    === "Incremental Loads with Ghost Record"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/satellites/satellite_ghost_incremental.sql"
        ```

#### Hashdiff Aliasing

If you have multiple Satellites using a single stage as its data source, then you will need to
use [hashdiff aliasing](../best_practises/hashing.md#hashdiff-aliasing)

#### Excluding columns from the payload

An `exclude_columns` flag can be provided for payload columns which will invert the selection of columns provided in the list of columns.

This is extremely useful when a payload is composed of many columns, and you do not wish to individually provide all the columns.

```yaml
{%- set yaml_metadata -%}
source_model: v_stg_orders
src_pk: CUSTOMER_HK
src_hashdiff: CUSTOMER_HASHDIFF
src_payload:
  exclude_columns: true
  columns:
    - NAME
    - PHONE
src_eff: EFFECTIVE_FROM
src_ldts: LOAD_DATETIME
src_source: RECORD_SOURCE
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                   src_hashdiff=metadata_dict["src_hashdiff"],
                   src_payload=metadata_dict["src_payload"],
                   src_eff=metadata_dict["src_eff"],
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}

```

Using the configuration in the above snippet, if we had the following columns: `NAME, PHONE, ADDRESS_LINE_1, EMAIL_ADDRESS, DOB,...`

The satellite payload would be created with the following columns: `ADDRESS_LINE_1, EMAIL_ADDRESS, DOB,...`


___

### eff_sat

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/snowflake/eff_sat.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/bigquery/eff_sat.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/sqlserver/eff_sat.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/databricks/eff_sat.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/postgres/eff_sat.sql)

Generates SQL to build an Effectivity Satellite table using the provided parameters.

#### Usage

``` jinja
{{ automate_dv.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                       src_start_date=src_start_date, src_end_date=src_end_date,
                       src_extra_columns=src_extra_columns,
                       src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                       source_model=source_model) }}
```

#### Parameters

| Parameter         | Description                                 | Type                | Required?                                         |
|-------------------|---------------------------------------------|---------------------|---------------------------------------------------|
| src_pk            | Source primary key column                   | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_dfk           | Source driving foreign key column           | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |
| src_sfk           | Source secondary foreign key column         | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |
| src_start_date    | Source start date column                    | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_end_date      | Source end date column                      | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_extra_columns | Select arbitrary columns from the source    | List[String]/String | :fontawesome-solid-circle-minus:{ .not-required } |
| src_eff           | Source effective from column                | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_ldts          | Source load date timestamp column           | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_source        | Name of the column containing the source ID | String              | :fontawesome-solid-circle-check:{ .required }     |
| source_model      | Staging model name                          | String              | :fontawesome-solid-circle-check:{ .required }     |

!!! tip
    [Read the tutorial](../tutorial/tut_eff_satellites.md) for more details

#### Example Metadata

[See examples](../metadata.md#effectivity-satellites)

#### Example Output

=== "Snowflake"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/eff_sats/eff_sat_customer_order.sql"
        ```
    
    === "With auto end-dating (Incremental)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/eff_sats/eff_sat_customer_order_incremental.sql"
        ```

    === "Without auto end-dating (Incremental)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/eff_sats/eff_sat_customer_order_incremental_nae.sql"
        ```

=== "Google BigQuery"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/eff_sats/eff_sat_customer_order.sql"
        ```
    
    === "With auto end-dating (Incremental)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/eff_sats/eff_sat_customer_order_incremental.sql"
        ```

    === "Without auto end-dating (Incremental)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/eff_sats/eff_sat_customer_order_incremental_nae.sql"
        ```


=== "MS SQL Server"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/eff_sats/eff_sat_customer_order.sql"
        ```
    
    === "With auto end-dating (Incremental)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/eff_sats/eff_sat_customer_order_incremental.sql"
        ```

    === "Without auto end-dating (Incremental)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/eff_sats/eff_sat_customer_order_incremental_nae.sql"
        ```


=== "Postgres"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/eff_sats/eff_sat_customer_order.sql"
        ```
    
    === "With auto end-dating (Incremental)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/eff_sats/eff_sat_customer_order_incremental.sql"
        ```

    === "Without auto end-dating (Incremental)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/eff_sats/eff_sat_customer_order_incremental_nae.sql"
        ```


=== "Databricks"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/eff_sats/eff_sat_customer_order.sql"
        ```
    
    === "With auto end-dating (Incremental)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/eff_sats/eff_sat_customer_order_incremental.sql"
        ```

    === "Without auto end-dating (Incremental)"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/eff_sats/eff_sat_customer_order_incremental_nae.sql"
        ```

#### Auto end-dating

Auto end-dating is enabled by providing a config option as below:

``` jinja
{{ config(is_auto_end_dating=true) }}

{{ automate_dv.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                       src_start_date=src_start_date, src_end_date=src_end_date,
                       src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                       source_model=source_model) }}
```

This will enable 3 extra CTEs in the Effectivity Satellite SQL generated by the macro. Examples of this SQL are in the
Example Output section above. The result of this will be additional effectivity records with end dates included, which
will aid business logic and creation of presentation layer structures downstream.

In most cases where Effectivity Satellites are recording 1-1 or 1-M relationships, this feature can be safely enabled.
In situations where a M-M relationship is being modelled/recorded, it becomes impossible to infer end dates. This
feature is disabled by default because it could be considered an application of a business rule:
The definition of the 'end' of a relationship is considered business logic which should happen in the Business Vault.

[Read the Effectivity Satellite tutorial](../tutorial/tut_eff_satellites.md) for more information.

!!! warning
    We have implemented the auto end-dating feature to cover most use cases and scenarios, but caution should be
    exercised if you are unsure.

___

### ma_sat

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/snowflake/ma_sat.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/bigquery/ma_sat.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/sqlserver/ma_sat.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/databricks/ma_sat.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/postgres/ma_sat.sql)

Generates SQL to build a Multi-Active Satellite (MAS) table.

#### Usage

``` jinja
{{ automate_dv.ma_sat(src_pk=src_pk, src_cdk=src_cdk, src_hashdiff=src_hashdiff, 
                      src_payload=src_payload, src_eff=src_eff,
                      src_extra_columns=src_extra_columns, src_ldts=src_ldts, 
                      src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter         | Description                                 | Type                | Required?                                         |
|-------------------|---------------------------------------------|---------------------|---------------------------------------------------|
| src_pk            | Source primary key column                   | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_cdk           | Source child dependent key(s) column(s)     | List[String]        | :fontawesome-solid-circle-check:{ .required }     |
| src_hashdiff      | Source hashdiff column                      | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_payload       | Source payload column(s)                    | List[String]        | :fontawesome-solid-circle-check:{ .required }     |
| src_eff           | Source effective from column                | String              | :fontawesome-solid-circle-minus:{ .not-required } |
| src_extra_columns | Select arbitrary columns from the source    | List[String]/String | :fontawesome-solid-circle-minus:{ .not-required } |
| src_ldts          | Source load date timestamp column           | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_source        | Name of the column containing the source ID | String              | :fontawesome-solid-circle-check:{ .required }     |
| source_model      | Staging model name                          | String              | :fontawesome-solid-circle-check:{ .required }     |

!!! tip
    [Read the tutorial](../tutorial/tut_multi_active_satellites.md) for more details

#### Example Metadata

[See examples](../metadata.md#multi-active-satellites-mas)

#### Example Output

=== "Snowflake"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/ma_sats/ma_sat_customer_address.sql"
        ```
    
    === "Incremental Loads"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/ma_sats/ma_sat_customer_address_incremental.sql"
        ```

=== "Google BigQuery"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/ma_sats/ma_sat_customer_address.sql"
        ```
    
    === "Incremental Loads"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/ma_sats/ma_sat_customer_address_incremental.sql"
        ```

=== "MS SQL Server"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/ma_sats/ma_sat_customer_address.sql"
        ```
    
    === "Incremental Loads"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/ma_sats/ma_sat_customer_address_incremental.sql"
        ```

=== "Postgres"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/ma_sats/ma_sat_customer_address.sql"
        ```
    
    === "Incremental Loads"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/raw_vault/ma_sats/ma_sat_customer_address_incremental.sql"
        ```

=== "Databricks"

    === "Base Load"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/ma_sats/ma_sat_customer_address.sql"
        ```
    
    === "Incremental Loads"
    
        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/raw_vault/ma_sats/ma_sat_customer_address_incremental.sql"
        ```

### xts

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/snowflake/xts.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/bigquery/xts.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/sqlserver/xts.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/databricks/xts.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/postgres/xts.sql)

Generates SQL to build an Extended Tracking Satellite table using the provided parameters.

#### Usage

``` jinja
{{ automate_dv.xts(src_pk=src_pk, src_satellite=src_satellite, 
                   src_extra_columns=src_extra_columns, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}`
```

#### Parameters

| Parameter         | Description                                                    | Type                | Required?                                         |
|-------------------|----------------------------------------------------------------|---------------------|---------------------------------------------------|
| src_pk            | Source primary key column                                      | String/List         | :fontawesome-solid-circle-check:{ .required }     |
| src_satellite     | Dictionary of source satellite name column and hashdiff column | Dictionary          | :fontawesome-solid-circle-check:{ .required }     |
| src_extra_columns | Select arbitrary columns from the source                       | List[String]/String | :fontawesome-solid-circle-minus:{ .not-required } |
| src_ldts          | Source load date/timestamp column                              | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_source        | Name of the column containing the source ID                    | String/List         | :fontawesome-solid-circle-check:{ .required }     |
| source_model      | Staging model name                                             | String/List         | :fontawesome-solid-circle-check:{ .required }     |

!!! tip
    [Read the tutorial](../tutorial/tut_xts.md) for more details

!!! note "Understanding the src_satellite parameter"
    [Read More](../metadata.md#understanding-the-srcsatellite-parameter)

#### Example Metadata

[See examples](../metadata.md#extended-tracking-satellites-xts)

#### Example Output

=== "Snowflake"

    === "Single-Source"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/xts/xts_customer_phone.sql"
        ```

    === "Single-Source with Multiple Satellite Feeds"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/xts/xts_customer_phone_multi_sat.sql"
        ```

    === "Multi-Source"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/xts/xts_customer_phone_multi_source.sql"
        ```

=== "Google Bigquery"

    === "Single-Source"

        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/xts/xts_customer_phone.sql"
        ```

    === "Single-Source with Multiple Satellite Feeds"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/xts/xts_customer_phone_multi_sat.sql"
        ```

    === "Multi-Source"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/raw_vault/xts/xts_customer_phone_multi_source.sql"
        ```

=== "MS SQL Server"

    === "Single-Source"

        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/xts/xts_customer_phone.sql"
        ```

    === "Single-Source with Multiple Satellite Feeds"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/xts/xts_customer_phone_multi_sat.sql"
        ```

    === "Multi-Source"
        
        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/raw_vault/xts/xts_customer_phone_multi_source.sql"
        ```

=== "Postgres"
    Example Coming soon!

=== "Databricks"
    Example Coming soon!

### pit

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/snowflake/pit.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/bigquery/pit.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/sqlserver/pit.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/databricks/pit.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/postgres/pit.sql)

Generates SQL to build a Point-In-Time (PIT) table.

``` jinja
{{ automate_dv.pit(src_pk=src_pk, 
                   as_of_dates_table=as_of_dates_table,
                   satellites=satellites,
                   stage_tables_ldts=stage_tables_ldts,
                   src_ldts=src_ldts,
                   source_model=source_model) }}
```

#### Parameters

| Parameter         | Description                                  | Type    | Required?                                     |
|-------------------|----------------------------------------------|---------|-----------------------------------------------|
| src_pk            | Source primary key column                    | String  | :fontawesome-solid-circle-check:{ .required } |
| as_of_dates_table | Name for the As of Date table                | String  | :fontawesome-solid-circle-check:{ .required } |
| satellites        | Dictionary of satellite reference mappings   | Mapping | :fontawesome-solid-circle-check:{ .required } |
| stage_tables_ldts | Dictionary of stage table reference mappings | Mapping | :fontawesome-solid-circle-check:{ .required } |
| src_ldts          | Source load date timestamp column            | String  | :fontawesome-solid-circle-check:{ .required } |
| source_model      | Hub model name                               | String  | :fontawesome-solid-circle-check:{ .required } |

!!! tip
    [Read the tutorial](../tutorial/tut_point_in_time.md) for more details

#### Example Metadata

[See examples](../metadata.md#point-in-time-pit-tables)

#### Example Output

=== "Snowflake"

    === "Base Load"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/query_helpers/pits/base_load.sql"
        ```

    === "Incremental Load"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/query_helpers/pits/incremental_load.sql"
        ```

=== "Google Bigquery"
    Example Coming soon!

=== "MS SQL Server"
    Example Coming soon!

=== "Postgres"
    Example Coming soon!

=== "Databricks"
    Example Coming soon!

#### As Of Date Tables

An As of Date table contains a single column of dates (a date spine) used to construct the history in the PIT. A typical
structure will contain a date range where the date interval will be short, such as every day or every hour, followed by
a period of time after which the date intervals are slightly larger.

An example history could be end of day values for 3 months followed by another 3 months of end of week values. The As of
Date table would then contain a datetime for each entry to match this.

As the days pass, the As of Dates should change to reflect this with dates being removed off the end and new dates
added.

If we use the 3-month example from before, and a week had passed since when we had created the As of Date table, then it
would still contain 3 months worth of end of day values followed by 3 months of end of week values but shifted a week
forward to reflect the current date.

Think of As of Date tables as essentially a rolling window of time.

!!! note 
    At the current release of AutomateDV there is no functionality that auto generates this table for you, so you
    will have to supply this yourself. For further information, please check the tutorial [page](../tutorial/tut_as_of_date.md).

    Another caveat is that even though the As of Date table can take any name, you need to make sure it's defined 
    accordingly in the `as_of_dates_table` metadata parameter (see the [metadata section](../metadata.md#point-in-time-pit-tables) 
    for PITs). The column name in the As of Date table is currently defaulted to 'AS_OF_DATE' and it cannot be changed.

___

### bridge

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/snowflake/bridge.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/bigquery/bridge.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/sqlserver/bridge.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/databricks/bridge.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.10.1/macros/tables/postgres/bridge.sql)

Generates SQL to build a simple Bridge table, starting from a Hub and 'walking' through one or more associated Links (
and their Effectivity Satellites), using the provided parameters.

For the current version, Effectivity Satellite auto end dating must be enabled.

#### Usage

``` jinja
{{ automate_dv.bridge(source_model=source_model, src_pk=src_pk,
                      src_ldts=src_ldts,
                      bridge_walk=bridge_walk,
                      as_of_dates_table=as_of_dates_table,
                      stage_tables_ldts=stage_tables_ldts) }}
```

#### Parameters

| Parameter         | Description                                                                 | Type    | Required?                                     |
|-------------------|-----------------------------------------------------------------------------|---------|-----------------------------------------------|
| source_model      | Starting Hub model name                                                     | String  | :fontawesome-solid-circle-check:{ .required } |
| src_pk            | Starting Hub primary key column                                             | String  | :fontawesome-solid-circle-check:{ .required } |
| src_ldts          | Starting Hub load date timestamp                                            | String  | :fontawesome-solid-circle-check:{ .required } |
| bridge_walk       | Dictionary of bridge reference mappings                                     | Mapping | :fontawesome-solid-circle-check:{ .required } |
| as_of_dates_table | Name for the As of Date table                                               | String  | :fontawesome-solid-circle-check:{ .required } |
| stage_tables_ldts | Dictionary of stage table reference mappings and their load date timestamps | Mapping | :fontawesome-solid-circle-check:{ .required } |

!!! tip
    [Read the tutorial](../tutorial/tut_bridges.md) for more details

#### Example Metadata

[See examples](../metadata.md#bridge-tables)

#### Example Output

=== "Snowflake"

    === "Base Load"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/query_helpers/bridges/base_load.sql"
        ```

    === "Incremental Load"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/query_helpers/bridges/incremental_load.sql"
        ```

=== "Google Bigquery"
    Example Coming soon!

=== "MS SQL Server"
    Example Coming soon!

=== "Postgres"
    Example Coming soon!

=== "Databricks"
    Example Coming soon!

#### As Of Date Table Structures

An As of Date table contains a single column of dates used to construct the history in the Bridge table.

!!! note

    At the current release of AutomateDV there is no functionality that auto generates this table for you, so you will 
    have to supply this yourself. For further information, please check the tutorial [page](../tutorial/tut_as_of_date.md).
    
    Another caveat is that even though the As of Date table can take any name, you need to make sure it's defined 
    accordingly in the `as_of_dates_table` metadata parameter (see the [metadata section](../metadata.md#bridge-tables) 
    for Bridges). The column name in the As of Date table is currently defaulted to 'AS_OF_DATE' and it cannot be changed.

___

### ref_table

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/dbtvault/blob/v0.10.0/macros/tables/snowflake/ref_table.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/dbtvault/blob/v0.10.0/macros/tables/bigquery/ref_table.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/dbtvault/blob/v0.10.0/macros/tables/sqlserver/ref_table.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/dbtvault/blob/v0.10.0/macros/tables/databricks/ref_table.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/dbtvault/blob/v0.10.0/macros/tables/postgres/ref_table.sql)

Generates SQL to build a Reference table using the provided parameters.

#### Usage

``` jinja

{{ automate_dv.ref_table(src_pk=src_pk, src_ldts=src_ldts,
                         src_extra_columns=src_extra_columns,
                         src_ldts=src_ldts, src_source=src_source,
                         source_model=source_model) }}
```

#### Parameters

| Parameter         | Description                                 | Type                | Required?                                         |
|-------------------|---------------------------------------------|---------------------|---------------------------------------------------|
| src_pk            | Source primary key column                   | String              | :fontawesome-solid-circle-check:{ .required }     |
| src_extra_columns | Select arbitrary columns from the source    | List[String]/String | :fontawesome-solid-circle-minus:{ .not-required } |
| src_ldts          | Source load date timestamp column           | String              | :fontawesome-solid-circle-minus:{ .not-required } |
| src_source        | Name of the column containing the source ID | String              | :fontawesome-solid-circle-minus:{ .not-required } |
| source_model      | Staging model name                          | String              | :fontawesome-solid-circle-check:{ .required }     |

!!! tip
    [Read the tutorial](../tutorial/tut_ref_tables.md) for more details

#### Example Metadata

[See examples](../metadata.md#reference-tables)

#### Example Output

=== "Base Load"

    ```sql
    --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/ref_tables/ref_tables_base.sql"
    ```

=== "Incremental Load"

    ```sql
    --8<-- "docs/assets/snippets/compiled/snowflake/raw_vault/ref_tables/ref_tables_incremental.sql"
    ```

___

## Staging Macros

###### (macros/staging)

These macros are intended for use in the staging layer.

In AutomateDV, we call this staging layer "primed staging" as we are preparing or 'priming' the data ready for use in the
raw vault. It is important to understand that according to Data Vault 2.0 standards, the primed stages is
essentially where all of our **_hard_** business rules are defined. We are not excessively transforming the data beyond
what is reasonable prior to the raw stage, but simply creating some columns to drive audit and performance downstream.

___

### stage

([view source](https://github.com/Datavault-UK/automate-dv/blob/release/0.9.6/macros/staging/stage.sql))

Generates SQL to build a staging area using the provided parameters.

#### Usage

``` jinja 
{{ automate_dv.stage(include_source_columns=true,
                     source_model=source_model,
                     derived_columns=derived_columns,
                     null_columns=null_columns,
                     hashed_columns=hashed_columns,
                     ranked_columns=ranked_columns) }}
```

#### Parameters

| Parameter              | Description                                                                 | Type    | Default | Required?                                         |
|------------------------|-----------------------------------------------------------------------------|---------|---------|---------------------------------------------------|
| include_source_columns | If true, select all columns in the `source_model`                           | Boolean | true    | :fontawesome-solid-circle-minus:{ .not-required } |
| source_model           | Staging model name                                                          | Mapping | N/A     | :fontawesome-solid-circle-check:{ .required }     |
| derived_columns        | Mappings of column names and their value                                    | Mapping | none    | :fontawesome-solid-circle-minus:{ .not-required } |
| null_columns           | Mappings of columns for which null business keys should be replaced         | Mapping | none    | :fontawesome-solid-circle-minus:{ .not-required } |
| hashed_columns         | Mappings of hashes to their component columns                               | Mapping | none    | :fontawesome-solid-circle-minus:{ .not-required } |
| ranked_columns         | Mappings of ranked columns names to their order by and partition by columns | Mapping | none    | :fontawesome-solid-circle-minus:{ .not-required } |

??? video "Video Tutorial"
    <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/7yyrARKipeA" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

!!! tip
    [Read the tutorial](../tutorial/tut_staging.md) for more details

#### Example Metadata

[See examples](../metadata.md#staging)

#### Example Output

=== "Snowflake"

    === "All configurations"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/staging/primed_stages/stg_customer_all.sql"
        ```

    === "Only source columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/staging/primed_stages/stg_customer_only_source.sql"
        ```

    === "Only null columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/staging/primed_stages/stg_customer_only_null.sql"
        ```

    === "Only hashed columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/staging/primed_stages/stg_customer_only_hashed.sql"
        ```

    === "Only ranked columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/snowflake/staging/primed_stages/stg_customer_only_ranked.sql"
        ```

=== "Google BigQuery"

    === "All configurations"

        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/staging/primed_stages/stg_customer_all.sql"
        ```

    === "Only source columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/staging/primed_stages/stg_customer_only_source.sql"
        ```

    === "Only null columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/staging/primed_stages/stg_customer_only_null.sql"
        ```

    === "Only hashed columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/staging/primed_stages/stg_customer_only_hashed.sql"
        ```

    === "Only ranked columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/bigquery/staging/primed_stages/stg_customer_only_ranked.sql"

=== "MS SQL Server"

    === "All configurations"

        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/staging/primed_stages/stg_customer_all.sql"
        ```

    === "Only source columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/staging/primed_stages/stg_customer_only_source.sql"
        ```

    === "Only null columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/staging/primed_stages/stg_customer_only_null.sql"
        ```

    === "Only hashed columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/staging/primed_stages/stg_customer_only_hashed.sql"
        ```

    === "Only ranked columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/sqlserver/staging/primed_stages/stg_customer_only_ranked.sql"
        ```

=== "Postgres"

    === "All configurations"

        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/staging/primed_stages/stg_customer_all.sql"
        ```

    === "Only source columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/staging/primed_stages/stg_customer_only_source.sql"
        ```

    === "Only null columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/staging/primed_stages/stg_customer_only_null.sql"
        ```

    === "Only hashed columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/staging/primed_stages/stg_customer_only_hashed.sql"
        ```

    === "Only ranked columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/postgres/staging/primed_stages/stg_customer_only_ranked.sql"
        ```

=== "Databricks"

    === "All configurations"

        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/staging/primed_stages/stg_customer_all.sql"
        ```

    === "Only source columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/staging/primed_stages/stg_customer_only_source.sql"
        ```

    === "Only null columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/staging/primed_stages/stg_customer_only_null.sql"
        ```

    === "Only hashed columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/staging/primed_stages/stg_customer_only_hashed.sql"
        ```

    === "Only ranked columns"

        ```sql
        --8<-- "docs/assets/snippets/compiled/databricks/staging/primed_stages/stg_customer_only_ranked.sql"
        ```

### Stage Macro Configurations

[Stage Macro In-Depth](stage_macro_configurations.md){: .md-button .md-button--primary .btn }

## Supporting Macros

###### (macros/supporting)

Supporting macros are helper functions for use in models. It should not be necessary to call these macros directly,
however they are used extensively in the [table templates](#table-templates) and may be used for your own purposes if
you wish.

___

### hash (macro)

([view source](https://github.com/Datavault-UK/automate-dv/blob/release/0.9.6/macros/supporting/hash.sql))

!!! warning
    This macro ***should not be*** used for cryptographic purposes.
    The intended use is for creating checksum-like values only, so that we may compare records consistently.    
    [Read More](https://www.md5online.org/blog/why-md5-is-not-safe/)

!!! seealso "See Also"
    - [hash_columns](stage_macro_configurations.md#hashed-columns)
    - Read [Hashing best practices and why we hash](../best_practises/hashing.md)
    for more detailed information on the purposes of this macro and what it does.
    - You may choose between `MD5` and `SHA-256` hashing.
    [Learn how](../best_practises/hashing.md#choosing-a-hashing-algorithm)
    
A macro for generating hashing SQL for columns.

#### Usage

=== "Input"

    ```yaml
    {{ automate_dv.hash('CUSTOMERKEY', 'CUSTOMER_HK') }},
    {{ automate_dv.hash(['CUSTOMERKEY', 'PHONE', 'DOB', 'NAME'], 'HASHDIFF', true) }}
    ```

=== "Output (Snowflake)"

    === "MD5"

        ```sql
        CAST(MD5_BINARY(CONCAT_WS('||',
        IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'),
        IFNULL(NULLIF(UPPER(TRIM(CAST(DOB AS VARCHAR))), ''), '^^'),
        IFNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR))), ''), '^^')
        )) AS BINARY(16)) AS HASHDIFF
        ```

    === "SHA (256)"

        ```sql
        CAST(SHA2_BINARY(CONCAT_WS('||',
        IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'),
        IFNULL(NULLIF(UPPER(TRIM(CAST(DOB AS VARCHAR))), ''), '^^'), 
        IFNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR))), ''), '^^')
        )) AS BINARY(32)) AS HASHDIFF
        ```

=== "Output (MS SQL Server)"

    === "MD5"

        ```sql
        CAST(HASHBYTES('MD5', (CONCAT_WS('||',
        ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(max)))), ''), '^^'),
        ISNULL(NULLIF(UPPER(TRIM(CAST(DOB AS VARCHAR(max)))), ''), '^^'),
        ISNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR(max)))), ''), '^^')
        )) AS BINARY(16)) AS HASHDIFF
        ```

    === "SHA (256)"

        ```sql
        CAST(HASHBYTES('SHA2_256', (CONCAT_WS('||',
        ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(max)))), ''), '^^'),
        ISNULL(NULLIF(UPPER(TRIM(CAST(DOB AS VARCHAR(max)))), ''), '^^'), 
        ISNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR(max)))), ''), '^^')
        )) AS BINARY(32)) AS HASHDIFF
        ```

!!! tip 
    The [hash_columns](stage_macro_configurations.md#hashed-columns) macro can be used to simplify the hashing process and generate multiple hashes
    with one macro.

#### Parameters

| Parameter   | Description                                     | Type                | Required?                                         |
|-------------|-------------------------------------------------|---------------------|---------------------------------------------------|
| columns     | Columns to hash on                              | List[String]/String | :fontawesome-solid-circle-check:{ .required }     |
| alias       | The name to give the hashed column              | String              | :fontawesome-solid-circle-check:{ .required }     |
| is_hashdiff | Will alpha sort columns if true, default false. | Boolean             | :fontawesome-solid-circle-minus:{ .not-required } |      

___

### prefix

([view source](https://github.com/Datavault-UK/automate-dv/blob/release/0.9.6/macros/supporting/prefix.sql))

A macro for quickly prefixing a list of columns with a string.

#### Parameters

| Parameter  | Description                | Type         | Required?                                     |
|------------|----------------------------|--------------|-----------------------------------------------|
| columns    | A list of column names     | List[String] | :fontawesome-solid-circle-check:{ .required } |
| prefix_str | The prefix for the columns | String       | :fontawesome-solid-circle-check:{ .required } |

#### Usage

=== "Input"

    ```sql 
    {{ automate_dv.prefix(['CUSTOMERKEY', 'DOB', 'NAME', 'PHONE'], 'a') }} {{ automate_dv.prefix(['CUSTOMERKEY'], 'a') }}
    ```

=== "Output"

    ```sql 
    a.CUSTOMERKEY, a.DOB, a.NAME, a.PHONE a.CUSTOMERKEY
    ```

!!! note 
    Single columns must be provided as a 1-item list.

___

## Internal

###### (macros/internal)

Internal macros are used by other macros provided by AutomateDV. They process provided metadata and should not need to be
called directly.

--8<-- "includes/abbreviations.md"