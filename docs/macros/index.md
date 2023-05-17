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

This variable configures whether hashed columns are normalised with `UPPER()` when calculating the hashing.

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

!!! tip "New in v0.9.1"
    We've added this config to give you more options when hashing. If there is logic difference between uppercase
    and lowercase values in your data, set this to `DISABLED` otherwise, the standard approach is to use `UPPER` 

### Ghost Record configuration

!!! tip "New in v0.9.1"
    Ghost Records are here! This is our first iteration of Ghost Records functionality. Please give us feedback on
    GitHub or Slack :smile:


```yaml
vars:
  enable_ghost_records: false
  system_record_value: 'AUTOMATE_DV_SYSTEM'
```

#### enable_ghost_records

Enable the use of ghost records in your project. This can either be true or false, `true` will enable the configuration and `false` will disable it.

This will insert a ghost record to a satellite table whether it is a new table or pre-loaded. 

Before adding the ghost record, the satellite macro will check there is not already one loaded.

!!! note
    If this is enabled on an existing project, the ghost-records will be inserted into the satellite on the first dbt run after enabling **_only_**

#### system_record_value

This will set the record source system for the ghost record. The default is 'AUTOMATE_DV_SYSTEM' and can be changed to any string.

!!! note
    If this is changed on an existing project, the source system of already loaded ghost records will not be changed.

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

| Macro/Template | Snowflake                                     | Google BigQuery                               | MS SQL Server                                 | Databricks**                                      | Postgres**                                        | Redshift**                                        |
|----------------|-----------------------------------------------|-----------------------------------------------|-----------------------------------------------|---------------------------------------------------|---------------------------------------------------|---------------------------------------------------|
| hash           | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required }     | :fontawesome-solid-circle-check:{ .required }     | :fontawesome-solid-circle-minus:{ .not-required } |
| stage          | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required }     | :fontawesome-solid-circle-check:{ .required }     | :fontawesome-solid-circle-minus:{ .not-required } |
| hub            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required }     | :fontawesome-solid-circle-check:{ .required }     | :fontawesome-solid-circle-minus:{ .not-required } |
| link           | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required }     | :fontawesome-solid-circle-check:{ .required }     | :fontawesome-solid-circle-minus:{ .not-required } |
| sat            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required }     | :fontawesome-solid-circle-check:{ .required }     | :fontawesome-solid-circle-minus:{ .not-required } |
| t_link         | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } |
| eff_sat        | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } |
| ma_sat         | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } |
| xts            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } |
| pit            | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } |
| bridge         | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-check:{ .required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } | :fontawesome-solid-circle-minus:{ .not-required } |

!!! note "**"
    These platforms are either planned or actively being worked on by the community and/or internal AutomateDV team.
    See the issues below for more information:

    - [Databricks](https://github.com/Datavault-UK/automate-dv/issues/98)
    - [Postgres](https://github.com/Datavault-UK/automate-dv/issues/117)
    - [Redshift](https://github.com/Datavault-UK/automate-dv/issues/86)

### Limitations

This section documents platform-specific limitations.

#### Postgres

Due to the way Postgres handles CTEs, AutomateDV's [custom materialisations](../materialisations.md) are not yet 
available for use on Postgres. An exception will be raised if their use is attempted.

## Table templates

###### (macros/tables)

These macros are the core of the package and can be called in your models to build the different types of tables needed
for your Data Vault 2.0 Data Warehouse.

### hub

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/snowflake/hub.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/bigquery/hub.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/sqlserver/hub.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/databricks/hub.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/postgres/hub.sql)

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
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
        )

        SELECT * FROM records_to_insert
        ```
    
    === "Single-Source (Subsequent Loads)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
            LEFT JOIN AUTOMATE_DV.TEST.hub AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE_2
            QUALIFY row_number = 1
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            UNION ALL
            SELECT * FROM row_rank_2
        ),
        
        row_rank_union AS (
            SELECT *,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE, RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union
            WHERE CUSTOMER_HK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Subsequent Loads)"
 
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE_2
            QUALIFY row_number = 1
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            UNION ALL
            SELECT * FROM row_rank_2
        ),
        
        row_rank_union AS (
            SELECT *,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE, RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union
            WHERE CUSTOMER_HK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
            LEFT JOIN AUTOMATE_DV.TEST.hub AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google BigQuery"

    === "Single-Source (Base Load)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
            WHERE CUSTOMER_HK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
        )

        SELECT * FROM records_to_insert
        ```

    === "Single-Source (Subsequent Loads)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
            WHERE CUSTOMER_HK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
            LEFT JOIN AUTOMATE_DV.TEST.hub AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Multi-Source (Base Load)"

        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE 
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
            WHERE CUSTOMER_HK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE_2
            WHERE CUSTOMER_HK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            UNION ALL
            SELECT * FROM row_rank_2
        ),
        
        row_rank_union AS (
            SELECT *,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE, RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union
            WHERE CUSTOMER_HK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Subsequent Loads)"
 
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
            WHERE CUSTOMER_HK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE_2
            WHERE CUSTOMER_HK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            UNION ALL
            SELECT * FROM row_rank_2
        ),
        
        row_rank_union AS (
            SELECT *,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE, RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union
            WHERE CUSTOMER_HK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
            LEFT JOIN AUTOMATE_DV.TEST.hub AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "MS SQL Server"

    === "Single-Source (Base Load)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE ASC
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
            ) h
            WHERE h.row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Single-Source (Subsequent Loads)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE ASC
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
            ) h
            WHERE h.row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
            LEFT JOIN AUTOMATE_DV.TEST.hub AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE ASC
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
            ) h
            WHERE h.row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE_2 AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
            ) h
            WHERE h.row_number = 1
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            UNION ALL
            SELECT * FROM row_rank_2
        ),
        
        row_rank_union AS (
            SELECT *
            FROM
            (
                SELECT ru.*,
                       ROW_NUMBER() OVER(
                           PARTITION BY ru.CUSTOMER_HK
                           ORDER BY ru.LOAD_DATE, ru.RECORD_SOURCE ASC
                       ) AS row_rank_number
                FROM stage_union AS ru
                WHERE ru.CUSTOMER_HK IS NOT NULL
            ) h
            WHERE h.row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Subsequent Loads)"
 
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE ASC
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
            ) h
            WHERE h.row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE_2 AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
            ) h
            WHERE h.row_number = 1
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            UNION ALL
            SELECT * FROM row_rank_2
        ),
        
        row_rank_union AS (
            SELECT *
            FROM
            (
                SELECT ru.*,
                       ROW_NUMBER() OVER(
                           PARTITION BY ru.CUSTOMER_HK
                           ORDER BY ru.LOAD_DATE, ru.RECORD_SOURCE ASC
                       ) AS row_rank_number
                FROM stage_union AS ru
                WHERE ru.CUSTOMER_HK IS NOT NULL
            ) h
            WHERE h.row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
            LEFT JOIN AUTOMATE_DV.TEST.hub AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

___

### link

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/snowflake/link.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/bigquery/link.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/sqlserver/link.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/databricks/link.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/postgres/link.sql)

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
        WITH row_rank_1 AS (
            SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY rr.CUSTOMER_HK
                       ORDER BY rr.LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
            WHERE rr.CUSTOMER_HK IS NOT NULL
            AND rr.ORDER_FK IS NOT NULL
            AND rr.BOOKING_FK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Single-Source (Subsequent Loads)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY rr.CUSTOMER_HK
                       ORDER BY rr.LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
            WHERE rr.CUSTOMER_HK IS NOT NULL
            AND rr.ORDER_FK IS NOT NULL
            AND rr.BOOKING_FK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
            LEFT JOIN AUTOMATE_DV.TEST.link AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
                
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        WITH row_rank_1 AS (
            SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY rr.CUSTOMER_HK
                       ORDER BY rr.LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
            WHERE rr.CUSTOMER_HK IS NOT NULL
            AND rr.ORDER_FK IS NOT NULL
            AND rr.BOOKING_FK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY rr.CUSTOMER_HK
                       ORDER BY rr.LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE_2 AS rr
            WHERE rr.CUSTOMER_HK IS NOT NULL
            AND rr.ORDER_FK IS NOT NULL
            AND rr.BOOKING_FK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            UNION ALL
            SELECT * FROM row_rank_2
        ),
        
        row_rank_union AS (
            SELECT ru.*,
                   ROW_NUMBER() OVER(
                       PARTITION BY ru.CUSTOMER_HK
                       ORDER BY ru.LOAD_DATE, ru.RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union AS ru
            WHERE ru.ORDER_FK IS NOT NULL
            AND ru.BOOKING_FK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Subsequent Loads)"
 
        ```sql
        WITH row_rank_1 AS (
            SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY rr.CUSTOMER_HK
                       ORDER BY rr.LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
            WHERE rr.CUSTOMER_HK IS NOT NULL
            AND rr.ORDER_FK IS NOT NULL
            AND rr.BOOKING_FK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY rr.CUSTOMER_HK
                       ORDER BY rr.LOAD_DATE ASC
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
            WHERE rr.CUSTOMER_HK IS NOT NULL
            AND rr.ORDER_FK IS NOT NULL
            AND rr.BOOKING_FK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            UNION ALL
            SELECT * FROM row_rank_2
        ),
        
        row_rank_union AS (
            SELECT ru.*,
                   ROW_NUMBER() OVER(
                       PARTITION BY ru.CUSTOMER_HK
                       ORDER BY ru.LOAD_DATE, ru.RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union AS ru
            WHERE ru.ORDER_FK IS NOT NULL
            AND ru.BOOKING_FK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
            LEFT JOIN AUTOMATE_DV.TEST.link AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google BigQuery"

    === "Single-Source (Base Load)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
            WHERE CUSTOMER_HK IS NOT NULL
            AND ORDER_FK IS NOT NULL
            AND BOOKING_FK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Single-Source (Subsequent Loads)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
            WHERE CUSTOMER_HK IS NOT NULL
            AND ORDER_FK IS NOT NULL
            AND BOOKING_FK IS NOT NULL
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
            LEFT JOIN AUTOMATE_DV.TEST.link AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
                
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE_2
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            WHERE row_number = 1
            UNION ALL
            SELECT * FROM row_rank_2
            WHERE row_number = 1
        ),
        
        row_rank_union AS (
            SELECT *,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE, RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union
            WHERE CUSTOMER_HK IS NOT NULL
            AND ORDER_FK IS NOT NULL
            AND BOOKING_FK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Multi-Source (Subsequent Loads)"
 
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE
                   ) AS row_number
            FROM AUTOMATE_DV.TEST.MY_STAGE_2
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            WHERE row_number = 1
            UNION ALL
            SELECT * FROM row_rank_2
            WHERE row_number = 1
        ),
        
        row_rank_union AS (
            SELECT *,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE, RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union
            WHERE CUSTOMER_HK IS NOT NULL
            AND ORDER_FK IS NOT NULL
            AND BOOKING_FK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
            LEFT JOIN AUTOMATE_DV.TEST.link AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "MS SQL Server"

    === "Single-Source (Base Load)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT *
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE ASC
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
                AND rr.ORDER_FK IS NOT NULL
                AND rr.BOOKING_FK IS NOT NULL
            ) l
            WHERE l.row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Single-Source (Subsequent Loads)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT *
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE ASC
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
                AND rr.ORDER_FK IS NOT NULL
                AND rr.BOOKING_FK IS NOT NULL
            ) l
            WHERE l.row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
            LEFT JOIN AUTOMATE_DV.TEST.link AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
                
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        WITH row_rank_1 AS (
            SELECT *
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE ASC
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
                AND rr.ORDER_FK IS NOT NULL
                AND rr.BOOKING_FK IS NOT NULL
            ) l
            WHERE l.row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT *
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE ASC
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE_2 AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
                AND rr.ORDER_FK IS NOT NULL
                AND rr.BOOKING_FK IS NOT NULL
            ) l
            WHERE l.row_number = 1
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            UNION ALL
            SELECT * FROM row_rank_2
        ),
        
        row_rank_union AS (
            SELECT *
            FROM
            (
                SELECT ru.*,
                       ROW_NUMBER() OVER(
                           PARTITION BY ru.CUSTOMER_HK
                           ORDER BY ru.LOAD_DATE, ru.RECORD_SOURCE ASC
                       ) AS row_rank_number
                FROM stage_union AS ru
                WHERE ru.ORDER_FK IS NOT NULL
                AND ru.BOOKING_FK IS NOT NULL
            ) r
            WHERE r.row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Subsequent Loads)"
 
        ```sql
        WITH row_rank_1 AS (
            SELECT *
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE ASC
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
                AND rr.ORDER_FK IS NOT NULL
                AND rr.BOOKING_FK IS NOT NULL
            ) l
            WHERE l.row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT *
            FROM
            (
                SELECT rr.CUSTOMER_HK, rr.ORDER_FK, rr.BOOKING_FK, rr.LOAD_DATE, rr.RECORD_SOURCE,
                       ROW_NUMBER() OVER(
                           PARTITION BY rr.CUSTOMER_HK
                           ORDER BY rr.LOAD_DATE ASC
                       ) AS row_number
                FROM AUTOMATE_DV.TEST.MY_STAGE_2 AS rr
                WHERE rr.CUSTOMER_HK IS NOT NULL
                AND rr.ORDER_FK IS NOT NULL
                AND rr.BOOKING_FK IS NOT NULL
            ) l
            WHERE l.row_number = 1
        ),
        
        stage_union AS (
            SELECT * FROM row_rank_1
            UNION ALL
            SELECT * FROM row_rank_2
        ),
        
        row_rank_union AS (
            SELECT *
            FROM
            (
                SELECT ru.*,
                       ROW_NUMBER() OVER(
                           PARTITION BY ru.CUSTOMER_HK
                           ORDER BY ru.LOAD_DATE, ru.RECORD_SOURCE ASC
                       ) AS row_rank_number
                FROM stage_union AS ru
                WHERE ru.ORDER_FK IS NOT NULL
                AND ru.BOOKING_FK IS NOT NULL
            ) r
            WHERE r.row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
            LEFT JOIN AUTOMATE_DV.TEST.link AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

___

### t_link

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/snowflake/t_link.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/bigquery/t_link.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/sqlserver/t_link.sql)

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
        WITH stage AS (
            SELECT TRANSACTION_HK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM AUTOMATE_DV.TEST.MY_STAGE
            WHERE TRANSACTION_HK IS NOT NULL
            AND CUSTOMER_FK IS NOT NULL
        ),

        records_to_insert AS (
            SELECT DISTINCT stg.TRANSACTION_HK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH stage AS (
            SELECT TRANSACTION_HK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM AUTOMATE_DV.TEST.raw_stage_hashed
            WHERE TRANSACTION_HK IS NOT NULL
            AND CUSTOMER_FK IS NOT NULL
        ),

        records_to_insert AS (
            SELECT DISTINCT stg.TRANSACTION_HK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
            LEFT JOIN AUTOMATE_DV.TEST.t_link AS tgt
            ON stg.TRANSACTION_HK = tgt.TRANSACTION_HK
            WHERE tgt.TRANSACTION_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google BigQuery"

    === "Base Load"
    
        ```sql
        WITH stage AS (
            SELECT TRANSACTION_HK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM AUTOMATE_DV.TEST.MY_STAGE
            WHERE TRANSACTION_HK IS NOT NULL
            AND CUSTOMER_FK IS NOT NULL
        ),
        records_to_insert AS (
            SELECT DISTINCT stg.TRANSACTION_HK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Subsequent Loads"
        
        ```sql
        WITH stage AS (
            SELECT TRANSACTION_HK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM AUTOMATE_DV.TEST.raw_stage_hashed
            WHERE TRANSACTION_HK IS NOT NULL
            AND CUSTOMER_FK IS NOT NULL
        ),
        records_to_insert AS (
            SELECT DISTINCT stg.TRANSACTION_HK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
            LEFT JOIN AUTOMATE_DV.TEST.t_link AS tgt
            ON stg.TRANSACTION_HK = tgt.TRANSACTION_HK
            WHERE tgt.TRANSACTION_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "MS SQL Server"

    === "Base Load"
    
        ```sql
        WITH stage AS (
            SELECT TRANSACTION_HK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM AUTOMATE_DV.TEST.MY_STAGE
            WHERE TRANSACTION_HK IS NOT NULL
            AND CUSTOMER_FK IS NOT NULL
        ),

        records_to_insert AS (
            SELECT DISTINCT stg.TRANSACTION_HK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH stage AS (
            SELECT TRANSACTION_HK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM AUTOMATE_DV.TEST.raw_stage_hashed
            WHERE TRANSACTION_HK IS NOT NULL
            AND CUSTOMER_FK IS NOT NULL
        ),

        records_to_insert AS (
            SELECT DISTINCT stg.TRANSACTION_HK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
            LEFT JOIN AUTOMATE_DV.TEST.t_link AS tgt
            ON stg.TRANSACTION_HK = tgt.TRANSACTION_HK
            WHERE tgt.TRANSACTION_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

___

### sat

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/snowflake/sat.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/bigquery/sat.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/sqlserver/sat.sql)
[![Databricks](../assets/images/platform_icons/databricks.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/databricks/sat.sql)
[![Postgres](../assets/images/platform_icons/postgres.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/postgres/sat.sql)

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
| src_pk            | Source primary key column                   | String              | :fontawesome-solid-circle-check:{ .required }     |
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

#### Example Metadata

[See examples](../metadata.md#satellites)

#### Example Output

=== "Snowflake"

    === "Base Load"
    
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM AUTOMATE_DV.TEST.MY_STAGE AS a
            WHERE CUSTOMER_HK IS NOT NULL
        ),

        records_to_insert AS (
            SELECT DISTINCT e.CUSTOMER_HK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
        )

        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM AUTOMATE_DV.TEST.MY_STAGE AS a
            WHERE CUSTOMER_HK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT c.CUSTOMER_HK, c.HASHDIFF, c.LOAD_DATE
            FROM (
                SELECT current_records.CUSTOMER_HK, current_records.HASHDIFF, current_records.LOAD_DATE,
                RANK() OVER (
                    PARTITION BY c.CUSTOMER_HK
                    ORDER BY c.LOAD_DATE DESC
                ) AS rank
            FROM AUTOMATE_DV.TEST.SATELLITE AS c
            JOIN (
                SELECT DISTINCT source_data.CUSTOMER_PK
                FROM source_data
            ) AS source_records
                ON c.CUSTOMER_PK = source_records.CUSTOMER_PK
            QUALIFY rank = 1
        ),
        
        records_to_insert AS (
            SELECT DISTINCT e.CUSTOMER_HK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
            LEFT JOIN latest_records
                ON latest_records.CUSTOMER_HK = e.CUSTOMER_HK
            WHERE latest_records.HASHDIFF != e.HASHDIFF
                OR latest_records.HASHDIFF IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Base Load with Ghost Record"

        ```sql
        WITH source_data AS (
            SELECT a."CUSTOMER_HK", a."HASHDIFF", a."CUSTOMER_NAME", a."CUSTOMER_PHONE", a."CUSTOMER_DOB", a."EFFECTIVE_FROM", a."LOAD_DATE", a."SOURCE"
            FROM AUTOMATE_DV.TEST.MY_STAGE AS a
            WHERE a."CUSTOMER_PK" IS NOT NULL
        ),

        ghost AS (SELECT
            NULL AS "CUSTOMER_NAME",
            NULL AS "CUSTOMER_DOB",
            NULL AS "CUSTOMER_PHONE",
            TO_DATE('1900-01-01 00:00:00') AS "LOAD_DATE",
            CAST('AUTOMATE_DV_SYSTEM' AS VARCHAR) AS "SOURCE",
            TO_DATE('1900-01-01 00:00:00') AS "EFFECTIVE_FROM",
            CAST('00000000000000000000000000000000' AS BINARY(16)) AS "CUSTOMER_HK",
            CAST('00000000000000000000000000000000' AS BINARY(16)) AS "HASHDIFF"
        ),

        records_to_insert AS (SELECT
                g."CUSTOMER_HK", g."HASHDIFF", g."CUSTOMER_NAME", g."CUSTOMER_PHONE", g."CUSTOMER_DOB", g."EFFECTIVE_FROM", g."LOAD_DATE", g."SOURCE"
                FROM ghost AS g
            UNION
            SELECT DISTINCT stage."CUSTOMER_PK", stage."HASHDIFF", stage."CUSTOMER_NAME", stage."CUSTOMER_PHONE", stage."CUSTOMER_DOB", stage."EFFECTIVE_FROM", stage."LOAD_DATE", stage."SOURCE"
            FROM source_data AS stage
        )

        SELECT * FROM records_to_insert
        ```

    === "Subsequent Loads with Ghost Record"

        ```sql
        WITH source_data AS (
            SELECT a."CUSTOMER_HK", a."HASHDIFF", a."CUSTOMER_NAME", a."CUSTOMER_DOB", a."CUSTOMER_PHONE", a."EFFECTIVE_FROM", a."LOAD_DATE", a."SOURCE"
            FROM AUTOMATE_DV.TEST.MY_STAGE AS a
            WHERE a."CUSTOMER_PK" IS NOT NULL
        ),

        latest_records AS (
            SELECT a."CUSTOMER_HK", a."HASHDIFF", a."LOAD_DATE"
            FROM (
                SELECT current_records."CUSTOMER_HK", current_records."HASHDIFF", current_records."LOAD_DATE",
                    RANK() OVER (
                       PARTITION BY current_records."CUSTOMER_HK"
                       ORDER BY current_records."LOAD_DATE" DESC
                    ) AS rank
                FROM AUTOMATE_DV.TEST.SATELLITE AS current_records
                    JOIN (
                        SELECT DISTINCT source_data."CUSTOMER_HK"
                        FROM source_data
                    ) AS source_records
                        ON current_records."CUSTOMER_HK" = source_records."CUSTOMER_HK"
            ) AS a
            WHERE a.rank = 1
        ),

        ghost AS (SELECT
            NULL AS "CUSTOMER_NAME",
            NULL AS "CUSTOMER_DOB",
            NULL AS "CUSTOMER_PHONE",
            TO_DATE('1900-01-01 00:00:00') AS "LOAD_DATE",
            CAST('AUTOMATE_DV_SYSTEM' AS VARCHAR) AS "SOURCE",
            TO_DATE('1900-01-01 00:00:00') AS "EFFECTIVE_FROM",
            CAST('00000000000000000000000000000000' AS BINARY(16)) AS "CUSTOMER_HK",
            CAST('00000000000000000000000000000000' AS BINARY(16)) AS "HASHDIFF"
        ),
        
        records_to_insert AS (SELECT
                g."CUSTOMER_HK", g."HASHDIFF", g."CUSTOMER_NAME", g."CUSTOMER_DOB", g."CUSTOMER_PHONE", g."EFFECTIVE_FROM", g."LOAD_DATE", g."SOURCE"
                FROM ghost AS g
                WHERE NOT EXISTS ( SELECT 1 FROM DBTVAULT.TEST.SATELLITE AS h WHERE h."HASHDIFF" = g."HASHDIFF" )
            UNION
            SELECT DISTINCT stage."CUSTOMER_HK", stage."HASHDIFF", stage."CUSTOMER_NAME", stage."CUSTOMER_DOB", stage."CUSTOMER_PHONE", stage."EFFECTIVE_FROM", stage."LOAD_DATE", stage."SOURCE"
            FROM source_data AS stage
            LEFT JOIN latest_records
            ON latest_records."CUSTOMER_HK" = stage."CUSTOMER_HK"
                AND latest_records."HASHDIFF" = stage."HASHDIFF"
            WHERE latest_records."HASHDIFF" IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```
=== "Google BigQuery"

    === "Base Load"
    
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.MY_STAGE AS a
            WHERE CUSTOMER_HK IS NOT NULL
        ),

        records_to_insert AS (
            SELECT DISTINCT e.CUSTOMER_HK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
        )

        SELECT * FROM records_to_insert
        ```

    === "Subsequent Loads"

        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.MY_STAGE AS a
            WHERE CUSTOMER_HK IS NOT NULL
        ),

        latest_records AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.LOAD_DATE
            FROM (
                SELECT c.CUSTOMER_HK, c.HASHDIFF, c.LOAD_DATE, 
                RANK() OVER (
                PARTITION BY c.CUSTOMER_HK
                ORDER BY c.LOAD_DATE DESC
                ) AS rank
                FROM DBTVAULT.TEST.SATELLITE AS c
                JOIN (  
                SELECT DISTICT source_data.CUSTOMER_HK
                FROM source_data
                ) AS source_records
                ON c.CUSTOMER_HK = source_records.CUSTOMER_HK
                ) AS a
            WHERE a.rank = 1
        ),

        records_to_insert AS (
            SELECT DISTICT e.CUSTOMER_HK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
            LEFT JOIN latest_records
            ON latest_recods.CUSTOMER_HK = e.CUSTOMER_HK
            WHERE latest_records.HASHDIFF != e.HASHDIFF
            OR latest_records.HASHDIFF IS NULL
        )

        SELECT * FROM records_to_insert
        ```

    === "Base Load with Ghost Record"
        ```sql
        WITH source_data AS (
            SELECT a.`CUSTOMER_HK`, a.`HASHDIFF`, a.`CUSTOMER_NAME`, a.`CUSTOMER_DOB`, a.`CUSTOMER_PHONE`, a.`EFFECTIVE_FROM`, a.`LOAD_DATE`, a.`SOURCE`
            FROM `DBTVAULT`.`TEST`.`MY_STAGE` AS a
            WHERE a.`CUSTOMER_PK` IS NOT NULL
        ),
        
        ghost AS (SELECT
            CAST(NULL AS STRING) AS `CUSTOMER_NAME`,
            CAST(NULL AS DATE) AS `CUSTOMER_DOB`,
            CAST(NULL AS STRING) AS `CUSTOMER_PHONE`,
            CAST('1900-01-01' AS DATE) AS `LOAD_DATE`,
            CAST('DBTVAULT_SYSTEM' AS STRING) AS `SOURCE`,
            CAST('1900-01-01' AS DATE) AS `EFFECTIVE_FROM`,
            CAST('00000000000000000000000000000000' AS STRING) AS `CUSTOMER_HK`,
            CAST('00000000000000000000000000000000' AS STRING) AS `HASHDIFF`
        ),
        
        records_to_insert AS (SELECT
                g.`CUSTOMER_HK`, g.`HASHDIFF`, g.`CUSTOMER_NAME`, g.`CUSTOMER_DOB`, g.`CUSTOMER_PHONE`, g.`EFFECTIVE_FROM`, g.`LOAD_DATE`, g.`SOURCE`
                FROM ghost AS g
            UNION DISTINCT
            SELECT DISTINCT stage.`CUSTOMER_HK`, stage.`HASHDIFF`, stage.`CUSTOMER_NAME`, stage.`CUSTOMER_DOB`, stage.`CUSTOMER_PHONE`, stage.`EFFECTIVE_FROM`, stage.`LOAD_DATE`, stage.`SOURCE`
            FROM source_data AS stage
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Subsequent Load with Ghost Record"
        ```sql
        WITH source_data AS (
            SELECT a.`CUSTOMER_HK`, a.`HASHDIFF`, a.`CUSTOMER_NAME`, a.`CUSTOMER_DOB`, a.`CUSTOMER_PHONE`, a.`EFFECTIVE_FROM`, a.`LOAD_DATE`, a.`SOURCE`
            FROM `DBTVAULT`.`TEST`.`MY_STAGE` AS a
            WHERE a.`CUSTOMER_PK` IS NOT NULL
        ),
        
        latest_records AS (
            SELECT a.`CUSTOMER_HK`, a.`HASHDIFF`, a.`LOAD_DATE`
            FROM (
                SELECT current_records.`CUSTOMER_HK`, current_records.`HASHDIFF`, current_records.`LOAD_DATE`,
                    RANK() OVER (
                       PARTITION BY current_records.`CUSTOMER_HK`
                       ORDER BY current_records.`LOAD_DATE` DESC
                    ) AS rank
                FROM `DBTVAULT`.`TEST`.`SATELLITE` AS current_records
                    JOIN (
                        SELECT DISTINCT source_data.`CUSTOMER_HK`
                        FROM source_data
                    ) AS source_records
                        ON current_records.`CUSTOMER_HK` = source_records.`CUSTOMER_HK`
            ) AS a
            WHERE a.rank = 1
        ),

        ghost AS (SELECT
            CAST(NULL AS STRING) AS `CUSTOMER_NAME`,
            CAST(NULL AS DATE) AS `CUSTOMER_DOB`,
            CAST(NULL AS STRING) AS `CUSTOMER_PHONE`,
            CAST('1900-01-01' AS DATE) AS `LOAD_DATE`,
            CAST('DBTVAULT_SYSTEM' AS STRING) AS `SOURCE`,
            CAST('1900-01-01' AS DATE) AS `EFFECTIVE_FROM`,
            CAST('00000000000000000000000000000000' AS STRING) AS `CUSTOMER_HK`,
            CAST('00000000000000000000000000000000' AS STRING) AS `HASHDIFF`
        ),
        
        records_to_insert AS (SELECT
                g.`CUSTOMER_HK`, g.`HASHDIFF`, g.`CUSTOMER_NAME`, g.`CUSTOMER_DOB`, g.`CUSTOMER_PHONE`, g.`EFFECTIVE_FROM`, g.`LOAD_DATE`, g.`SOURCE`
                FROM ghost AS g
                WHERE NOT EXISTS ( SELECT 1 FROM `DBTVAULT`.`TEST`.`SATELLITE` AS h WHERE h.`HASHDIFF` = g.`HASHDIFF` )
            UNION DISTINCT
            SELECT DISTINCT stage.`CUSTOMER_HK`, stage.`HASHDIFF`, stage.`CUSTOMER_NAME`, stage.`CUSTOMER_DOB`, stage.`CUSTOMER_PHONE`, stage.`EFFECTIVE_FROM`, stage.`LOAD_DATE`, stage.`SOURCE`
            FROM source_data AS stage
            LEFT JOIN latest_records
            ON latest_records.`CUSTOMER_HK` = stage.`CUSTOMER_HK`
                AND latest_records.`HASHDIFF` = stage.`HASHDIFF`
            WHERE latest_records.`HASHDIFF` IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "MS SQL Server"

    === "Base Load"
    
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.MY_STAGE AS a
            WHERE CUSTOMER_HK IS NOT NULL
        ),

        records_to_insert AS (
            SELECT DISTINCT e.CUSTOMER_HK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
        )

        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.MY_STAGE AS a
            WHERE CUSTOMER_HK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT a.CUSTOMER_PK, a.HASHDIFF, a.LOAD_DATE
            FROM
            (
                SELECT current_records.CUSTOMER_PK, current_records.HASHDIFF, current_records.LOAD_DATE,
                    RANK() OVER (
                       PARTITION BY current_records.CUSTOMER_PK
                       ORDER BY current_records.LOAD_DATE DESC
                    ) AS rank
                FROM DBTVAULT_DEV.TEST.SATELLITE AS current_records
                JOIN (
                    SELECT DISTINCT source_data.CUSTOMER_PK
                    FROM source_data
                ) AS source_records
                ON current_records.CUSTOMER_PK = source_records.CUSTOMER_PK
            ) AS a
            WHERE a.rank = 1
        ),

        records_to_insert AS (
            SELECT DISTINCT e.CUSTOMER_HK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
            LEFT JOIN latest_records
            ON latest_records.CUSTOMER_HK = e.CUSTOMER_HK
            WHERE latest_records.HASHDIFF != e.HASHDIFF
                OR latest_records.HASHDIFF IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```
    === "Base Load with Ghost Record"
    
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.MY_STAGE AS a
            WHERE CUSTOMER_HK IS NOT NULL
        ),

        ghost AS (SELECT
            NULL AS CUSTOMER_NAME,
            NULL AS CUSTOMER_DOB,
            NULL AS CUSTOMER_PHONE,
            CAST('1900-01-01' AS DATE) AS LOAD_DATE,
            CAST('DBTVAULT_SYSTEM' AS VARCHAR(50)) AS SOURCE,
            CAST('1900-01-01' AS DATE) AS EFFECTIVE_FROM,
            CAST('00000000000000000000000000000000' AS BINARY(16)) AS CUSTOMER_HK,
            CAST('00000000000000000000000000000000' AS BINARY(16)) AS HASHDIFF
        ),

        records_to_insert AS (
            SELECT g.CUSTOMER_HK, g.HASHDIFF, g.CUSTOMER_NAME, g.CUSTOMER_PHONE, g.CUSTOMER_DOB, g.EFFECTIVE_FROM, g.LOAD_DATE, g.SOURCE
            FROM ghost AS g
            UNION
            SELECT DISTINCT e.CUSTOMER_HK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
        )

        SELECT * FROM records_to_insert
        ```

    === "Subsequent Loads"
        
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.MY_STAGE AS a
            WHERE CUSTOMER_HK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT a.CUSTOMER_PK, a.HASHDIFF, a.LOAD_DATE
            FROM
            (
                SELECT current_records.CUSTOMER_PK, current_records.HASHDIFF, current_records.LOAD_DATE,
                    RANK() OVER (
                       PARTITION BY current_records.CUSTOMER_PK
                       ORDER BY current_records.LOAD_DATE DESC
                    ) AS rank
                FROM DBTVAULT_DEV.TEST.SATELLITE AS current_records
                JOIN (
                    SELECT DISTINCT source_data.CUSTOMER_PK
                    FROM source_data
                ) AS source_records
                ON current_records.CUSTOMER_PK = source_records.CUSTOMER_PK
            ) AS a
            WHERE a.rank = 1
        ),

        ghost AS (SELECT
            NULL AS CUSTOMER_NAME,
            NULL AS CUSTOMER_DOB,
            NULL AS CUSTOMER_PHONE,
            CAST('1900-01-01' AS DATE) AS LOAD_DATE,
            CAST('DBTVAULT_SYSTEM' AS VARCHAR(50)) AS SOURCE,
            CAST('1900-01-01' AS DATE) AS EFFECTIVE_FROM,
            CAST('00000000000000000000000000000000' AS BINARY(16)) AS CUSTOMER_HK,
            CAST('00000000000000000000000000000000' AS BINARY(16)) AS HASHDIFF
        ),

        records_to_insert AS (SELECT
                g.CUSTOMER_HK, g.HASHDIFF, g.CUSTOMER_NAME, g.CUSTOMER_DOB, g.CUSTOMER_PHONE, g.EFFECTIVE_FROM, g.LOAD_DATE, g.SOURCE
                FROM ghost AS g
                WHERE NOT EXISTS ( SELECT 1 FROM DBTVAULT.TEST.SATELLITE AS h WHERE h."HASHDIFF" = g."HASHDIFF" )
            UNION
            SELECT DISTINCT e.CUSTOMER_HK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
            LEFT JOIN latest_records
            ON latest_records.CUSTOMER_HK = e.CUSTOMER_HK
            WHERE latest_records.HASHDIFF != e.HASHDIFF
                OR latest_records.HASHDIFF IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

#### Ghost records

Ghost Records are system-generated records which are added to Satellites to provide equi-join performance in PIT tables
downstream. AutomateDV will generate ghost records if the [global variable](#ghost-record-configuration) is set to `true`.

!!! tip "New in v0.9.1"
    Ghost Records are here! More details (including examples of how it works) coming soon!

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

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/snowflake/eff_sat.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/bigquery/eff_sat.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/sqlserver/eff_sat.sql)

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
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_HK, a.ORDER_HK, a.CUSTOMER_HK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_HK IS NOT NULL
            AND a.CUSTOMER_HK IS NOT NULL
        ),
        
        records_to_insert AS (
            SELECT i.ORDER_CUSTOMER_HK, i.ORDER_HK, i.CUSTOMER_HK, i.START_DATE, i.END_DATE, i.EFFECTIVE_FROM, i.LOAD_DATETIME, i.SOURCE
            FROM source_data AS i
        )
        
        SELECT * FROM records_to_insert
        ```

    === "With auto end-dating (Subsequent)"

        ```sql
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_HK, a.ORDER_HK, a.CUSTOMER_HK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_HK IS NOT NULL
            AND a.CUSTOMER_HK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT b.ORDER_CUSTOMER_HK, b.ORDER_HK, b.CUSTOMER_HK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATETIME, b.SOURCE,
                ROW_NUMBER() OVER (
                    PARTITION BY b.ORDER_CUSTOMER_HK
                    ORDER BY b.LOAD_DATETIME DESC
                ) AS row_num
            FROM DBTVAULT.TEST.EFF_SAT_ORDER_CUSTOMER AS b
            QUALIFY row_num = 1
        ),
        
        latest_open AS (
            SELECT c.ORDER_CUSTOMER_HK, c.ORDER_HK, c.CUSTOMER_HK, c.START_DATE, c.END_DATE, c.EFFECTIVE_FROM, c.LOAD_DATETIME, c.SOURCE
            FROM latest_records AS c
            WHERE TO_DATE(c.END_DATE) = TO_DATE('9999-12-31 23:59:59.999999')
        ),
        
        latest_closed AS (
            SELECT d.ORDER_CUSTOMER_HK, d.ORDER_HK, d.CUSTOMER_HK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.SOURCE
            FROM latest_records AS d
            WHERE TO_DATE(d.END_DATE) != TO_DATE('9999-12-31 23:59:59.999999')
        ),
        
        new_open_records AS (
            SELECT DISTINCT
                f.ORDER_CUSTOMER_HK, f.ORDER_HK, f.CUSTOMER_HK, f.START_DATE, f.END_DATE, f.EFFECTIVE_FROM, f.LOAD_DATETIME, f.SOURCE
            FROM source_data AS f
            LEFT JOIN latest_records AS lr
            ON f.ORDER_CUSTOMER_HK = lr.ORDER_CUSTOMER_HK
            WHERE lr.ORDER_CUSTOMER_HK IS NULL
        ),
        
        new_reopened_records AS (
            SELECT DISTINCT
                lc.ORDER_CUSTOMER_HK,
                lc.ORDER_HK, lc.CUSTOMER_HK,
                g.EFFECTIVE_FROM AS START_DATE,
                g.END_DATE AS END_DATE,
                g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                g.LOAD_DATETIME,
                g.SOURCE
            FROM source_data AS g
            INNER JOIN latest_closed lc
            ON g.ORDER_CUSTOMER_HK = lc.ORDER_CUSTOMER_HK
            WHERE TO_DATE(g.END_DATE) = TO_DATE('9999-12-31 23:59:59.999999')
        ),
        
        new_closed_records AS (
            SELECT DISTINCT
                lo.ORDER_CUSTOMER_HK,
                lo.ORDER_HK, lo.CUSTOMER_HK,
                lo.START_DATE AS START_DATE,
                h.EFFECTIVE_FROM AS END_DATE,
                h.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                h.LOAD_DATETIME,
                lo.SOURCE
            FROM source_data AS h
            INNER JOIN latest_open AS lo
            ON lo.ORDER_HK = h.ORDER_HK
            WHERE (lo.CUSTOMER_HK <> h.CUSTOMER_HK)
        ),
        
        records_to_insert AS (
            SELECT * FROM new_open_records
            UNION
            SELECT * FROM new_reopened_records
            UNION
            SELECT * FROM new_closed_records
        )
        
        SELECT * FROM records_to_insert
        ```
        
    === "Without auto end-dating (Subsequent)"   
        
        ```sql
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_HK, a.ORDER_HK, a.CUSTOMER_HK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_HK IS NOT NULL
            AND a.CUSTOMER_HK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT b.ORDER_CUSTOMER_HK, b.ORDER_HK, b.CUSTOMER_HK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATETIME, b.SOURCE,
                ROW_NUMBER() OVER (
                    PARTITION BY b.ORDER_CUSTOMER_HK
                    ORDER BY b.LOAD_DATETIME DESC
                ) AS row_num
            FROM DBTVAULT.TEST.EFF_SAT_ORDER_CUSTOMER AS b
            QUALIFY row_num = 1
        ),
        
        latest_open AS (
            SELECT c.ORDER_CUSTOMER_HK, c.ORDER_HK, c.CUSTOMER_HK, c.START_DATE, c.END_DATE, c.EFFECTIVE_FROM, c.LOAD_DATETIME, c.SOURCE
            FROM latest_records AS c
            WHERE TO_DATE(c.END_DATE) = TO_DATE('9999-12-31 23:59:59.999999')
        ),
        
        latest_closed AS (
            SELECT d.ORDER_CUSTOMER_HK, d.ORDER_HK, d.CUSTOMER_HK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.SOURCE
            FROM latest_records AS d
            WHERE TO_DATE(d.END_DATE) != TO_DATE('9999-12-31 23:59:59.999999')
        ),
        
        new_open_records AS (
            SELECT DISTINCT
                f.ORDER_CUSTOMER_HK, f.ORDER_HK, f.CUSTOMER_HK, f.START_DATE, f.END_DATE, f.EFFECTIVE_FROM, f.LOAD_DATETIME, f.SOURCE
            FROM source_data AS f
            LEFT JOIN latest_records AS lr
            ON f.ORDER_CUSTOMER_HK = lr.ORDER_CUSTOMER_HK
            WHERE lr.ORDER_CUSTOMER_HK IS NULL
        ),
        
        new_reopened_records AS (
            SELECT DISTINCT
                lc.ORDER_CUSTOMER_HK,
                lc.ORDER_HK, lc.CUSTOMER_HK,
                g.START_DATE AS START_DATE,
                g.END_DATE AS END_DATE,
                g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                g.LOAD_DATETIME,
                g.SOURCE
            FROM source_data AS g
            INNER JOIN latest_closed lc
            ON g.ORDER_CUSTOMER_HK = lc.ORDER_CUSTOMER_HK
            WHERE TO_DATE(g.END_DATE) = TO_DATE('9999-12-31 23:59:59.999999')
        ),
        
        new_closed_records AS (
            SELECT DISTINCT
                lo.ORDER_CUSTOMER_HK,
                lo.ORDER_HK, lo.CUSTOMER_HK,
                h.START_DATE AS START_DATE,
                h.EFFECTIVE_FROM AS END_DATE,
                h.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                h.LOAD_DATETIME,
                lo.SOURCE
            FROM source_data AS h
            LEFT JOIN Latest_open AS lo
            ON lo.ORDER_CUSTOMER_HK = h.ORDER_CUSTOMER_HK
            LEFT JOIN latest_closed AS lc
            ON lc.ORDER_CUSTOMER_HK = h.ORDER_CUSTOMER_HK
            WHERE TO_DATE(h.END_DATE) != TO_DATE('9999-12-31 23:59:59.999999')
            AND lo.ORDER_CUSTOMER_HK IS NOT NULL
            AND lc.ORDER_CUSTOMER_HK IS NULL
        ),

        records_to_insert AS (
            SELECT * FROM new_open_records
            UNION
            SELECT * FROM new_reopened_records
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google BigQuery"

    === "Base Load"

        ```sql
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_HK, a.ORDER_HK, a.CUSTOMER_HK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_HK IS NOT NULL
            AND a.CUSTOMER_HK IS NOT NULL
        ),
        
        records_to_insert AS (
            SELECT i.ORDER_CUSTOMER_HK, i.ORDER_HK, i.CUSTOMER_HK, i.START_DATE, i.END_DATE, i.EFFECTIVE_FROM, i.LOAD_DATETIME, i.SOURCE
            FROM source_data AS i
        )
        
        SELECT * FROM records_to_insert
        ```

    === "With auto end-dating (Subsequent)"

        ```sql
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_HK, a.ORDER_HK, a.CUSTOMER_HK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_HK IS NOT NULL
            AND a.CUSTOMER_HK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT b.ORDER_CUSTOMER_HK, b.ORDER_HK, b.CUSTOMER_HK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATETIME, b.SOURCE,
                ROW_NUMBER() OVER (
                    PARTITION BY b.ORDER_CUSTOMER_HK
                    ORDER BY b.LOAD_DATETIME DESC
                ) AS row_num
            FROM DBTVAULT.TEST.EFF_SAT_ORDER_CUSTOMER AS b
            WHERE b.ORDER_HK IS NOT NULL
            QUALIFY row_num = 1
        ),
        
        latest_open AS (
            SELECT c.ORDER_CUSTOMER_HK, c.ORDER_HK, c.CUSTOMER_HK, c.START_DATE, c.END_DATE, c.EFFECTIVE_FROM, c.LOAD_DATETIME, c.SOURCE
            FROM latest_records AS c
            WHERE DATE(c.END_DATE) = DATE('9999-12-31 23:59:59.999')
        ),
        
        latest_closed AS (
            SELECT d.ORDER_CUSTOMER_HK, d.ORDER_HK, d.CUSTOMER_HK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.SOURCE
            FROM latest_records AS d
            WHERE DATE(d.END_DATE) != DATE('9999-12-31 23:59:59.999')
        ),
        
        new_open_records AS (
            SELECT DISTINCT
                f.ORDER_CUSTOMER_HK, f.ORDER_HK, f.CUSTOMER_HK, f.START_DATE, f.END_DATE, f.EFFECTIVE_FROM, f.LOAD_DATETIME, f.SOURCE
            FROM source_data AS f
            LEFT JOIN latest_records AS lr
            ON f.ORDER_CUSTOMER_HK = lr.ORDER_CUSTOMER_HK
            WHERE lr.ORDER_CUSTOMER_HK IS NULL
        ),
        
        new_reopened_records AS (
            SELECT DISTINCT
                lc.ORDER_CUSTOMER_HK,
                lc.ORDER_HK, lc.CUSTOMER_HK,
                g.EFFECTIVE_FROM AS START_DATE,
                g.END_DATE AS END_DATE,
                g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                g.LOAD_DATETIME,
                g.SOURCE
            FROM source_data AS g
            INNER JOIN latest_closed lc
            ON g.ORDER_CUSTOMER_HK = lc.ORDER_CUSTOMER_HK
            WHERE DATE(g.END_DATE) = DATE('9999-12-31 23:59:59.999')
        ),
        
        new_closed_records AS (
            SELECT DISTINCT
                lo.ORDER_CUSTOMER_HK,
                lo.ORDER_HK, lo.CUSTOMER_HK,
                lo.START_DATE AS START_DATE,
                h.EFFECTIVE_FROM AS END_DATE,
                h.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                h.LOAD_DATETIME,
                lo.SOURCE
            FROM source_data AS h
            INNER JOIN latest_open AS lo
            ON lo.ORDER_HK = h.ORDER_HK
            WHERE (lo.CUSTOMER_HK <> h.CUSTOMER_HK)
        ),
        
        records_to_insert AS (
            SELECT * FROM new_open_records
            UNION DISTINCT
            SELECT * FROM new_reopened_records
            UNION DISTINCT
            SELECT * FROM new_closed_records
        )
        
        SELECT * FROM records_to_insert
        ```
        
    === "Without auto end-dating (Subsequent)"   
        
        ```sql
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_HK, a.ORDER_HK, a.CUSTOMER_HK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_HK IS NOT NULL
            AND a.CUSTOMER_HK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT b.ORDER_CUSTOMER_HK, b.ORDER_HK, b.CUSTOMER_HK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATETIME, b.SOURCE,
                ROW_NUMBER() OVER (
                    PARTITION BY b.ORDER_CUSTOMER_HK
                    ORDER BY b.LOAD_DATETIME DESC
                ) AS row_num
            FROM DBTVAULT.TEST.EFF_SAT_ORDER_CUSTOMER AS b
            WHERE b.ORDER_HK IS NOT NULL
            QUALIFY row_num = 1
        ),
        
        latest_open AS (
            SELECT c.ORDER_CUSTOMER_HK, c.ORDER_HK, c.CUSTOMER_HK, c.START_DATE, c.END_DATE, c.EFFECTIVE_FROM, c.LOAD_DATETIME, c.SOURCE
            FROM latest_records AS c
            WHERE DATE(c.END_DATE) = DATE('9999-12-31 23:59:59.999')
        ),
        
        latest_closed AS (
            SELECT d.ORDER_CUSTOMER_HK, d.ORDER_HK, d.CUSTOMER_HK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.SOURCE
            FROM latest_records AS d
            WHERE DATE(d.END_DATE) != DATE('9999-12-31 23:59:59.999')
        ),
        
        new_open_records AS (
            SELECT DISTINCT
                f.ORDER_CUSTOMER_HK, f.ORDER_HK, f.CUSTOMER_HK, f.START_DATE, f.END_DATE, f.EFFECTIVE_FROM, f.LOAD_DATETIME, f.SOURCE
            FROM source_data AS f
            LEFT JOIN latest_records AS lr
            ON f.ORDER_CUSTOMER_HK = lr.ORDER_CUSTOMER_HK
            WHERE lr.ORDER_CUSTOMER_HK IS NULL
        ),
        
        new_reopened_records AS (
            SELECT DISTINCT
                lc.ORDER_CUSTOMER_HK,
                lc.ORDER_HK, lc.CUSTOMER_HK,
                g.START_DATE AS START_DATE,
                g.END_DATE AS END_DATE,
                g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                g.LOAD_DATETIME,
                g.SOURCE
            FROM source_data AS g
            INNER JOIN latest_closed lc
            ON g.ORDER_CUSTOMER_HK = lc.ORDER_CUSTOMER_HK
            WHERE DATE(g.END_DATE) = DATE('9999-12-31 23:59:59.999')
        ),
        
        new_closed_records AS (
            SELECT DISTINCT
                lo.ORDER_CUSTOMER_HK,
                lo.ORDER_HK, lo.CUSTOMER_HK,
                h.START_DATE AS START_DATE,
                h.EFFECTIVE_FROM AS END_DATE,
                h.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                h.LOAD_DATETIME,
                lo.SOURCE
            FROM source_data AS h
            LEFT JOIN Latest_open AS lo
            ON lo.ORDER_CUSTOMER_HK = h.ORDER_CUSTOMER_HK
            LEFT JOIN latest_closed AS lc
            ON lc.ORDER_CUSTOMER_HK = h.ORDER_CUSTOMER_HK
            WHERE DATE(h.END_DATE) != DATE('9999-12-31 23:59:59.999')
            AND lo.ORDER_CUSTOMER_HK IS NOT NULL
            AND lc.ORDER_CUSTOMER_HK IS NULL
        ),

        records_to_insert AS (
            SELECT * FROM new_open_records
            UNION DISTINCT
            SELECT * FROM new_reopened_records
            UNION DISTINCT
            SELECT * FROM new_closed_records
        )
        
        SELECT * FROM records_to_insert
        ```

=== "MS SQL Server"

    === "Base Load"

        ```sql
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_HK, a.ORDER_HK, a.CUSTOMER_HK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_HK IS NOT NULL
            AND a.CUSTOMER_HK IS NOT NULL
        ),
        
        records_to_insert AS (
            SELECT i.ORDER_CUSTOMER_HK, i.ORDER_HK, i.CUSTOMER_HK, i.START_DATE, i.END_DATE, i.EFFECTIVE_FROM, i.LOAD_DATETIME, i.SOURCE
            FROM source_data AS i
        )
        
        SELECT * FROM records_to_insert
        ```

    === "With auto end-dating (Subsequent)"

        ```sql
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_HK, a.ORDER_HK, a.CUSTOMER_HK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_HK IS NOT NULL
            AND a.CUSTOMER_HK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT *
            FROM
            (
                SELECT b.ORDER_CUSTOMER_HK, b.ORDER_HK, b.CUSTOMER_HK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATETIME, b.SOURCE,
                    ROW_NUMBER() OVER (
                        PARTITION BY b.ORDER_CUSTOMER_HK
                        ORDER BY b.LOAD_DATETIME DESC
                    ) AS row_num
                FROM DBTVAULT.TEST.EFF_SAT_ORDER_CUSTOMER AS b
            ) l
            WHERE l.row_num = 1
        ),
        
        latest_open AS (
            SELECT c.ORDER_CUSTOMER_HK, c.ORDER_HK, c.CUSTOMER_HK, c.START_DATE, c.END_DATE, c.EFFECTIVE_FROM, c.LOAD_DATETIME, c.SOURCE
            FROM latest_records AS c
            WHERE CONVERT(DATE, c.END_DATE) = CONVERT(DATE, '9999-12-31 23:59:59.9999999')
        ),
        
        latest_closed AS (
            SELECT d.ORDER_CUSTOMER_HK, d.ORDER_HK, d.CUSTOMER_HK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.SOURCE
            FROM latest_records AS d
            WHERE CONVERT(DATE, d.END_DATE) != CONVERT(DATE, '9999-12-31 23:59:59.9999999')
        ),
        
        new_open_records AS (
            SELECT DISTINCT
                f.ORDER_CUSTOMER_HK, f.ORDER_HK, f.CUSTOMER_HK, f.START_DATE, f.END_DATE, f.EFFECTIVE_FROM, f.LOAD_DATETIME, f.SOURCE
            FROM source_data AS f
            LEFT JOIN latest_records AS lr
            ON f.ORDER_CUSTOMER_HK = lr.ORDER_CUSTOMER_HK
            WHERE lr.ORDER_CUSTOMER_HK IS NULL
        ),
        
        new_reopened_records AS (
            SELECT DISTINCT
                lc.ORDER_CUSTOMER_HK,
                lc.ORDER_HK, lc.CUSTOMER_HK,
                g.EFFECTIVE_FROM AS START_DATE,
                g.END_DATE AS END_DATE,
                g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                g.LOAD_DATETIME,
                g.SOURCE
            FROM source_data AS g
            INNER JOIN latest_closed lc
            ON g.ORDER_CUSTOMER_HK = lc.ORDER_CUSTOMER_HK
            WHERE CAST((g."END_DATE") AS DATE) = CAST(('9999-12-31 23:59:59.9999999') AS DATE)
        ),
        
        new_closed_records AS (
            SELECT DISTINCT
                lo.ORDER_CUSTOMER_HK,
                lo.ORDER_HK, lo.CUSTOMER_HK,
                lo.START_DATE AS START_DATE,
                h.EFFECTIVE_FROM AS END_DATE,
                h.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                h.LOAD_DATETIME,
                lo.SOURCE
            FROM source_data AS h
            INNER JOIN latest_open AS lo
            ON lo.ORDER_HK = h.ORDER_HK
            WHERE (lo.CUSTOMER_HK <> h.CUSTOMER_HK)
        ),
        
        records_to_insert AS (
            SELECT * FROM new_open_records
            UNION
            SELECT * FROM new_reopened_records
            UNION
            SELECT * FROM new_closed_records
        )
        
        SELECT * FROM records_to_insert
        ```
        
    === "Without auto end-dating (Subsequent)"   
        
        ```sql
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_HK, a.ORDER_HK, a.CUSTOMER_HK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_HK IS NOT NULL
            AND a.CUSTOMER_HK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT *
            FROM
            (
                SELECT b.ORDER_CUSTOMER_HK, b.ORDER_HK, b.CUSTOMER_HK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATETIME, b.SOURCE,
                    ROW_NUMBER() OVER (
                        PARTITION BY b.ORDER_CUSTOMER_HK
                        ORDER BY b.LOAD_DATETIME DESC
                    ) AS row_num
                FROM DBTVAULT.TEST.EFF_SAT_ORDER_CUSTOMER AS b
            ) l
            WHERE l.row_num = 1
        ),
        
        latest_open AS (
            SELECT c.ORDER_CUSTOMER_HK, c.ORDER_HK, c.CUSTOMER_HK, c.START_DATE, c.END_DATE, c.EFFECTIVE_FROM, c.LOAD_DATETIME, c.SOURCE
            FROM latest_records AS c
            WHERE CONVERT(DATE, c.END_DATE) = CONVERT(DATE, '9999-12-31 23:59:59.9999999')
        ),
        
        latest_closed AS (
            SELECT d.ORDER_CUSTOMER_HK, d.ORDER_HK, d.CUSTOMER_HK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.SOURCE
            FROM latest_records AS d
            WHERE CONVERT(DATE, d."END_DATE") != CONVERT(DATE, '9999-12-31 23:59:59.9999999')
        ),
        
        new_open_records AS (
            SELECT DISTINCT
                f.ORDER_CUSTOMER_HK, f.ORDER_HK, f.CUSTOMER_HK, f.START_DATE, f.END_DATE, f.EFFECTIVE_FROM, f.LOAD_DATETIME, f.SOURCE
            FROM source_data AS f
            LEFT JOIN latest_records AS lr
            ON f.ORDER_CUSTOMER_HK = lr.ORDER_CUSTOMER_HK
            WHERE lr.ORDER_CUSTOMER_HK IS NULL
        ),
        
        new_reopened_records AS (
            SELECT DISTINCT
                lc.ORDER_CUSTOMER_HK,
                lc.ORDER_HK, lc.CUSTOMER_HK,
                g.START_DATE AS START_DATE,
                g.END_DATE AS END_DATE,
                g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                g.LOAD_DATETIME,
                g.SOURCE
            FROM source_data AS g
            INNER JOIN latest_closed lc
            ON g.ORDER_CUSTOMER_HK = lc.ORDER_CUSTOMER_HK
            WHERE CAST((g.END_DATE) AS DATE) = CAST(('9999-12-31 23:59:59.9999999') AS DATE)
        ),
        
        new_closed_records AS (
            SELECT DISTINCT
                lo.ORDER_CUSTOMER_HK,
                lo.ORDER_HK, lo.CUSTOMER_HK,
                h.START_DATE AS START_DATE,
                h.EFFECTIVE_FROM AS END_DATE,
                h.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                h.LOAD_DATETIME,
                lo.SOURCE
            FROM source_data AS h
            LEFT JOIN Latest_open AS lo
            ON lo.ORDER_CUSTOMER_HK = h.ORDER_CUSTOMER_HK
            LEFT JOIN latest_closed AS lc
            ON lc.ORDER_CUSTOMER_HK = h.ORDER_CUSTOMER_HK
            WHERE CAST((h.END_DATE) AS DATE) != CAST(('9999-12-31 23:59:59.9999999') AS DATE)
            AND lo.ORDER_CUSTOMER_HK IS NOT NULL
            AND lc.ORDER_CUSTOMER_HK IS NULL
        ),

        records_to_insert AS (
            SELECT * FROM new_open_records
            UNION
            SELECT * FROM new_reopened_records
        )
        
        SELECT * FROM records_to_insert
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

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/snowflake/ma_sat.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/bigquery/ma_sat.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/sqlserver/ma_sat.sql)

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
        WITH source_data AS (
            SELECT DISTINCT s.CUSTOMER_PK, s.HASHDIFF, s.CUSTOMER_PHONE, s.CUSTOMER_NAME, s.EFFECTIVE_FROM, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
                AND s.CUSTOMER_PHONE IS NOT NULL
        ),
        
        records_to_insert AS (
            SELECT source_data.CUSTOMER_PK, source_data.HASHDIFF, source_data.CUSTOMER_PHONE, source_data.CUSTOMER_NAME, source_data.EFFECTIVE_FROM, source_data.LOAD_DATE, source_data.SOURCE
            FROM source_data
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH source_data AS (
            SELECT DISTINCT s.CUSTOMER_PK, s.HASHDIFF, s.CUSTOMER_PHONE, s.CUSTOMER_NAME, s.EFFECTIVE_FROM, s.LOAD_DATE, s.SOURCE 
                ,COUNT(DISTINCT s.HASHDIFF, s.CUSTOMER_PHONE)
                    OVER (PARTITION BY s.CUSTOMER_PK) AS source_count
            FROM DBTVAULT.TEST.STG_CUSTOMER AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
                AND s.CUSTOMER_PHONE IS NOT NULL
        ),
        
        latest_records AS (
            SELECT mas.CUSTOMER_PK
                ,mas.HASHDIFF
                ,mas.CUSTOMER_PHONE
                ,mas.LOAD_DATE
                ,mas.latest_rank
                ,DENSE_RANK() OVER (
                    PARTITION BY mas.CUSTOMER_PK
                    ORDER BY mas.HASHDIFF, mas.CUSTOMER_PHONE ASC
                ) AS check_rank
            FROM (
                SELECT inner_mas.CUSTOMER_PK
                    ,inner_mas.HASHDIFF
                    ,inner_mas.CUSTOMER_PHONE
                    ,inner_mas.LOAD_DATE
                    ,RANK() OVER (PARTITION BY inner_mas.CUSTOMER_PK
                        ORDER BY inner_mas.LOAD_DATE DESC) AS latest_rank
                FROM DBTVAULT.TEST.MULTI_ACTIVE_SATELLITE AS inner_mas
                INNER JOIN (SELECT DISTINCT s.CUSTOMER_PK FROM source_data as s ) AS spk
                    ON inner_mas.CUSTOMER_PK = spk.CUSTOMER_PK 
                QUALIFY latest_rank = 1
            ) AS mas
        ),
        
        latest_group_details AS (
            SELECT lr.CUSTOMER_PK
                ,lr.LOAD_DATE
                ,MAX(lr.check_rank) AS latest_count
            FROM latest_records AS lr
            GROUP BY lr.CUSTOMER_PK, lr.LOAD_DATE
        ),
        
        records_to_insert AS (
            SELECT source_data.CUSTOMER_PK, source_data.HASHDIFF, source_data.CUSTOMER_PHONE, source_data.CUSTOMER_NAME, source_data.EFFECTIVE_FROM, source_data.LOAD_DATE, source_data.SOURCE
            FROM source_data
            WHERE EXISTS
            (
                SELECT 1
                FROM source_data AS stage
                WHERE NOT EXISTS
                (
                    SELECT 1
                    FROM
                    (
                        SELECT lr.CUSTOMER_PK
                        ,lr.HASHDIFF
                        ,lr.CUSTOMER_PHONE
                        ,lr.LOAD_DATE
                        ,lg.latest_count
                        FROM latest_records AS lr
                        INNER JOIN latest_group_details AS lg
                            ON lr.CUSTOMER_PK = lg.CUSTOMER_PK 
                            AND lr.LOAD_DATE = lg.LOAD_DATE
                    ) AS active_records
                    WHERE stage.CUSTOMER_PK = active_records.CUSTOMER_PK 
                        AND stage.HASHDIFF = active_records.HASHDIFF
                        AND stage.CUSTOMER_PHONE = active_records.CUSTOMER_PHONE 
                        AND stage.source_count = active_records.latest_count
                )
                AND source_data.CUSTOMER_PK = stage.CUSTOMER_PK 
            )
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google BigQuery"

    === "Base Load"
    
        ```sql
        WITH source_data AS (
            SELECT DISTINCT s.CUSTOMER_PK, s.HASHDIFF, s.CUSTOMER_PHONE, s.CUSTOMER_NAME, s.EFFECTIVE_FROM, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
                AND s.CUSTOMER_PHONE IS NOT NULL
        ),
        
        records_to_insert AS (
            SELECT source_data.CUSTOMER_PK, source_data.HASHDIFF, source_data.CUSTOMER_PHONE, source_data.CUSTOMER_NAME, source_data.EFFECTIVE_FROM, source_data.LOAD_DATE, source_data.SOURCE
            FROM source_data
        )
        
        SELECT * FROM records_to_insert
        ```
    === "Subsequent Loads"
        
        ```sql
        WITH source_data AS (
            SELECT DISTINCT s.CUSTOMER_PK, s.HASHDIFF, s.CUSTOMER_PHONE, s.CUSTOMER_NAME, s.EFFECTIVE_FROM, s.LOAD_DATETIME, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
                AND s.CUSTOMER_PHONE IS NOT NULL
        ),

        source_data_with_count AS (
            SELECT a.*
                ,b.source_count
            FROM source_data a
            INNER JOIN
            (
                SELECT t.CUSTOMER_PK
                    ,COUNT(*) AS source_count
                FROM (SELECT DISTINCT s.CUSTOMER_PK, s.HASHDIFF, s.CUSTOMER_PHONE FROM source_data AS s) AS t
                GROUP BY t.CUSTOMER_PK
            ) AS b
            ON a.CUSTOMER_PK = b.CUSTOMER_PK
        ),

        latest_records AS (
            SELECT mas.CUSTOMER_PK
                ,mas.HASHDIFF
                ,mas.CUSTOMER_PHONE
                ,mas.LOAD_DATETIME
                ,mas.latest_rank
                ,DENSE_RANK() OVER (PARTITION BY mas.CUSTOMER_PK
                    ORDER BY mas.HASHDIFF, mas.CUSTOMER_PHONE ASC) AS check_rank
            FROM
            (
            SELECT inner_mas.CUSTOMER_PK
                ,inner_mas.HASHDIFF
                ,inner_mas.CUSTOMER_PHONE
                ,inner_mas.LOAD_DATETIME
                ,RANK() OVER (PARTITION BY inner_mas.CUSTOMER_PK
                    ORDER BY inner_mas.LOAD_DATETIME DESC) AS latest_rank
            FROM flash-bazaar-332912.DBTVAULT_FLASH_BAZAAR_332912.MULTI_ACTIVE_SATELLITE_TS AS inner_mas
            INNER JOIN (SELECT DISTINCT s.CUSTOMER_PK FROM source_data as s ) AS spk
                ON inner_mas.CUSTOMER_PK = spk.CUSTOMER_PK
            ) AS mas
            WHERE latest_rank = 1
        ),

        latest_group_details AS (
            SELECT lr.CUSTOMER_PK
                ,lr.LOAD_DATETIME
                ,MAX(lr.check_rank) AS latest_count
            FROM latest_records AS lr
            GROUP BY lr.CUSTOMER_PK, lr.LOAD_DATETIME
        ),



        records_to_insert AS (
            SELECT source_data_with_count.CUSTOMER_PK, source_data_with_count.HASHDIFF, source_data_with_count.CUSTOMER_PHONE, source_data_with_count.CUSTOMER_NAME, source_data_with_count.EFFECTIVE_FROM, source_data_with_count.LOAD_DATETIME, source_data_with_count.SOURCE
            FROM source_data_with_count
            WHERE EXISTS
            (
                SELECT 1
                FROM source_data_with_count AS stage
                WHERE NOT EXISTS
                (
                    SELECT 1
                    FROM
                    (
                        SELECT lr.CUSTOMER_PK
                        ,lr.HASHDIFF
                        ,lr.CUSTOMER_PHONE
                        ,lr.LOAD_DATETIME
                        ,lg.latest_count
                        FROM latest_records AS lr
                        INNER JOIN latest_group_details AS lg
                            ON lr.CUSTOMER_PK = lg.CUSTOMER_PK
                            AND lr.LOAD_DATETIME = lg.LOAD_DATETIME
                    ) AS active_records
                    WHERE stage.CUSTOMER_PK = active_records.CUSTOMER_PK
                        AND stage.HASHDIFF = active_records.HASHDIFF
                        AND stage.CUSTOMER_PHONE = active_records.CUSTOMER_PHONE
                        AND stage.source_count = active_records.latest_count
                )
                AND source_data_with_count.CUSTOMER_PK = stage.CUSTOMER_PK
            )

        )

        SELECT * FROM records_to_insert
        ```

=== "MS SQL Server"

    === "Base Load"
    
        ```sql
        WITH source_data AS (
            SELECT DISTINCT s.CUSTOMER_PK, s.HASHDIFF, s.CUSTOMER_PHONE, s.CUSTOMER_NAME, s.EFFECTIVE_FROM, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
                AND s.CUSTOMER_PHONE IS NOT NULL
        ),
        
        records_to_insert AS (
            SELECT source_data.CUSTOMER_PK, source_data.HASHDIFF, source_data.CUSTOMER_PHONE, source_data.CUSTOMER_NAME, source_data.EFFECTIVE_FROM, source_data.LOAD_DATE, source_data.SOURCE
            FROM source_data
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH source_data AS (
            SELECT DISTINCT s.CUSTOMER_PK, s.HASHDIFF, s.CUSTOMER_PHONE, s.CUSTOMER_NAME, s.EFFECTIVE_FROM, s.LOAD_DATETIME, s.SOURCE
            FROM DBTVAULT_DEV.TEST.STG_CUSTOMER AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
                AND s.CUSTOMER_PHONE IS NOT NULL
        ),
        
        source_data_with_count AS (
            SELECT a.*
                ,b.source_count
            FROM source_data a
            INNER JOIN
            (
                SELECT t.CUSTOMER_PK
                    ,COUNT(*) AS source_count
                FROM (SELECT DISTINCT s.CUSTOMER_PK, s.HASHDIFF, s.CUSTOMER_PHONE FROM source_data AS s) AS t
                GROUP BY t.CUSTOMER_PK
            ) AS b
            ON a.CUSTOMER_PK = b.CUSTOMER_PK
        ),
        
        latest_records AS (
            SELECT mas.CUSTOMER_PK
                ,mas.HASHDIFF
                ,mas.CUSTOMER_PHONE
                ,mas.LOAD_DATETIME
                ,mas.latest_rank
                ,DENSE_RANK() OVER (PARTITION BY mas.CUSTOMER_PK
                    ORDER BY mas.HASHDIFF, mas.CUSTOMER_PHONE ASC) AS check_rank
            FROM
            (
            SELECT inner_mas.CUSTOMER_PK
                ,inner_mas.HASHDIFF
                ,inner_mas.CUSTOMER_PHONE
                ,inner_mas.LOAD_DATETIME
                ,RANK() OVER (PARTITION BY inner_mas.CUSTOMER_PK
                    ORDER BY inner_mas.LOAD_DATETIME DESC) AS latest_rank
            FROM DBTVAULT_DEV.TEST.MULTI_ACTIVE_SATELLITE AS inner_mas
            INNER JOIN (SELECT DISTINCT s.CUSTOMER_PK FROM source_data as s ) AS spk
                ON inner_mas.CUSTOMER_PK = spk.CUSTOMER_PK
            ) AS mas
            WHERE latest_rank = 1
        ),
        
        latest_group_details AS (
            SELECT lr.CUSTOMER_PK
                ,lr.LOAD_DATETIME
                ,MAX(lr.check_rank) AS latest_count
            FROM latest_records AS lr
            GROUP BY lr.CUSTOMER_PK, lr.LOAD_DATETIME
        ),
        
        records_to_insert AS (
            SELECT source_data_with_count.CUSTOMER_PK, source_data_with_count.HASHDIFF, source_data_with_count.CUSTOMER_PHONE, source_data_with_count.CUSTOMER_NAME, source_data_with_count.EFFECTIVE_FROM, source_data_with_count.LOAD_DATETIME, source_data_with_count.SOURCE
            FROM source_data_with_count
            WHERE EXISTS
            (
                SELECT 1
                FROM source_data_with_count AS stage
                WHERE NOT EXISTS
                (
                    SELECT 1
                    FROM
                    (
                        SELECT lr.CUSTOMER_PK
                        ,lr.HASHDIFF
                        ,lr.CUSTOMER_PHONE
                        ,lr.LOAD_DATETIME
                        ,lg.latest_count
                        FROM latest_records AS lr
                        INNER JOIN latest_group_details AS lg
                            ON lr.CUSTOMER_PK = lg.CUSTOMER_PK
                            AND lr.LOAD_DATETIME = lg.LOAD_DATETIME
                    ) AS active_records
                    WHERE stage.CUSTOMER_PK = active_records.CUSTOMER_PK
                        AND stage.HASHDIFF = active_records.HASHDIFF
                        AND stage.CUSTOMER_PHONE = active_records.CUSTOMER_PHONE
                        AND stage.source_count = active_records.latest_count
                )
                AND source_data_with_count.CUSTOMER_PK = stage.CUSTOMER_PK
            )
        )
        
        SELECT * FROM records_to_insert
        ```

### xts

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/snowflake/xts.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/bigquery/xts.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/sqlserver/xts.sql)

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
        WITH satellite_a AS (
            SELECT CUSTOMER_PK, HASHDIFF AS HASHDIFF, SATELLITE_NAME AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        union_satellites AS (
            SELECT * 
            FROM satellite_a
        ),
        
        records_to_insert AS (
            SELECT DISTINCT union_satellites.* 
            FROM union_satellites
            LEFT JOIN DBTVAULT.TEST.XTS AS d
                ON (union_satellites.HASHDIFF = d.HASHDIFF
                AND union_satellites.LOAD_DATE = d.LOAD_DATE
                AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
                )
            WHERE d.HASHDIFF IS NULL
                AND d.LOAD_DATE IS NULL
                AND d.SATELLITE_NAME IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Single-Source with Multiple Satellite Feeds"
        
        ```sql
        WITH satellite_a AS (
            SELECT CUSTOMER_PK, HASHDIFF_1 AS HASHDIFF, SATELLITE_1 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        satellite_b AS (
            SELECT CUSTOMER_PK, HASHDIFF_2 AS HASHDIFF, SATELLITE_2 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        union_satellites AS (
            SELECT * FROM satellite_a
            UNION ALL
            SELECT * FROM satellite_b
        ),
        
        records_to_insert AS (
            SELECT DISTINCT union_satellites.* FROM union_satellites
            LEFT JOIN DBTVAULT.TEST.XTS_2SAT AS d
                ON (union_satellites.HASHDIFF = d.HASHDIFF
                AND union_satellites.LOAD_DATE = d.LOAD_DATE
                AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
                )
            WHERE d.HASHDIFF IS NULL
                AND d.LOAD_DATE IS NULL
                AND d.SATELLITE_NAME IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Multi-Source"
        
        ```sql
        WITH satellite_a AS (
            SELECT CUSTOMER_PK, HASHDIFF_1 AS HASHDIFF, SATELLITE_1 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_1
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        satellite_b AS (
            SELECT CUSTOMER_PK, HASHDIFF_2 AS HASHDIFF, SATELLITE_2 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_1
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        satellite_c AS (
            SELECT CUSTOMER_PK, HASHDIFF_1 AS HASHDIFF, SATELLITE_1 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_2
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        satellite_d AS (
            SELECT CUSTOMER_PK, HASHDIFF_2 AS HASHDIFF, SATELLITE_2 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_2
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        union_satellites AS (
            SELECT * FROM satellite_a
            UNION ALL
            SELECT * FROM satellite_b
            UNION ALL
            SELECT * FROM satellite_c
            UNION ALL
            SELECT * FROM satellite_d
        ),
        
        records_to_insert AS (
            SELECT DISTINCT union_satellites.* FROM union_satellites
            LEFT JOIN DBTVAULT.TEST.XTS_2SAT AS d
                ON (union_satellites.HASHDIFF = d.HASHDIFF
                    AND union_satellites.LOAD_DATE = d.LOAD_DATE
                    AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
                )
            WHERE d.HASHDIFF IS NULL
                AND d.LOAD_DATE IS NULL
                AND d.SATELLITE_NAME IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google Bigquery"

    === "Single-Source"

        ```sql
        WITH satellite_a AS (
            SELECT CUSTOMER_PK, HASHDIFF AS HASHDIFF, SATELLITE_NAME AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        union_satellites AS (
            SELECT * 
            FROM satellite_a
        ),
        
        records_to_insert AS (
            SELECT DISTINCT union_satellites.* 
            FROM union_satellites
            LEFT JOIN DBTVAULT.TEST.XTS AS d
                ON (union_satellites.HASHDIFF = d.HASHDIFF
                AND union_satellites.LOAD_DATE = d.LOAD_DATE
                AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
                )
            WHERE d.HASHDIFF IS NULL
                AND d.LOAD_DATE IS NULL
                AND d.SATELLITE_NAME IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Single-Source with Multiple Satellite Feeds"
        
        ```sql
        WITH 

        satellite_a AS (
            SELECT s.CUSTOMER_PK, s.HASHDIFF_1 AS HASHDIFF, s.SATELLITE_1 AS SATELLITE_NAME, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
        ),

        satellite_b AS (
            SELECT s.CUSTOMER_PK, s.HASHDIFF_2 AS HASHDIFF, s.SATELLITE_2 AS SATELLITE_NAME, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
        ),

        union_satellites AS (
            SELECT * FROM satellite_a
            UNION ALL
            SELECT * FROM satellite_b
        ),

        records_to_insert AS (
            SELECT DISTINCT union_satellites.* FROM union_satellites
            LEFT JOIN DBTVAULT.TEST.XTS_2SAT AS d
                ON (union_satellites.HASHDIFF = d.HASHDIFF
                AND union_satellites.LOAD_DATE = d.LOAD_DATE
                AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
            )
            WHERE d.HASHDIFF IS NULL
            AND d.LOAD_DATE IS NULL
            AND d.SATELLITE_NAME IS NULL
        )

        SELECT * FROM records_to_insert
        ```

    === "Multi-Source"
        
        ```sql
        
        WITH 

        satellite_a AS (
            SELECT s.CUSTOMER_PK, s.HASHDIFF_1 AS HASHDIFF, s.SATELLITE_1 AS SATELLITE_NAME, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_1 AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
        ),

        satellite_b AS (
            SELECT s.CUSTOMER_PK, s.HASHDIFF_2 AS HASHDIFF, s.SATELLITE_2 AS SATELLITE_NAME, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_1 AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
        ),

        satellite_c AS (
            SELECT s.CUSTOMER_PK, s.HASHDIFF_1 AS HASHDIFF, s.SATELLITE_1 AS SATELLITE_NAME, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
        ),

        satellite_d AS (
            SELECT s.CUSTOMER_PK, s.HASHDIFF_2 AS HASHDIFF, s.SATELLITE_2 AS SATELLITE_NAME, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
        ),

        satellite_e AS (
            SELECT s.CUSTOMER_PK, s.HASHDIFF_1 AS HASHDIFF, s.SATELLITE_1 AS SATELLITE_NAME, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_2 AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
        ),

        satellite_f AS (
            SELECT s.CUSTOMER_PK, s.HASHDIFF_2 AS HASHDIFF, s.SATELLITE_2 AS SATELLITE_NAME, s.LOAD_DATE, s.SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_2 AS s
            WHERE s.CUSTOMER_PK IS NOT NULL
        ),

        union_satellites AS (
            SELECT * FROM satellite_a
            UNION ALL
            SELECT * FROM satellite_b
            UNION ALL
            SELECT * FROM satellite_c
            UNION ALL
            SELECT * FROM satellite_d
            UNION ALL
            SELECT * FROM satellite_e
            UNION ALL
            SELECT * FROM satellite_f
        ),

        records_to_insert AS (
            SELECT DISTINCT union_satellites.* FROM union_satellites
            LEFT JOIN DBTVAULT.TEST.XTS_2SAT AS d
                ON (union_satellites.HASHDIFF = d.HASHDIFF
                AND union_satellites.LOAD_DATE = d.LOAD_DATE
                AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
                )
            WHERE d.HASHDIFF IS NULL
            AND d.LOAD_DATE IS NULL
            AND d.SATELLITE_NAME IS NULL
        )

    SELECT * FROM records_to_insert
    ```

=== "MS SQL Server"

    === "Single-Source"

        ```sql
        WITH satellite_a AS (
            SELECT CUSTOMER_PK, HASHDIFF AS HASHDIFF, SATELLITE_NAME AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        union_satellites AS (
            SELECT * 
            FROM satellite_a
        ),
        
        records_to_insert AS (
            SELECT DISTINCT union_satellites.* 
            FROM union_satellites
            LEFT JOIN DBTVAULT.TEST.XTS AS d
                ON (union_satellites.HASHDIFF = d.HASHDIFF
                AND union_satellites.LOAD_DATE = d.LOAD_DATE
                AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
                )
            WHERE d.HASHDIFF IS NULL
                AND d.LOAD_DATE IS NULL
                AND d.SATELLITE_NAME IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Single-Source with Multiple Satellite Feeds"
        
        ```sql
        WITH satellite_a AS (
            SELECT CUSTOMER_PK, HASHDIFF_1 AS HASHDIFF, SATELLITE_1 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        satellite_b AS (
            SELECT CUSTOMER_PK, HASHDIFF_2 AS HASHDIFF, SATELLITE_2 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        union_satellites AS (
            SELECT * FROM satellite_a
            UNION ALL
            SELECT * FROM satellite_b
        ),
        
        records_to_insert AS (
            SELECT DISTINCT union_satellites.* FROM union_satellites
            LEFT JOIN DBTVAULT.TEST.XTS_2SAT AS d
                ON (union_satellites.HASHDIFF = d.HASHDIFF
                AND union_satellites.LOAD_DATE = d.LOAD_DATE
                AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
                )
            WHERE d.HASHDIFF IS NULL
                AND d.LOAD_DATE IS NULL
                AND d.SATELLITE_NAME IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Multi-Source"
        
        ```sql
        WITH satellite_a AS (
            SELECT CUSTOMER_PK, HASHDIFF_1 AS HASHDIFF, SATELLITE_1 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_1
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        satellite_b AS (
            SELECT CUSTOMER_PK, HASHDIFF_2 AS HASHDIFF, SATELLITE_2 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_1
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        satellite_c AS (
            SELECT CUSTOMER_PK, HASHDIFF_1 AS HASHDIFF, SATELLITE_1 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_2
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        satellite_d AS (
            SELECT CUSTOMER_PK, HASHDIFF_2 AS HASHDIFF, SATELLITE_2 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT_2
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        union_satellites AS (
            SELECT * FROM satellite_a
            UNION ALL
            SELECT * FROM satellite_b
            UNION ALL
            SELECT * FROM satellite_c
            UNION ALL
            SELECT * FROM satellite_d
        ),
        
        records_to_insert AS (
            SELECT DISTINCT union_satellites.* FROM union_satellites
            LEFT JOIN DBTVAULT.TEST.XTS_2SAT AS d
                ON (union_satellites.HASHDIFF = d.HASHDIFF
                    AND union_satellites.LOAD_DATE = d.LOAD_DATE
                    AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
                )
            WHERE d.HASHDIFF IS NULL
                AND d.LOAD_DATE IS NULL
                AND d.SATELLITE_NAME IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

### pit

###### view source:

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/snowflake/pit.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/bigquery/pit.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/sqlserver/pit.sql)

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
        WITH as_of_dates AS (
            SELECT * 
            FROM DBTVAULT.TEST.AS_OF_DATE AS a
        ),
        
        new_rows_as_of_dates AS (
            SELECT
                a.CUSTOMER_PK,
                b.AS_OF_DATE
            FROM DBTVAULT.TEST.HUB_CUSTOMER AS a
            INNER JOIN as_of_dates AS b
            ON (1=1)
        ),
        
        new_rows AS (
            SELECT
                a.CUSTOMER_PK,
                a.AS_OF_DATE,
                COALESCE(MAX(sat_customer_details_src.CUSTOMER_PK), CAST('0000000000000000' AS BINARY(16))) AS SAT_CUSTOMER_DETAILS_PK,
                COALESCE(MAX(sat_customer_details_src.LOAD_DATE), CAST('1900-01-01 00:00:00.000' AS timestamp_ntz)) AS SAT_CUSTOMER_DETAILS_LDTS,
                COALESCE(MAX(sat_customer_login_src.CUSTOMER_PK), CAST('0000000000000000' AS BINARY(16))) AS SAT_CUSTOMER_LOGIN_PK,
                COALESCE(MAX(sat_customer_login_src.LOAD_DATE), CAST('1900-01-01 00:00:00.000' AS timestamp_ntz)) AS SAT_CUSTOMER_LOGIN_LDTS,
                COALESCE(MAX(sat_customer_profile_src.CUSTOMER_PK), CAST('0000000000000000' AS BINARY(16))) AS SAT_CUSTOMER_PROFILE_PK,
                COALESCE(MAX(sat_customer_profile_src.LOAD_DATE), CAST('1900-01-01 00:00:00.000' AS timestamp_ntz)) AS SAT_CUSTOMER_PROFILE_LDTS
            FROM new_rows_as_of_dates AS a
            LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_DETAILS AS sat_customer_details_src
                ON a.CUSTOMER_PK = sat_customer_details_src.CUSTOMER_PK
                AND sat_customer_details_src.LOAD_DATE <= a.AS_OF_DATE
            LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_LOGIN AS sat_customer_login_src
                ON a.CUSTOMER_PK = sat_customer_login_src.CUSTOMER_PK
                AND sat_customer_login_src.LOAD_DATE <= a.AS_OF_DATE
            LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_PROFILE AS sat_customer_profile_src
                ON a.CUSTOMER_PK = sat_customer_profile_src.CUSTOMER_PK
                AND sat_customer_profile_src.LOAD_DATE <= a.AS_OF_DATE
            GROUP BY
                a.CUSTOMER_PK, a.AS_OF_DATE
        ),
        
        pit AS (
            SELECT * FROM new_rows
        )
        
        SELECT DISTINCT * FROM pit
        ```

    === "Incremental Load"

        ```sql
        WITH as_of_dates AS (
            SELECT * 
            FROM DBTVAULT.TEST.AS_OF_DATE
        ),
        
        last_safe_load_datetime AS (
            SELECT MIN(LOAD_DATETIME) AS LAST_SAFE_LOAD_DATETIME 
            FROM (
                SELECT MIN(LOAD_DATE) AS LOAD_DATETIME FROM DBTVAULT.TEST.STG_CUSTOMER_DETAILS
                UNION ALL
                SELECT MIN(LOAD_DATE) AS LOAD_DATETIME FROM DBTVAULT.TEST.STG_CUSTOMER_LOGIN
                UNION ALL
                SELECT MIN(LOAD_DATE) AS LOAD_DATETIME FROM DBTVAULT.TEST.STG_CUSTOMER_PROFILE
            ) a
        ),
        
        as_of_grain_old_entries AS (
            SELECT DISTINCT AS_OF_DATE 
            FROM DBTVAULT.TEST.PIT_CUSTOMER
        ),
        
        as_of_grain_lost_entries AS (
            SELECT a.AS_OF_DATE
            FROM as_of_grain_old_entries AS a
            LEFT OUTER JOIN as_of_dates AS b
                ON a.AS_OF_DATE = b.AS_OF_DATE
            WHERE b.AS_OF_DATE IS NULL
        ),
        
        as_of_grain_new_entries AS (
            SELECT a.AS_OF_DATE
            FROM as_of_dates AS a
            LEFT OUTER JOIN as_of_grain_old_entries AS b
                ON a.AS_OF_DATE = b.AS_OF_DATE
            WHERE b.AS_OF_DATE IS NULL
        ),
        
        min_date AS (
            SELECT min(AS_OF_DATE) AS MIN_DATE
            FROM as_of_dates
        ),
        
        backfill_as_of AS (
            SELECT AS_OF_DATE
            FROM as_of_dates AS a
            WHERE a.AS_OF_DATE < (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
        ),
        
        new_rows_pks AS (
            SELECT a.CUSTOMER_PK
            FROM DBTVAULT.TEST.HUB_CUSTOMER AS a
            WHERE a.LOAD_DATE >= (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
        ),
        
        new_rows_as_of AS (
            SELECT AS_OF_DATE
            FROM as_of_dates AS a
            WHERE a.AS_OF_DATE >= (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
            UNION
            SELECT AS_OF_DATE
            FROM as_of_grain_new_entries
        ),
        
        overlap AS (
            SELECT a.*
            FROM DBTVAULT.TEST.PIT_CUSTOMER AS a
            INNER JOIN DBTVAULT.TEST.HUB_CUSTOMER as b
                ON a.CUSTOMER_PK = b.CUSTOMER_PK
            WHERE a.AS_OF_DATE >= (SELECT MIN_DATE FROM min_date)
                AND a.AS_OF_DATE < (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
                AND a.AS_OF_DATE NOT IN (SELECT AS_OF_DATE FROM as_of_grain_lost_entries)
        ),
        
        -- Back-fill any newly arrived hubs, set all historical pit dates to ghost records
        
        backfill_rows_as_of_dates AS (
            SELECT
                a.CUSTOMER_PK,
                b.AS_OF_DATE
            FROM new_rows_pks AS a
            INNER JOIN backfill_as_of AS b
                ON (1=1 )
        ),
        
        backfill AS (
            SELECT
                a.CUSTOMER_PK,
                a.AS_OF_DATE,
                CAST('0000000000000000' AS BINARY(16)) AS SAT_CUSTOMER_DETAILS_PK,
                CAST('1900-01-01 00:00:00.000' AS timestamp_ntz) AS SAT_CUSTOMER_DETAILS_LDTS,
                CAST('0000000000000000' AS BINARY(16)) AS SAT_CUSTOMER_LOGIN_PK,
                CAST('1900-01-01 00:00:00.000' AS timestamp_ntz) AS SAT_CUSTOMER_LOGIN_LDTS,
                CAST('0000000000000000' AS BINARY(16)) AS SAT_CUSTOMER_PROFILE_PK,        
                CAST('1900-01-01 00:00:00.000' AS timestamp_ntz) AS SAT_CUSTOMER_PROFILE_LDTS
            FROM backfill_rows_as_of_dates AS a
            LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_DETAILS AS sat_customer_details_src
                ON a.CUSTOMER_PK = sat_customer_details_src.CUSTOMER_PK
                AND sat_customer_details_src.LOAD_DATE <= a.AS_OF_DATE
            LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_LOGIN AS sat_customer_login_src
                ON a.CUSTOMER_PK = sat_customer_login_src.CUSTOMER_PK
                AND sat_customer_login_src.LOAD_DATE <= a.AS_OF_DATE
            LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_PROFILE AS sat_customer_profile_src
                ON a.CUSTOMER_PK = sat_customer_profile_src.CUSTOMER_PK
                AND sat_customer_profile_src.LOAD_DATE <= a.AS_OF_DATE
            GROUP BY
                a.CUSTOMER_PK, a.AS_OF_DATE
        ),
        
        new_rows_as_of_dates AS (
            SELECT
                a.CUSTOMER_PK,
                b.AS_OF_DATE
            FROM DBTVAULT.TEST.HUB_CUSTOMER AS a
            INNER JOIN new_rows_as_of AS b
            ON (1=1)
        ),
        
        new_rows AS (
            SELECT
                a.CUSTOMER_PK,
                a.AS_OF_DATE,
                COALESCE(MAX(sat_customer_details_src.CUSTOMER_PK), CAST('0000000000000000' AS BINARY(16))) AS SAT_CUSTOMER_DETAILS_PK,
                COALESCE(MAX(sat_customer_details_src.LOAD_DATE), CAST('1900-01-01 00:00:00.000' AS timestamp_ntz)) AS SAT_CUSTOMER_DETAILS_LDTS,
                COALESCE(MAX(sat_customer_login_src.CUSTOMER_PK), CAST('0000000000000000' AS BINARY(16))) AS SAT_CUSTOMER_LOGIN_PK,
                COALESCE(MAX(sat_customer_login_src.LOAD_DATE), CAST('1900-01-01 00:00:00.000' AS timestamp_ntz)) AS SAT_CUSTOMER_LOGIN_LDTS,
                COALESCE(MAX(sat_customer_profile_src.CUSTOMER_PK), CAST('0000000000000000' AS BINARY(16))) AS SAT_CUSTOMER_PROFILE_PK,
                COALESCE(MAX(sat_customer_profile_src.LOAD_DATE), CAST('1900-01-01 00:00:00.000' AS timestamp_ntz)) AS SAT_CUSTOMER_PROFILE_LDTS
            FROM new_rows_as_of_dates AS a
            LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_DETAILS AS sat_customer_details_src
                ON a.CUSTOMER_PK = sat_customer_details_src.CUSTOMER_PK
                AND sat_customer_details_src.LOAD_DATE <= a.AS_OF_DATE
            LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_LOGIN AS sat_customer_login_src
                ON a.CUSTOMER_PK = sat_customer_login_src.CUSTOMER_PK
                AND sat_customer_login_src.LOAD_DATE <= a.AS_OF_DATE
            LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_PROFILE AS sat_customer_profile_src
                ON a.CUSTOMER_PK = sat_customer_profile_src.CUSTOMER_PK
                AND sat_customer_profile_src.LOAD_DATE <= a.AS_OF_DATE
            GROUP BY
                a.CUSTOMER_PK, a.AS_OF_DATE
        ),
        
        pit AS (
            SELECT * FROM new_rows
            UNION ALL
            SELECT * FROM overlap
            UNION ALL
            SELECT * FROM backfill
        )
        
        SELECT DISTINCT * FROM pit
        ```

=== "Google Bigquery"
    Coming soon!

=== "MS SQL Server"
    Coming soon!

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

[![Snowflake](../assets/images/platform_icons/snowflake.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/snowflake/bridge.sql)
[![BigQuery](../assets/images/platform_icons/bigquery.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/bigquery/bridge.sql)
[![SQLServer](../assets/images/platform_icons/sqlserver.png)](https://github.com/Datavault-UK/automate-dv/blob/v0.9.6/macros/tables/sqlserver/bridge.sql)

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
        WITH as_of AS (
             SELECT a.AS_OF_DATE
             FROM DBTVAULT_DEV.TEST.AS_OF_DATE AS a
             WHERE a.AS_OF_DATE <= CURRENT_DATE()
        ),
        
        new_rows AS (
            SELECT
                a.CUSTOMER_PK,
                b.AS_OF_DATE,LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK AS LINK_CUSTOMER_ORDER_PK
                            ,EFF_SAT_CUSTOMER_ORDER.END_DATE AS EFF_SAT_CUSTOMER_ORDER_ENDDATE
                            ,EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME AS EFF_SAT_CUSTOMER_ORDER_LOADDATE
            FROM DBTVAULT_DEV.TEST.HUB_CUSTOMER AS a
            INNER JOIN AS_OF AS b
                ON (1=1)
            LEFT JOIN DBTVAULT_DEV.TEST.LINK_CUSTOMER_ORDER AS LINK_CUSTOMER_ORDER
                ON a.CUSTOMER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_FK
            INNER JOIN DBTVAULT_DEV.TEST.EFF_SAT_CUSTOMER_ORDER AS EFF_SAT_CUSTOMER_ORDER
                ON EFF_SAT_CUSTOMER_ORDER.CUSTOMER_ORDER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK
                AND EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME <= b.AS_OF_DATE
        ),
        
        all_rows AS (
            SELECT * FROM new_rows
        ),
        
        candidate_rows AS (
            SELECT *,
                ROW_NUMBER() OVER (
                    PARTITION BY AS_OF_DATE,
                        LINK_CUSTOMER_ORDER_PK
                    ORDER BY
                        EFF_SAT_CUSTOMER_ORDER_LOADDATE DESC
                    ) AS row_num
            FROM all_rows
            QUALIFY row_num = 1
        ),
        
        bridge AS (
            SELECT
                c.CUSTOMER_PK,
                c.AS_OF_DATE,c.LINK_CUSTOMER_ORDER_PK
            FROM candidate_rows AS c
            WHERE TO_DATE(c.EFF_SAT_CUSTOMER_ORDER_ENDDATE) = TO_DATE('9999-12-31 23:59:59.999999')
        )
        
        SELECT * FROM bridge
        ```

    === "Subsequent Loads"
        
        ```sql
        WITH as_of AS (
             SELECT a.AS_OF_DATE
             FROM DBTVAULT_DEV.TEST.AS_OF_DATE AS a
             WHERE a.AS_OF_DATE <= CURRENT_DATE()
        ),
        
        last_safe_load_datetime AS (
            SELECT MIN(LOAD_DATETIME) AS LAST_SAFE_LOAD_DATETIME
            FROM (SELECT MIN(LOAD_DATETIME) AS LOAD_DATETIME FROM DBTVAULT_DEV.TEST.STG_CUSTOMER_ORDER
                        
                    ) AS l
        ),
        
        as_of_grain_old_entries AS (
            SELECT DISTINCT AS_OF_DATE
            FROM DBTVAULT_DEV.TEST.BRIDGE_CUSTOMER_ORDER
        ),
        
        as_of_grain_lost_entries AS (
            SELECT a.AS_OF_DATE
            FROM as_of_grain_old_entries AS a
            LEFT OUTER JOIN as_of AS b
                ON a.AS_OF_DATE = b.AS_OF_DATE
            WHERE b.AS_OF_DATE IS NULL
        ),
        
        as_of_grain_new_entries AS (
            SELECT a.AS_OF_DATE
            FROM as_of AS a
            LEFT OUTER JOIN as_of_grain_old_entries AS b
                ON a.AS_OF_DATE = b.AS_OF_DATE
            WHERE b.AS_OF_DATE IS NULL
        ),
        
        min_date AS (
            SELECT min(AS_OF_DATE) AS MIN_DATE
            FROM as_of
        ),
        
        new_rows_pks AS (
            SELECT h.CUSTOMER_PK
            FROM DBTVAULT_DEV.TEST.HUB_CUSTOMER AS h
            WHERE h.LOAD_DATETIME >= (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
        ),
        
        new_rows_as_of AS (
            SELECT AS_OF_DATE
            FROM as_of
            WHERE as_of.AS_OF_DATE >= (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
            UNION
            SELECT as_of_date
            FROM as_of_grain_new_entries
        ),
        
        overlap_pks AS (
            SELECT p.CUSTOMER_PK
            FROM DBTVAULT_DEV.TEST.BRIDGE_CUSTOMER_ORDER AS p
            INNER JOIN DBTVAULT_DEV.TEST.HUB_CUSTOMER as h
                ON p.CUSTOMER_PK = h.CUSTOMER_PK
            WHERE p.AS_OF_DATE >= (SELECT MIN_DATE FROM min_date)
                AND p.AS_OF_DATE < (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
                AND p.AS_OF_DATE NOT IN (SELECT AS_OF_DATE FROM as_of_grain_lost_entries)
        ),
        
        overlap_as_of AS (
            SELECT AS_OF_DATE
            FROM as_of AS p
            WHERE p.AS_OF_DATE >= (SELECT MIN_DATE FROM min_date)
                AND p.AS_OF_DATE < (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
                AND p.AS_OF_DATE NOT IN (SELECT AS_OF_DATE FROM as_of_grain_lost_entries)
        ),
        
        overlap AS (
            SELECT
                a.CUSTOMER_PK,
                b.AS_OF_DATE
                            ,LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK AS LINK_CUSTOMER_ORDER_PK
                            ,EFF_SAT_CUSTOMER_ORDER.END_DATE AS EFF_SAT_CUSTOMER_ORDER_ENDDATE
                            ,EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME AS EFF_SAT_CUSTOMER_ORDER_LOADDATE
            FROM overlap_pks AS a
            INNER JOIN overlap_as_of AS b
                ON (1=1)
            LEFT JOIN DBTVAULT_DEV.TEST.LINK_CUSTOMER_ORDER AS LINK_CUSTOMER_ORDER
                ON a.CUSTOMER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_FK
            INNER JOIN DBTVAULT_DEV.TEST.EFF_SAT_CUSTOMER_ORDER AS EFF_SAT_CUSTOMER_ORDER
                ON EFF_SAT_CUSTOMER_ORDER.CUSTOMER_ORDER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK
                AND EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME <= b.AS_OF_DATE
        ),
        
        new_rows AS (
            SELECT
                a.CUSTOMER_PK,
                b.AS_OF_DATE,LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK AS LINK_CUSTOMER_ORDER_PK
                            ,EFF_SAT_CUSTOMER_ORDER.END_DATE AS EFF_SAT_CUSTOMER_ORDER_ENDDATE
                            ,EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME AS EFF_SAT_CUSTOMER_ORDER_LOADDATE
            FROM DBTVAULT_DEV.TEST.HUB_CUSTOMER AS a
            INNER JOIN NEW_ROWS_AS_OF AS b
                ON (1=1)
            LEFT JOIN DBTVAULT_DEV.TEST.LINK_CUSTOMER_ORDER AS LINK_CUSTOMER_ORDER
                ON a.CUSTOMER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_FK
            INNER JOIN DBTVAULT_DEV.TEST.EFF_SAT_CUSTOMER_ORDER AS EFF_SAT_CUSTOMER_ORDER
                ON EFF_SAT_CUSTOMER_ORDER.CUSTOMER_ORDER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK
                AND EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME <= b.AS_OF_DATE
        ),
        
        all_rows AS (
            SELECT * FROM new_rows
            UNION ALL
            SELECT * FROM overlap
        ),
        
        candidate_rows AS (
            SELECT *,
                ROW_NUMBER() OVER (
                    PARTITION BY AS_OF_DATE,
                        LINK_CUSTOMER_ORDER_PK
                    ORDER BY
                        EFF_SAT_CUSTOMER_ORDER_LOADDATE DESC
                    ) AS row_num
            FROM all_rows
            QUALIFY row_num = 1
        ),
        
        bridge AS (
            SELECT
                c.CUSTOMER_PK,
                c.AS_OF_DATE,c.LINK_CUSTOMER_ORDER_PK
            FROM candidate_rows AS c
            WHERE TO_DATE(c.EFF_SAT_CUSTOMER_ORDER_ENDDATE) = TO_DATE('9999-12-31 23:59:59.999999')
        )
        
        SELECT * FROM bridge
        ```

=== "Google BigQuery"
    Coming soon!

=== "MS SQL Server"
    Coming soon!

#### As Of Date Table Structures

An As of Date table contains a single column of dates used to construct the history in the Bridge table.

!!! note

    At the current release of AutomateDV there is no functionality that auto generates this table for you, so you will 
    have to supply this yourself. For further information, please check the tutorial [page](../tutorial/tut_as_of_date.md).
    
    Another caveat is that even though the As of Date table can take any name, you need to make sure it's defined 
    accordingly in the `as_of_dates_table` metadata parameter (see the [metadata section](../metadata.md#bridge-tables) 
    for Bridges). The column name in the As of Date table is currently defaulted to 'AS_OF_DATE' and it cannot be changed.

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

    === "All variables"

        ```sql
        WITH source_data AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
        
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        derived_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            'STG_BOOKING' AS RECORD_SOURCE,
            BOOKING_DATE AS EFFECTIVE_FROM
        
            FROM source_data
        ),
        
        null_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            RECORD_SOURCE,
            EFFECTIVE_FROM,
            CUSTOMER_ID AS CUSTOMER_ID_ORIGINAL,
            IFNULL(CUSTOMER_ID, '-1') AS CUSTOMER_ID,
            CUSTOMER_NAME AS CUSTOMER_NAME_ORIGINAL,
            IFNULL(CUSTOMER_NAME, '-2') AS CUSTOMER_NAME,
            NATIONALITY AS NATIONALITY_ORIGINAL,
            IFNULL(NATIONALITY, '-2') AS NATIONALITY

            FROM derived_columns
        ),

        hashed_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            SOURCE,
            EFFECTIVE_FROM,
            CUSTOMER_ID_ORIGINAL,
            CUSTOMER_NAME_ORIGINAL,
            NATIONALITY_ORIGINAL,
        
            CAST((MD5_BINARY(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''))) AS BINARY(16)) AS CUSTOMER_HK,
            CAST(MD5_BINARY(CONCAT_WS('||',
                IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_DOB AS VARCHAR))), ''), '^^'),
                IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'),
                IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_NAME AS VARCHAR))), ''), '^^')
            )) AS BINARY(16)) AS CUST_CUSTOMER_HASHDIFF,
            CAST(MD5_BINARY(CONCAT_WS('||',
                IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'),
                IFNULL(NULLIF(UPPER(TRIM(CAST(NATIONALITY AS VARCHAR))), ''), '^^'),
                IFNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR))), ''), '^^')
            )) AS BINARY(16)) AS CUSTOMER_HASHDIFF
        
            FROM derived_columns
        ),
        
        columns_to_select AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            SOURCE,
            EFFECTIVE_FROM,
            CUSTOMER_ID_ORIGINAL,
            CUSTOMER_NAME_ORIGINAL,
            NATIONALITY_ORIGINAL,
            CUSTOMER_HK,
            CUST_CUSTOMER_HASHDIFF,
            CUSTOMER_HASHDIFF
        
            FROM hashed_columns
        )
        
        SELECT * FROM columns_to_select
        ```

    === "Only source"

        ```sql
        WITH source_data AS (
        
            SELECT *
            
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        columns_to_select AS (
        
            SELECT
            
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
            
            FROM source_data
        )
        
        SELECT * FROM columns_to_select
        ```

    === "Only derived"

        ```sql
        WITH source_data AS (

            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
        
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        derived_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            'STG_BOOKING' AS RECORD_SOURCE,
            LOAD_DATE AS EFFECTIVE_FROM
        
            FROM source_data
        ),
        
        columns_to_select AS (
        
            SELECT
        
            SOURCE,
            EFFECTIVE_FROM
        
            FROM derived_columns
        )
        
        SELECT * FROM columns_to_select
        ```

    === "Only null columns"

        ```sql
        WITH source_data AS (

            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
        
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        null_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            CUSTOMER_ID AS CUSTOMER_ID_ORIGINAL,
            IFNULL(CUSTOMER_ID, '-1') AS CUSTOMER_ID,
            CUSTOMER_NAME AS CUSTOMER_NAME_ORIGINAL,
            IFNULL(CUSTOMER_NAME, '-2') AS CUSTOMER_NAME,
            NATIONALITY AS NATIONALITY_ORIGINAL,
            IFNULL(NATIONALITY, '-2') AS NATIONALITY
        
            FROM source_data
        ),
        
        columns_to_select AS (
        
            SELECT
        
            CUSTOMER_ID_ORIGINAL,
            CUSTOMER_ID,
            CUSTOMER_NAME_ORIGINAL,
            CUSTOMER_NAME,
            NATIONALITY_ORIGINAL,
            NATIONALITY
        
            FROM null_columns
        )
        
        SELECT * FROM columns_to_select
        ```

    === "Only hashing"

        ```sql
        WITH source_data AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
        
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        hashed_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
        
            CAST((MD5_BINARY(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''))) AS BINARY(16)) AS CUSTOMER_HK,
            CAST(MD5_BINARY(CONCAT_WS('||',
                IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_DOB AS VARCHAR))), ''), '^^'),
                IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'),
                IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_NAME AS VARCHAR))), ''), '^^')
            )) AS BINARY(16)) AS CUST_CUSTOMER_HASHDIFF,
            CAST(MD5_BINARY(CONCAT_WS('||',
                IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'),
                IFNULL(NULLIF(UPPER(TRIM(CAST(NATIONALITY AS VARCHAR))), ''), '^^'),
                IFNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR))), ''), '^^')
            )) AS BINARY(16)) AS CUSTOMER_HASHDIFF
        
            FROM source_data
        ),
        
        columns_to_select AS (
        
            SELECT
        
            CUSTOMER_HK,
            CUST_CUSTOMER_HASHDIFF,
            CUSTOMER_HASHDIFF
        
            FROM hashed_columns
        )
        
        SELECT * FROM columns_to_select
        ```

    === "Only ranked"

        ```sql
        WITH source_data AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
        
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        ranked_columns AS (
        
            SELECT *,
        
            RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY LOAD_DATE) AS DBTVAULT_RANK,
            RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY LOAD_DATE) AS SAT_LOAD_RANK
        
            FROM source_data
        ),
        
        columns_to_select AS (
        
            SELECT
        
            DBTVAULT_RANK,
            SAT_LOAD_RANK
        
            FROM ranked_columns
        )
        
        SELECT * FROM columns_to_select
        ```

=== "MS SQL Server"

    === "All variables"

        ```sql
        WITH source_data AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
        
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        derived_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            'STG_BOOKING' AS RECORD_SOURCE,
            BOOKING_DATE AS EFFECTIVE_FROM
        
            FROM source_data
        ),
        
        null_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            RECORD_SOURCE,
            EFFECTIVE_FROM,
            CUSTOMER_ID AS CUSTOMER_ID_ORIGINAL,
            ISNULL(CUSTOMER_ID, '-1') AS CUSTOMER_ID,
            CUSTOMER_NAME AS CUSTOMER_NAME_ORIGINAL,
            ISNULL(CUSTOMER_NAME, '-2') AS CUSTOMER_NAME,
            NATIONALITY AS NATIONALITY_ORIGINAL,
            ISNULL(NATIONALITY, '-2') AS NATIONALITY

            FROM derived_columns
        ),

        hashed_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            SOURCE,
            EFFECTIVE_FROM,
            CUSTOMER_ID_ORIGINAL,
            CUSTOMER_NAME_ORIGINAL,
            NATIONALITY_ORIGINAL,
        
            CAST(HASHBYTES('MD5', NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(max)))), '')) AS BINARY(16)) AS CUSTOMER_HK,
            CAST(HASHBYTES('MD5', (CONCAT_WS('||',
                ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_DOB AS VARCHAR(max)))), ''), '^^'),
                ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(max)))), ''), '^^'),
                ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_NAME AS VARCHAR(max)))), ''), '^^')
            )) AS BINARY(16)) AS CUST_CUSTOMER_HASHDIFF,
            CAST(HASHBYTES('MD5', (CONCAT_WS('||',
                ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(max)))), ''), '^^'),
                ISNULL(NULLIF(UPPER(TRIM(CAST(NATIONALITY AS VARCHAR(max)))), ''), '^^'),
                ISNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR(max)))), ''), '^^')
            )) AS BINARY(16)) AS CUSTOMER_HASHDIFF
        
            FROM derived_columns
        ),
        
        columns_to_select AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            SOURCE,
            EFFECTIVE_FROM,
            CUSTOMER_ID_ORIGINAL,
            CUSTOMER_NAME_ORIGINAL,
            NATIONALITY_ORIGINAL,
            CUSTOMER_HK,
            CUST_CUSTOMER_HASHDIFF,
            CUSTOMER_HASHDIFF
        
            FROM hashed_columns
        )
        
        SELECT * FROM columns_to_select
        ```

    === "Only source"

        ```sql
        WITH source_data AS (
        
            SELECT *
            
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        columns_to_select AS (
        
            SELECT
            
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
            
            FROM source_data
        )
        
        SELECT * FROM columns_to_select
        ```

    === "Only derived"

        ```sql
        WITH source_data AS (

            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
        
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        derived_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            'STG_BOOKING' AS RECORD_SOURCE,
            LOAD_DATE AS EFFECTIVE_FROM
        
            FROM source_data
        ),
        
        columns_to_select AS (
        
            SELECT
        
            SOURCE,
            EFFECTIVE_FROM
        
            FROM derived_columns
        )
        
        SELECT * FROM columns_to_select
        ```

    === "Only null columns"

        ```sql
        WITH source_data AS (

            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
        
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        null_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
            CUSTOMER_ID AS CUSTOMER_ID_ORIGINAL,
            ISNULL(CUSTOMER_ID, '-1') AS CUSTOMER_ID,
            CUSTOMER_NAME AS CUSTOMER_NAME_ORIGINAL,
            ISNULL(CUSTOMER_NAME, '-2') AS CUSTOMER_NAME,
            NATIONALITY AS NATIONALITY_ORIGINAL,
            ISNULL(NATIONALITY, '-2') AS NATIONALITY
        
            FROM source_data
        ),
        
        columns_to_select AS (
        
            SELECT
        
            CUSTOMER_ID_ORIGINAL,
            CUSTOMER_ID,
            CUSTOMER_NAME_ORIGINAL,
            CUSTOMER_NAME,
            NATIONALITY_ORIGINAL,
            NATIONALITY
        
            FROM null_columns
        )
        
        SELECT * FROM columns_to_select
        ```

    === "Only hashing"

        ```sql
        WITH source_data AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
        
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        hashed_columns AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE,
        
            CAST(HASHBYTES('MD5', NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(max)))), '')) AS BINARY(16)) AS CUSTOMER_HK,
            CAST(HASHBYTES('MD5', (CONCAT_WS('||',
                ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_DOB AS VARCHAR(max)))), ''), '^^'),
                ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(max)))), ''), '^^'),
                ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_NAME AS VARCHAR(max)))), ''), '^^')
            )) AS BINARY(16)) AS CUST_CUSTOMER_HASHDIFF,
            CAST(HASHBYTES('MD5', (CONCAT_WS('||',
                ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(max)))), ''), '^^'),
                ISNULL(NULLIF(UPPER(TRIM(CAST(NATIONALITY AS VARCHAR(max)))), ''), '^^'),
                ISNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR(max)))), ''), '^^')
            )) AS BINARY(16)) AS CUSTOMER_HASHDIFF
        
            FROM source_data
        ),
        
        columns_to_select AS (
        
            SELECT
        
            CUSTOMER_HK,
            CUST_CUSTOMER_HASHDIFF,
            CUSTOMER_HASHDIFF
        
            FROM hashed_columns
        )
        
        SELECT * FROM columns_to_select
        ```

    === "Only ranked"

        ```sql
        WITH source_data AS (
        
            SELECT
        
            BOOKING_FK,
            ORDER_FK,
            CUSTOMER_HK,
            CUSTOMER_ID,
            LOAD_DATE,
            RECORD_SOURCE,
            CUSTOMER_DOB,
            CUSTOMER_NAME,
            NATIONALITY,
            PHONE,
            TEST_COLUMN_2,
            TEST_COLUMN_3,
            TEST_COLUMN_4,
            TEST_COLUMN_5,
            TEST_COLUMN_6,
            TEST_COLUMN_7,
            TEST_COLUMN_8,
            TEST_COLUMN_9,
            BOOKING_DATE
        
            FROM DBTVAULT.TEST.my_raw_stage
        ),
        
        ranked_columns AS (
        
            SELECT *,
        
            RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY LOAD_DATE) AS DBTVAULT_RANK,
            RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY LOAD_DATE) AS SAT_LOAD_RANK
        
            FROM source_data
        ),
        
        columns_to_select AS (
        
            SELECT
        
            DBTVAULT_RANK,
            SAT_LOAD_RANK
        
            FROM ranked_columns
        )
        
        SELECT * FROM columns_to_select
        ```

### Stage Macro Configurations

[Navigate to our dedicated Stage Macro page](stage_macro_configurations.md)

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