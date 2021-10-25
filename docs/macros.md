## Global usage notes

### source_model syntax

dbt itself supports references to data via
the `ref()` [function](https://docs.getdbt.com/reference/dbt-jinja-functions/ref/) for models, and the `source()`
function for [dbt sources](https://docs.getdbt.com/docs/building-a-dbt-project/using-sources/).

dbtvault provides the means for specifying sources for Data Vault structures with a `source_model` argument.

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

The mapping provided for the source style, is in the form `source_name: table_name` which mimics the syntax for
the `source()` macro.

For all other structures (hub, link, satellite, etc.) the `source_model` argument must be a string to denote a single
staging source, or a list of strings to denote multiple staging sources, which must be names of models (minus
the `.sql`).

## Global variables

dbtvault provides user-overridable [global variables](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-variables#defining-variables-in-dbt_projectyml)
which allow you to configure different aspects of dbtvault. These variables will be expanded in future versions of dbtvault.

=== "dbt_project.yml"

    ```yaml
    vars:
      hash: MD5
      max_datetime: '{{ dbtvault.max_datetime() }}'
      concat_string: '||'
      null_placeholder_string: '^^'
    ```

#### hash

TODO

#### max_datetime

TODO

#### concat_string

TODO

#### null_placeholder_string

TODO

## Table templates

###### (macros/tables)

These macros are the core of the package and can be called in your models to build the different types of tables needed
for your Data Vault.

### hub

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/tables/hub.sql))

Generates SQL to build a hub table using the provided parameters.

#### Usage

``` jinja

{{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter     | Description                                         | Type                 | Required?                                      |
| ------------- | --------------------------------------------------- | -------------------- | ---------------------------------------------- |
| src_pk        | Source primary key column                           | List[String]/String  | :fontawesome-solid-check-circle:{ .required } |
| src_nk        | Source natural key column                           | List[String]/String  | :fontawesome-solid-check-circle:{ .required } |
| src_ldts      | Source load date timestamp column                   | String               | :fontawesome-solid-check-circle:{ .required } |
| src_source    | Name of the column containing the source ID         | List[String]/String  | :fontawesome-solid-check-circle:{ .required } |
| source_model  | Staging model name                                  | List[String]/String  | :fontawesome-solid-check-circle:{ .required } |

!!! tip
    [Read the tutorial](tutorial/tut_hubs.md) for more details

#### Example Metadata

[See examples](metadata.md#hubs)

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
            FROM DBTVAULT.TEST.MY_STAGE
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
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
            LEFT JOIN DBTVAULT.TEST.hub AS d
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
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE_2
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
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE_2
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
            LEFT JOIN DBTVAULT.TEST.hub AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google BigQuery"
    Coming soon!

___

### link

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/tables/link.sql))

Generates sql to build a link table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                 src_source=src_source, source_model=source_model) }}
```                                             

#### Parameters

| Parameter     | Description                                         | Type                 | Required?                                      |
| ------------- | --------------------------------------------------- | ---------------------| ---------------------------------------------- |
| src_pk        | Source primary key column                           | List[String]/String  | :fontawesome-solid-check-circle:{ .required } |
| src_fk        | Source foreign key column(s)                        | List[String]         | :fontawesome-solid-check-circle:{ .required } |
| src_ldts      | Source load date timestamp column                   | String               | :fontawesome-solid-check-circle:{ .required } |
| src_source    | Name of the column containing the source ID         | List[String]/String  | :fontawesome-solid-check-circle:{ .required } |
| source_model  | Staging model name                                  | List[String]/String  | :fontawesome-solid-check-circle:{ .required } |

!!! tip
    [Read the tutorial](tutorial/tut_links.md) for more details

#### Example Metadata

[See examples](metadata.md#links)

#### Example Output

=== "Snowflake"

    === "Single-Source (Base Load)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_HK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
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
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
            LEFT JOIN DBTVAULT.TEST.link AS d
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
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE_2
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
            WHERE ORDER_FK IS NOT NULL
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
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_HK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_HK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE_2
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
            WHERE ORDER_FK IS NOT NULL
            AND BOOKING_FK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_HK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
            LEFT JOIN DBTVAULT.TEST.link AS d
            ON a.CUSTOMER_HK = d.CUSTOMER_HK
            WHERE d.CUSTOMER_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google BigQuery"
    Coming soon!

___

### t_link

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/tables/t_link.sql))

Generates sql to build a transactional link table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.t_link(src_pk=src_pk, src_fk=src_fk, src_payload=src_payload,
                   src_eff=src_eff, src_ldts=src_ldts, 
                   src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter     | Description                                         | Type                | Required?                                         |
| ------------- | --------------------------------------------------- | ------------------- | ------------------------------------------------- |
| src_pk        | Source primary key column                           | List[String]/String | :fontawesome-solid-check-circle:{ .required }    |
| src_fk        | Source foreign key column(s)                        | List[String]        | :fontawesome-solid-check-circle:{ .required }    |
| src_payload   | Source payload column(s)                            | List[String]        | :fontawesome-solid-minus-circle:{ .not-required } |
| src_eff       | Source effective from column                        | String              | :fontawesome-solid-check-circle:{ .required }    |
| src_ldts      | Source load date timestamp column                   | String              | :fontawesome-solid-check-circle:{ .required }    |
| src_source    | Name of the column containing the source ID         | String              | :fontawesome-solid-check-circle:{ .required }    |
| source_model  | Staging model name                                  | String              | :fontawesome-solid-check-circle:{ .required }    |

!!! tip
    [Read the tutorial](tutorial/tut_t_links.md) for more details

#### Example Metadata

[See examples](metadata.md#transactional-links)

#### Example Output

=== "Snowflake"

    === "Base Load"
    
        ```sql
        WITH stage AS (
            SELECT TRANSACTION_HK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.MY_STAGE
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
            FROM DBTVAULT.TEST.raw_stage_hashed
        ),
        records_to_insert AS (
            SELECT DISTINCT stg.TRANSACTION_HK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
            LEFT JOIN DBTVAULT.TEST.t_link AS tgt
            ON stg.TRANSACTION_HK = tgt.TRANSACTION_HK
            WHERE tgt.TRANSACTION_HK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google BigQuery"
    Coming soon!

___

### sat

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/tables/sat.sql))

Generates sql to build a satellite table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.sat(src_pk=src_pk, src_hashdiff=src_hashdiff, src_payload=src_payload,
                src_eff=src_eff, src_ldts=src_ldts, 
                src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter     | Description                                         | Type             | Required?                                          |
| ------------- | --------------------------------------------------- | ---------------- | -------------------------------------------------- |
| src_pk        | Source primary key column                           | String           | :fontawesome-solid-check-circle:{ .required }     |
| src_hashdiff  | Source hashdiff column                              | String           | :fontawesome-solid-check-circle:{ .required }     |
| src_payload   | Source payload column(s)                            | List[String]     | :fontawesome-solid-check-circle:{ .required }     |
| src_eff       | Source effective from column                        | String           | :fontawesome-solid-minus-circle:{ .not-required }  |
| src_ldts      | Source load date timestamp column                   | String           | :fontawesome-solid-check-circle:{ .required }     |
| src_source    | Name of the column containing the source ID         | String           | :fontawesome-solid-check-circle:{ .required }     |
| source_model  | Staging model name                                  | String           | :fontawesome-solid-check-circle:{ .required }     |

!!! tip
    [Read the tutorial](tutorial/tut_satellites.md) for more details

#### Example Metadata

[See examples](metadata.md#satellites)

#### Example Output

=== "Snowflake"

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
        
        update_records AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.SATELLITE as a
            JOIN source_data as b
            ON a.CUSTOMER_HK = b.CUSTOMER_HK
        ),
        
        latest_records AS (
            SELECT c.CUSTOMER_HK, c.HASHDIFF, c.LOAD_DATE,
                RANK() OVER (
                   PARTITION BY c.CUSTOMER_HK
                   ORDER BY c.LOAD_DATE DESC
                   ) AS rank
            FROM update_records as c
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

=== "Google BigQuery"
    Coming soon!

#### Hashdiff Aliasing

If you have multiple satellites using a single stage as its data source, then you will need to
use [hashdiff aliasing](best_practices.md#hashdiff-aliasing)

___

### eff_sat

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/tables/eff_sat.sql))

Generates sql to build an effectivity satellite table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                    src_start_date=src_start_date, src_end_date=src_end_date,
                    src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                    source_model=source_model) }}
```

#### Parameters

| Parameter      | Description                                         | Type                    | Required?                                      |
| -------------- | --------------------------------------------------- | ----------------------- | ---------------------------------------------- |
| src_pk         | Source primary key column                           | String                  | :fontawesome-solid-check-circle:{ .required } |
| src_dfk        | Source driving foreign key column                   | List[String]/String     | :fontawesome-solid-check-circle:{ .required } |
| src_sfk        | Source secondary foreign key column                 | List[String]/String     | :fontawesome-solid-check-circle:{ .required } |
| src_start_date | Source start date column                            | String                  | :fontawesome-solid-check-circle:{ .required } |
| src_end_date   | Source end date column                              | String                  | :fontawesome-solid-check-circle:{ .required } |
| src_eff        | Source effective from column                        | String                  | :fontawesome-solid-check-circle:{ .required } |
| src_ldts       | Source load date timestamp column                   | String                  | :fontawesome-solid-check-circle:{ .required } |
| src_source     | Name of the column containing the source ID         | String                  | :fontawesome-solid-check-circle:{ .required } |
| source_model   | Staging model name                                  | String                  | :fontawesome-solid-check-circle:{ .required } |

!!! tip
    [Read the tutorial](tutorial/tut_eff_satellites.md) for more details

#### Example Metadata

[See examples](metadata.md#effectivity-satellites)

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
            WHERE TO_DATE(c.END_DATE) = TO_DATE('9999-12-31')
        ),
        
        latest_closed AS (
            SELECT d.ORDER_CUSTOMER_HK, d.ORDER_HK, d.CUSTOMER_HK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.SOURCE
            FROM latest_records AS d
            WHERE TO_DATE(d.END_DATE) != TO_DATE('9999-12-31')
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
                lc.START_DATE AS START_DATE,
                g.END_DATE AS END_DATE,
                g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                g.LOAD_DATETIME,
                g.SOURCE
            FROM source_data AS g
            INNER JOIN latest_closed lc
            ON g.ORDER_CUSTOMER_HK = lc.ORDER_CUSTOMER_HK
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
            WHERE TO_DATE(c.END_DATE) = TO_DATE('9999-12-31')
        ),
        
        latest_closed AS (
            SELECT d.ORDER_CUSTOMER_HK, d.ORDER_HK, d.CUSTOMER_HK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.SOURCE
            FROM latest_records AS d
            WHERE TO_DATE(d.END_DATE) != TO_DATE('9999-12-31')
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
                lc.START_DATE AS START_DATE,
                g.END_DATE AS END_DATE,
                g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                g.LOAD_DATETIME,
                g.SOURCE
            FROM source_data AS g
            INNER JOIN latest_closed lc
            ON g.ORDER_CUSTOMER_HK = lc.ORDER_CUSTOMER_HK
        ),
        
        records_to_insert AS (
            SELECT * FROM new_open_records
            UNION
            SELECT * FROM new_reopened_records
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google BigQuery"
    Coming soon!

#### Auto end-dating

Auto end-dating is enabled by providing a config option as below:

``` jinja
{{ config(is_auto_end_dating=true) }}

{{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
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
The definition of the 'end' of a relationship is considered business logic which should happen in the business vault.

[Read the Effectivity Satellite tutorial](tutorial/tut_eff_satellites.md) for more information.

!!! warning

    We have implemented the auto end-dating feature to cover most use cases and scenarios, but caution should be
    exercised if you are unsure.

___

### ma_sat

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/tables/ma_sat.sql))

Generates SQL to build a multi-active satellite table (MAS).

#### Usage

``` jinja
{{ dbtvault.ma_sat(src_pk=src_pk, src_cdk=src_cdk, src_hashdiff=src_hashdiff, 
                   src_payload=src_payload, src_eff=src_eff, src_ldts=src_ldts, 
                   src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter      | Description                                         | Type             | Required?                                         |
| -------------- | --------------------------------------------------- | ---------------- | ------------------------------------------------- |
| src_pk         | Source primary key column                           | String           | :fontawesome-solid-check-circle:{ .required }     |
| src_cdk        | Source child dependent key(s) column(s)             | List[String]     | :fontawesome-solid-check-circle:{ .required }     |
| src_hashdiff   | Source hashdiff column                              | String           | :fontawesome-solid-check-circle:{ .required }     |
| src_payload    | Source payload column(s)                            | List[String]     | :fontawesome-solid-check-circle:{ .required }     |
| src_eff        | Source effective from column                        | String           | :fontawesome-solid-minus-circle:{ .not-required } |
| src_ldts       | Source load date timestamp column                   | String           | :fontawesome-solid-check-circle:{ .required }     |
| src_source     | Name of the column containing the source ID         | String           | :fontawesome-solid-check-circle:{ .required }     |
| source_model   | Staging model name                                  | String           | :fontawesome-solid-check-circle:{ .required }     |

!!! tip
    [Read the tutorial](tutorial/tut_multi_active_satellites.md) for more details

#### Example Metadata

[See examples](metadata.md#multi-active-satellites-mas)

#### Example Output

=== "Snowflake"

    === "Base Load"
    
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.MY_STAGE AS a
        ),
        
        records_to_insert AS (
            SELECT stage.CUSTOMER_HK, stage.HASHDIFF, stage.CUSTOMER_PHONE, stage.CUSTOMER_NAME, stage.EFFECTIVE_FROM, stage.LOAD_DATE, stage.SOURCE
            FROM source_data AS stage
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_PHONE, a.CUSTOMER_NAME, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            ,COUNT(DISTINCT a.HASHDIFF, a.CUSTOMER_PHONE )
                OVER (PARTITION BY a.CUSTOMER_HK) AS source_count
            FROM DBTVAULT.TEST.MY_STAGE AS a
            WHERE a.CUSTOMER_HK IS NOT NULL
                AND a.CUSTOMER_PHONE IS NOT NULL
        ),
        latest_records AS (
            SELECT *, COUNT(DISTINCT latest_selection.HASHDIFF, latest_selection.CUSTOMER_PHONE )
                    OVER (PARTITION BY latest_selection.CUSTOMER_HK) AS target_count
            FROM (
                SELECT target_records.CUSTOMER_PHONE, target_records.CUSTOMER_HK, target_records.HASHDIFF, target_records.LOAD_DATE
                    ,RANK() OVER (PARTITION BY target_records.CUSTOMER_HK
                            ORDER BY target_records.LOAD_DATE DESC) AS rank_value
                FROM DBTVAULT.TEST.MULTI_ACTIVE_SATELLITE AS target_records
                INNER JOIN
                    (SELECT DISTINCT source_pks.CUSTOMER_HK
                    FROM source_data AS source_pks) AS source_records
                        ON target_records.CUSTOMER_HK = source_records.CUSTOMER_HK
                QUALIFY rank_value = 1
                ) AS latest_selection
        ),
        matching_records AS (
            SELECT stage.CUSTOMER_HK
                ,COUNT(DISTINCT stage.HASHDIFF, stage.CUSTOMER_PHONE) AS match_count
            FROM source_data AS stage
            INNER JOIN latest_records
                ON stage.CUSTOMER_HK = latest_records.CUSTOMER_HK
                AND stage.HASHDIFF = latest_records.HASHDIFF
                AND stage.CUSTOMER_PHONE = latest_records.CUSTOMER_PHONE
            GROUP BY stage.CUSTOMER_HK
        ),
        satellite_update AS (
            SELECT DISTINCT stage.CUSTOMER_HK
            FROM source_data AS stage
            INNER JOIN latest_records
                ON latest_records.CUSTOMER_HK = stage.CUSTOMER_HK
            LEFT OUTER JOIN matching_records
                ON matching_records.CUSTOMER_HK = latest_records.CUSTOMER_HK
            WHERE (stage.source_count != latest_records.target_count
                OR COALESCE(matching_records.match_count, 0) != latest_records.target_count)
        ),
        satellite_insert AS (
            SELECT DISTINCT stage.CUSTOMER_HK
            FROM source_data AS stage
            LEFT OUTER JOIN latest_records
                ON stage.CUSTOMER_HK = latest_records.CUSTOMER_HK
            WHERE latest_records.CUSTOMER_HK IS NULL
        ),
        records_to_insert AS (
            SELECT  stage.CUSTOMER_HK, stage.HASHDIFF, stage.CUSTOMER_PHONE, stage.CUSTOMER_NAME, stage.EFFECTIVE_FROM, stage.LOAD_DATE, stage.SOURCE
            FROM source_data AS stage
            INNER JOIN satellite_update
                ON satellite_update.CUSTOMER_HK = stage.CUSTOMER_HK
        
            UNION
        
            SELECT stage.CUSTOMER_HK, stage.HASHDIFF, stage.CUSTOMER_PHONE, stage.CUSTOMER_NAME, stage.EFFECTIVE_FROM, stage.LOAD_DATE, stage.SOURCE
            FROM source_data AS stage
            INNER JOIN satellite_insert
                ON satellite_insert.CUSTOMER_HK = stage.CUSTOMER_HK
        )
        
        SELECT * FROM records_to_insert
        ```

=== "Google BigQuery"
    Coming soon!

___

### xts

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/tables/xts.sql))

Generates SQL to build an Extended Tracking Satellite table using the provided parameters

#### Usage

``` jinja
{{ dbtvault.xts(src_pk=src_pk, src_satellite=src_satellite, src_ldts=src_ldts,
                src_source=src_source, source_model=source_model)              }}
```

#### Parameters

| Parameter      | Description                                                    | Type             | Required?                                    |
| -------------- | -------------------------------------------------------------- | ---------------- | -------------------------------------------- |
| src_pk         | Source primary key column                                      | String/List      | <i class="fas fa-check-circle required"></i> |
| src_satellite  | Dictionary of source satellite name column and hashdiff column | Dictionary       | <i class="fas fa-check-circle required"></i> |
| src_ldts       | Source load dat timestamp column                               | String           | <i class="fas fa-check-circle required"></i> |
| src_source     | Name of the column containing the source ID                    | String/List      | <i class="fas fa-check-circle required"></i> |
| source_model   | Staging model name                                             | String/List      | <i class="fas fa-check-circle required"></i> |

#### Example Metadata

[See examples](metadata.md#extended-record-tracking-satellites-xts)

#### Example Output

=== "Snowflake"

    === "Single-Source"

        ```sql
        WITH 
        satellite_SATELLITE_1_from_PRIMED_STAGE AS (
            SELECT CUSTOMER_PK, HASHDIFF AS HASHDIFF, SATELLITE_NAME AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT_DEV.TEST.PRIMED_STAGE
            WHERE CUSTOMER_PK IS NOT NULL
        ),
            union_satellites AS (
            SELECT * FROM satellite_SATELLITE_1_from_PRIMED_STAGE
        ),
        records_to_insert AS (
            SELECT DISTINCT union_satellites.* FROM union_satellites
            LEFT JOIN DBTVAULT_DEV.TEST.xts AS d
            ON ( union_satellites.HASHDIFF = d.HASHDIFF
            AND union_satellites.LOAD_DATE = d.LOAD_DATE
            AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME )
            WHERE d.HASHDIFF IS NULL
            AND d.LOAD_DATE IS NULL
            AND d.SATELLITE_NAME IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Single-Source with Multiple Satellite Feeds"
        
        ```sql
        WITH 
        satellite_SATELLITE_1_from_PRIMED_STAGE AS (
            SELECT CUSTOMER_PK, HASHDIFF_1 AS HASHDIFF, SATELLITE_NAME_1 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT_DEV.TEST.PRIMED_STAGE
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        satellite_SATELLITE_2_from_PRIMED_STAGE AS (
            SELECT CUSTOMER_PK, HASHDIFF_2 AS HASHDIFF, SATELLITE_NAME_2 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT_DEV.TEST.PRIMED_STAGE
            WHERE CUSTOMER_PK IS NOT NULL
        ),
            union_satellites AS (
            SELECT * FROM satellite_SATELLITE_1_from_PRIMED_STAGE
            UNION ALL
            SELECT * FROM satellite_SATELLITE_2_from_PRIMED_STAGE
        ),
        records_to_insert AS (
            SELECT DISTINCT union_satellites.* FROM union_satellites
            LEFT JOIN DBTVAULT_DEV.TEST.xts AS d
            ON ( union_satellites.HASHDIFF = d.HASHDIFF
            AND union_satellites.LOAD_DATE = d.LOAD_DATE
            AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME )
            WHERE d.HASHDIFF IS NULL
            AND d.LOAD_DATE IS NULL
            AND d.SATELLITE_NAME IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

    === "Multi-Source"
        
        ```sql
        WITH 
        satellite_SATELLITE_1_from_PRIMED_STAGE_1 AS (
            SELECT CUSTOMER_PK, HASHDIFF_1 AS HASHDIFF, SATELLITE_NAME_1 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT_DEV.TEST.PRIMED_STAGE_1
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        satellite_SATELLITE_2_from_PRIMED_STAGE_1 AS (
            SELECT CUSTOMER_PK, HASHDIFF_2 AS HASHDIFF, SATELLITE_NAME_2 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT_DEV.TEST.PRIMED_STAGE_1
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        satellite_SATELLITE_1_from_PRIMED_STAGE_2 AS (
            SELECT CUSTOMER_PK, HASHDIFF_1 AS HASHDIFF, SATELLITE_NAME_1 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT_DEV.TEST.PRIMED_STAGE_2
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        satellite_SATELLITE_2_from_PRIMED_STAGE_2 AS (
            SELECT CUSTOMER_PK, HASHDIFF_2 AS HASHDIFF, SATELLITE_NAME_2 AS SATELLITE_NAME, LOAD_DATE, SOURCE
            FROM DBTVAULT_DEV.TEST.PRIMED_STAGE_1
            WHERE CUSTOMER_PK IS NOT NULL
        ),
            union_satellites AS (
            SELECT * FROM satellite_SATELLITE_1_from_PRIMED_STAGE_1
            UNION ALL
            SELECT * FROM satellite_SATELLITE_2_from_PRIMED_STAGE_1
            UNION ALL
            SELECT * FROM satellite_SATELLITE_2_from_PRIMED_STAGE_2
            UNION ALL
            SELECT * FROM satellite_SATELLITE_2_from_PRIMED_STAGE_2
        ),
        records_to_insert AS (
            SELECT DISTINCT union_satellites.* FROM union_satellites
            LEFT JOIN DBTVAULT_DEV.TEST.xts AS d
            ON ( union_satellites.HASHDIFF = d.HASHDIFF
            AND union_satellites.LOAD_DATE = d.LOAD_DATE
            AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME )
            WHERE d.HASHDIFF IS NULL
            AND d.LOAD_DATE IS NULL
            AND d.SATELLITE_NAME IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```
___

### pit

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/tables/pit.sql))

Generates SQL to build a point-in-time table (PIT).

#### Usage

``` jinja
{{ dbtvault.pit(source_model=source_model, src_pk=src_pk,
                as_of_dates_table=as_of_dates_table,
                satellites=satellites,
                stage_tables=stage_tables,
                src_ldts=src_ldts) }}
```

#### Parameters

| Parameter         | Description                                         | Type             | Required?                                    |
| --------------    | --------------------------------------------------- | ---------------- | -------------------------------------------- |
|  src_pk           | Source primary key column                           |  String          | <i class="fas fa-check-circle required"></i> |
|  as_of_dates_table| Name for the AS OF DATE table                       |  String          | <i class="fas fa-check-circle required"></i> |
|  satellites       | Dictionary of satellite reference mappings          |  Mapping         | <i class="fas fa-check-circle required"></i> |
|  stage_tables     | Dictionary of stage table reference mappings        |  Mapping         | <i class="fas fa-check-circle required"></i> |
|  src_ldts         | Source load date timestamp column                   |  String          | <i class="fas fa-check-circle required"></i> |
|  source_model     | Hub model name                                      |  String          | <i class="fas fa-check-circle required"></i> |

!!! tip
    [Read the tutorial](tutorial/tut_point_in_time.md) for more details

#### Parameter breakdown

##### satellites

PLACEHOLDER

##### stage_tables

PLACEHOLDER

#### Example Metadata

[See examples](metadata.md#point-in-time-tables-pits)

#### Example Output

=== "Snowflake"

    ```sql
    WITH as_of AS (
        SELECT * FROM DBTVAULT.TEST.AS_OF_DATE
    ),
    
    new_rows_as_of_dates AS (
        SELECT
            hub.CUSTOMER_PK,
            x.AS_OF_DATE
        FROM DBTVAULT.TEST.HUB_CUSTOMER hub
        INNER JOIN AS_OF AS x
        ON (1=1)
    ),
    
    new_rows AS (
        SELECT
            a.CUSTOMER_PK,
            a.AS_OF_DATE,
            COALESCE(MAX(SAT_CUSTOMER_DETAILS_SRC.CUSTOMER_PK), '0000000000000000'::BINARY(16)) AS SAT_CUSTOMER_DETAILS_PK,
            COALESCE(MAX(SAT_CUSTOMER_DETAILS_SRC.LOAD_DATE), '1900-01-01 00:00:00.000000'::TIMESTAMP_NTZ) AS SAT_CUSTOMER_DETAILS_LDTS,
            COALESCE(MAX(SAT_CUSTOMER_LOGIN_SRC.CUSTOMER_PK), '0000000000000000'::BINARY(16)) AS SAT_CUSTOMER_LOGIN_PK,
            COALESCE(MAX(SAT_CUSTOMER_LOGIN_SRC.LOAD_DATE), '1900-01-01 00:00:00.000000'::TIMESTAMP_NTZ) AS SAT_CUSTOMER_LOGIN_LDTS,
            COALESCE(MAX(SAT_CUSTOMER_PROFILE_SRC.CUSTOMER_PK), '0000000000000000'::BINARY(16)) AS SAT_CUSTOMER_PROFILE_PK,
            COALESCE(MAX(SAT_CUSTOMER_PROFILE_SRC.LOAD_DATE), '1900-01-01 00:00:00.000000'::TIMESTAMP_NTZ) AS SAT_CUSTOMER_PROFILE_LDTS
        FROM new_rows_as_of_dates AS a
    
        LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_DETAILS AS SAT_CUSTOMER_DETAILS_SRC
            ON  a.CUSTOMER_PK = SAT_CUSTOMER_DETAILS_SRC.CUSTOMER_PK
            AND SAT_CUSTOMER_DETAILS_SRC.LOAD_DATE <= a.AS_OF_DATE
        LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_LOGIN AS SAT_CUSTOMER_LOGIN_SRC
            ON  a.CUSTOMER_PK = SAT_CUSTOMER_LOGIN_SRC.CUSTOMER_PK
            AND SAT_CUSTOMER_LOGIN_SRC.LOAD_DATE <= a.AS_OF_DATE
        LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_PROFILE AS SAT_CUSTOMER_PROFILE_SRC
            ON  a.CUSTOMER_PK = SAT_CUSTOMER_PROFILE_SRC.CUSTOMER_PK
            AND SAT_CUSTOMER_PROFILE_SRC.LOAD_DATE <= a.AS_OF_DATE
    
        GROUP BY
            a.CUSTOMER_PK, a.AS_OF_DATE
        ORDER BY (1, 2)
    ),
    
    PIT AS (
    SELECT * FROM new_rows
    )
    
    SELECT DISTINCT * FROM PIT
    ```

#### As Of Date Table Structures

An As of Date table contains a single column of dates used to construct the history in the PIT. A typical structure will 
be a  date range where the date interval will be short such as every day or even every hour, followed by a period of 
time after which the date intervals are slightly larger. An example history could be end of day values for 3 months followed by another
3 months of end of week values. So the as of dates table would contain a datetime for each entry to match this. 
As the days pass however the as of dates table should change to reflect this with dates being removed off the end and new dates added. 
Using the example history before if a week had passed since when we had created the as of dates table
it would still contain 3 months worth of end of day values followed by 3 months of end of week values  just shifted a week forward to reflect the current date.

!!! Warning 
    At the current release of dbtvault there is no functionality that auto generates this table for you, so you will 
    have to supply this yourself. Another caveat is that even though the As of Date table can take any name, as long as it 
    is called correctly in the .yml, the column name must be called AS_OF_DATE.

___

### bridge

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/tables/pit.sql)))

Generates SQL to build a simple bridge table, starting from a hub and 'walking' through one or more associated links,
using the provided parameters.

For the current version effectivity satellite auto end dating must be enabled.

#### Usage

``` jinja
{{ dbtvault.bridge(source_model=source_model, src_pk=src_pk,
                        bridge_walk=bridge_walk,
                        as_of_dates_table=as_of_dates_table,
                        stage_tables=stage_tables,src_ldts=src_ldts) }}
```

#### Parameters

| Parameter          | Description                                         | Type             | Required?                                    |
| ------------------ | --------------------------------------------------- | ---------------- | -------------------------------------------- |
| src_pk             | Source primary key column                           | String           | <i class="fas fa-check-circle required"></i> |
| as_of_dates_table  | Name for the AS OF DATE table                       | String           | <i class="fas fa-check-circle required"></i> |
| bridge_walk        | Dictionary of bridge reference mappings             | Mapping          | <i class="fas fa-check-circle required"></i> |
| source_model       | Hub model name                                      | String           | <i class="fas fa-check-circle required"></i> |
| stage_tables       | List of stage table load date timestamps            | String           | <i class="fas fa-check-circle required"></i> |
| src_ldts           | Source load date timestamp                          | String           | <i class="fas fa-check-circle required"></i> |

!!! tip
    [Read the tutorial](tutorial/tut_bridges.md) for more details

#### Example Metadata

[See examples](metadata.md#bridge-tables)

#### Example Output

=== "Snowflake"

    === "Base Load"

        ```sql
        WITH as_of AS (
             SELECT a.AS_OF_DATE
             FROM DBTVAULT.TEST.AS_OF_DATE AS a
             WHERE a.AS_OF_DATE <= CURRENT_DATE()
        ),

        new_rows AS (
            SELECT
                a.CUSTOMER_PK
                ,b.AS_OF_DATE
                ,LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK AS LINK_CUSTOMER_ORDER_PK
                ,EFF_SAT_CUSTOMER_ORDER.END_DATE AS EFF_SAT_CUSTOMER_ORDER_ENDDATE
                ,EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME AS EFF_SAT_CUSTOMER_ORDER_LOADDATE
                ,LINK_ORDER_PRODUCT.ORDER_PRODUCT_PK AS LINK_ORDER_PRODUCT_PK
                ,EFF_SAT_ORDER_PRODUCT.END_DATE AS EFF_SAT_ORDER_PRODUCT_ENDDATE
                ,EFF_SAT_ORDER_PRODUCT.LOAD_DATETIME AS EFF_SAT_ORDER_PRODUCT_LOADDATE
            FROM DBTVAULT.TEST.HUB_CUSTOMER AS a
            INNER JOIN AS_OF AS b
                ON (1=1)
            LEFT JOIN DBTVAULT.TEST.LINK_CUSTOMER_ORDER AS LINK_CUSTOMER_ORDER
                ON a.CUSTOMER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_FK
            INNER JOIN DBTVAULT.TEST.EFF_SAT_CUSTOMER_ORDER AS EFF_SAT_CUSTOMER_ORDER
                ON EFF_SAT_CUSTOMER_ORDER.CUSTOMER_ORDER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK
                AND EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME <= b.AS_OF_DATE
            LEFT JOIN DBTVAULT.TEST.LINK_ORDER_PRODUCT AS LINK_ORDER_PRODUCT
                ON LINK_CUSTOMER_ORDER.ORDER_FK = LINK_ORDER_PRODUCT.ORDER_FK
            INNER JOIN DBTVAULT.TEST.EFF_SAT_ORDER_PRODUCT AS EFF_SAT_ORDER_PRODUCT
                ON EFF_SAT_ORDER_PRODUCT.ORDER_PRODUCT_PK = LINK_ORDER_PRODUCT.ORDER_PRODUCT_PK
                AND EFF_SAT_ORDER_PRODUCT.LOAD_DATETIME <= b.AS_OF_DATE
        ),

        all_rows AS (
            SELECT * FROM new_rows
        ),

        candidate_rows AS (
            SELECT *
                ,ROW_NUMBER() OVER (
                    PARTITION BY AS_OF_DATE,
                        LINK_CUSTOMER_ORDER_PK
                        ,LINK_ORDER_PRODUCT_PK
                    ORDER BY
                        EFF_SAT_CUSTOMER_ORDER_LOADDATE DESC
                        ,EFF_SAT_ORDER_PRODUCT_LOADDATE DESC
                    ) AS rownum
            FROM all_rows
            QUALIFY rownum = 1
        ),

        bridge AS (
            SELECT
                CUSTOMER_PK
                ,AS_OF_DATE
                ,LINK_CUSTOMER_ORDER_PK
                ,EFF_SAT_CUSTOMER_ORDER_ENDDATE
                ,LINK_ORDER_PRODUCT_PK
                ,EFF_SAT_ORDER_PRODUCT_ENDDATE
            FROM candidate_rows
            WHERE EFF_SAT_CUSTOMER_ORDER_ENDDATE = '9999-12-31 23:59:59.999'
                AND EFF_SAT_ORDER_PRODUCT_ENDDATE = '9999-12-31 23:59:59.999'
        )

        SELECT * FROM bridge    
        ```

    === "Incremental Load"

        ```sql
        WITH as_of AS (
             SELECT a.AS_OF_DATE
             FROM DBTVAULT.TEST.AS_OF_DATE AS a
             WHERE a.AS_OF_DATE <= CURRENT_DATE()
        ),

        last_safe_load_datetime AS (
            SELECT min(LOAD_DATETIME) AS LAST_SAFE_LOAD_DATETIME
            FROM (SELECT MIN(LOAD_DATETIME) AS LOAD_DATETIME FROM DBTVAULT.TEST.STG_CUSTOMER_ORDER
                  UNION ALL
                  SELECT MIN(LOAD_DATETIME) AS LOAD_DATETIME FROM DBTVAULT.TEST.STG_ORDER_PRODUCT
                 )
        ),

        as_of_grain_old_entries AS (
            SELECT DISTINCT AS_OF_DATE
            FROM DBTVAULT.TEST.BRIDGE_CUSTOMER_ORDER_PRODUCT
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
            FROM DBTVAULT.TEST.HUB_CUSTOMER AS h
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
            FROM DBTVAULT.TEST.BRIDGE_CUSTOMER_ORDER_PRODUCT AS p
            INNER JOIN DBTVAULT.TEST.HUB_CUSTOMER as h
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
                a.CUSTOMER_PK
                ,b.AS_OF_DATE
                ,LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK AS LINK_CUSTOMER_ORDER_PK
                ,EFF_SAT_CUSTOMER_ORDER.END_DATE AS EFF_SAT_CUSTOMER_ORDER_ENDDATE
                ,EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME AS EFF_SAT_CUSTOMER_ORDER_LOADDATE
                ,LINK_ORDER_PRODUCT.ORDER_PRODUCT_PK AS LINK_ORDER_PRODUCT_PK
                ,EFF_SAT_ORDER_PRODUCT.END_DATE AS EFF_SAT_ORDER_PRODUCT_ENDDATE
                ,EFF_SAT_ORDER_PRODUCT.LOAD_DATETIME AS EFF_SAT_ORDER_PRODUCT_LOADDATE
            FROM overlap_pks AS a
            INNER JOIN overlap_as_of AS b
                ON (1=1)
            LEFT JOIN DBTVAULT.TEST.LINK_CUSTOMER_ORDER AS LINK_CUSTOMER_ORDER
                ON a.CUSTOMER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_FK
            INNER JOIN DBTVAULT.TEST.EFF_SAT_CUSTOMER_ORDER AS EFF_SAT_CUSTOMER_ORDER
                ON EFF_SAT_CUSTOMER_ORDER.CUSTOMER_ORDER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK
                AND EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME <= b.AS_OF_DATE
            LEFT JOIN DBTVAULT.TEST.LINK_ORDER_PRODUCT AS LINK_ORDER_PRODUCT
                ON LINK_CUSTOMER_ORDER.ORDER_FK = LINK_ORDER_PRODUCT.ORDER_FK
            INNER JOIN DBTVAULT.TEST.EFF_SAT_ORDER_PRODUCT AS EFF_SAT_ORDER_PRODUCT
                ON EFF_SAT_ORDER_PRODUCT.ORDER_PRODUCT_PK = LINK_ORDER_PRODUCT.ORDER_PRODUCT_PK
                AND EFF_SAT_ORDER_PRODUCT.LOAD_DATETIME <= b.AS_OF_DATE
        ),

        new_rows AS (
            SELECT
                a.CUSTOMER_PK
                ,b.AS_OF_DATE
                ,LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK AS LINK_CUSTOMER_ORDER_PK
                ,EFF_SAT_CUSTOMER_ORDER.END_DATE AS EFF_SAT_CUSTOMER_ORDER_ENDDATE
                ,EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME AS EFF_SAT_CUSTOMER_ORDER_LOADDATE
                ,LINK_ORDER_PRODUCT.ORDER_PRODUCT_PK AS LINK_ORDER_PRODUCT_PK
                ,EFF_SAT_ORDER_PRODUCT.END_DATE AS EFF_SAT_ORDER_PRODUCT_ENDDATE
                ,EFF_SAT_ORDER_PRODUCT.LOAD_DATETIME AS EFF_SAT_ORDER_PRODUCT_LOADDATE
            FROM DBTVAULT.TEST.HUB_CUSTOMER AS a
            INNER JOIN NEW_ROWS_AS_OF AS b
                ON (1=1)
            LEFT JOIN DBTVAULT.TEST.LINK_CUSTOMER_ORDER AS LINK_CUSTOMER_ORDER
                ON a.CUSTOMER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_FK
            INNER JOIN DBTVAULT.TEST.EFF_SAT_CUSTOMER_ORDER AS EFF_SAT_CUSTOMER_ORDER
                ON EFF_SAT_CUSTOMER_ORDER.CUSTOMER_ORDER_PK = LINK_CUSTOMER_ORDER.CUSTOMER_ORDER_PK
                AND EFF_SAT_CUSTOMER_ORDER.LOAD_DATETIME <= b.AS_OF_DATE
            LEFT JOIN DBTVAULT.TEST.LINK_ORDER_PRODUCT AS LINK_ORDER_PRODUCT
                ON LINK_CUSTOMER_ORDER.ORDER_FK = LINK_ORDER_PRODUCT.ORDER_FK
            INNER JOIN DBTVAULT.TEST.EFF_SAT_ORDER_PRODUCT AS EFF_SAT_ORDER_PRODUCT
                ON EFF_SAT_ORDER_PRODUCT.ORDER_PRODUCT_PK = LINK_ORDER_PRODUCT.ORDER_PRODUCT_PK
                AND EFF_SAT_ORDER_PRODUCT.LOAD_DATETIME <= b.AS_OF_DATE
        ),

        all_rows AS (
            SELECT * FROM new_rows
            UNION ALL
            SELECT * FROM overlap
        ),

        candidate_rows AS (
            SELECT *
                ,ROW_NUMBER() OVER (
                    PARTITION BY AS_OF_DATE,
                        LINK_CUSTOMER_ORDER_PK
                        ,LINK_ORDER_PRODUCT_PK
                    ORDER BY
                        EFF_SAT_CUSTOMER_ORDER_LOADDATE DESC
                        ,EFF_SAT_ORDER_PRODUCT_LOADDATE DESC
                    ) AS rownum
            FROM all_rows
            QUALIFY rownum = 1
        ),

        bridge AS (
            SELECT
                CUSTOMER_PK
                ,AS_OF_DATE
                ,LINK_CUSTOMER_ORDER_PK
                ,EFF_SAT_CUSTOMER_ORDER_ENDDATE
                ,LINK_ORDER_PRODUCT_PK
                ,EFF_SAT_ORDER_PRODUCT_ENDDATE
            FROM candidate_rows
            WHERE EFF_SAT_CUSTOMER_ORDER_ENDDATE = '9999-12-31 23:59:59.999'
                AND EFF_SAT_ORDER_PRODUCT_ENDDATE = '9999-12-31 23:59:59.999'
        )

        SELECT * FROM bridge
        ```

#### As Of Date Table Structures

An As of Date table contains a single column of dates used to construct the history in the bridge table. A typical structure will 
contain a date range and date intervals appropriate to the data mart or reporting requirement(s).

!!! Warning 
    At the current release of dbtvault there is no functionality that auto generates this table for you, so you will 
    have to supply this yourself. Another caveat is that even though the As of Date table can take any name, as long as it 
    is called correctly in the .yml, the column name must be called AS_OF_DATE.

___

## Staging Macros

###### (macros/staging)

These macros are intended for use in the staging layer.
___

### stage

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/staging/stage.sql))

Generates sql to build a staging area using the provided parameters.

#### Usage

=== "Input"

    ``` jinja 
    {{ dbtvault.stage(include_source_columns=true,
                      source_model=source_model,
                      hashed_columns=hashed_columns,
                      derived_columns=derived_columns,
                      ranked_columns=ranked_columns) }}
    ```

=== "Example Output (Snowflake)"

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
            'STG_BOOKING' AS SOURCE,
            BOOKING_DATE AS EFFECTIVE_FROM
        
            FROM source_data
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
            'STG_BOOKING' AS SOURCE,
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

#### Parameters

| Parameter              | Description                                                                 | Type           | Default    | Required?                                         |
| ---------------------- | --------------------------------------------------------------------------- | -------------- | ---------- | ------------------------------------------------- |
| include_source_columns | If true, select all columns in the `source_model`                           | Boolean        | true       | :fontawesome-solid-minus-circle:{ .not-required } |
| source_model           | Staging model name                                                          | Mapping        | N/A        | :fontawesome-solid-check-circle:{ .required }    |
| derived_columns        | Mappings of column names and their value                                    | Mapping        | none       | :fontawesome-solid-minus-circle:{ .not-required } |
| hashed_columns         | Mappings of hashes to their component columns                               | Mapping        | none       | :fontawesome-solid-minus-circle:{ .not-required } |
| ranked_columns         | Mappings of ranked columns names to their order by and partition by columns | Mapping        | none       | :fontawesome-solid-minus-circle:{ .not-required } |

#### Parameter breakdown

##### derived_columns

PLACEHOLDER

##### hashed_columns

PLACEHOLDER

##### ranked_columns

PLACEHOLDER

#### Example Metadata

[See examples](metadata.md#staging)

### stage macro configurations

The stage macro supports some syntactic sugar and shortcuts for providing metadata. These are documented in this
section.

#### Column scoping

The hashed column configuration in the stage macro may refer to columns which have been newly created in the derived
column configuration. This allows you to create hashed columns using columns defined in the `derived_columns` configuration.

For example:

=== "Snowflake"

```yaml hl_lines="3 12"
source_model: "MY_STAGE"
derived_columns:
  CUSTOMER_DOB_UK: "TO_VARCHAR(CUSTOMER_DOB::date, 'DD-MM-YYYY')"
  SOURCE: "!RAW_CUSTOMER"
  EFFECTIVE_FROM: "BOOKING_DATE"
hashed_columns:
  CUSTOMER_HK: "CUSTOMER_ID"
  HASHDIFF:
    is_hashdiff: true 
    columns:
      - "CUSTOMER_NAME"
      - "CUSTOMER_DOB_UK"
      - "CUSTOMER_PHONE"
```

Here, we create a new derived column called `CUSTOMER_DOB_UK` which formats the `CUSTOMER_DOB` column
(contained in our source) to use the UK date format, using a function. We then use the new `CUSTOMER_DOB_UK` as a
component of the `HASHDIFF` column in our `hashed_columns` configuration.

For the `ranked_columns` configuration, the derived and hashed columns are in scope, in the same way as above for the
`hashed_columns` configuration.

#### Overriding column names

It is possible to re-use column names present in the source, for **derived and hashed columns**. This is useful if you
wish to replace the value of a source column with a new value. For example, if you wish to cast a value:

```yaml
source_model: "MY_STAGE"
derived_columns:
  CUSTOMER_DOB: "TO_VARCHAR(CUSTOMER_DOB::date, 'DD-MM-YYYY')"
```

The above snippet, which includes a `derived_columns` configuration, will re-format the date in the `CUSTOMER_DOB`
column, and alias it to `CUSTOMER_DOB`, effectively replacing the value present in that column in this staging layer.

There should not be a common need for this functionality, and it is advisable to keep the old column value around for
auditability purposes, however this could be useful in some scenarios.

#### Exclude Flag (Hashed Columns)

A flag can be provided for hashdiff columns which will invert the selection of columns provided in the list of columns.

This is extremely useful when a hashdiff composed of many columns needs to be generated, and you do not wish to
individually provide all the columns.

The snippets below demonstrate the use of an `exclude_columns` flag. This will inform dbtvault to exclude the columns
listed under the `columns` key, instead of using them to create the hashdiff. 

!!! tip "Hash every column without listing them all"
    You may omit the `columns` key to hash every column. See the `Columns key not provided` example below.

##### Examples:

=== "Columns key provided"

    === "Columns in source model"
    
        ```text
        TRANSACTION_NUMBER
        CUSTOMER_DOB
        PHONE_NUMBER
        BOOKING_FK
        ORDER_FK
        CUSTOMER_HK
        LOAD_DATE
        RECORD_SOURCE
        ```
    
    === "hashed_columns configuration"
        
        ```yaml hl_lines="5"
        hashed_columns:
          CUSTOMER_HK: CUSTOMER_ID
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            exclude_columns: true
            columns:
              - BOOKING_FK
              - ORDER_FK
              - CUSTOMER_HK
              - LOAD_DATE
              - RECORD_SOURCE
        ```

    === "Equivalent hashed_columns configuration"
    
        ```yaml
        hashed_columns:
          CUSTOMER_HK: CUSTOMER_ID
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            columns:
              - TRANSACTION_NUMBER
              - CUSTOMER_DOB
              - PHONE_NUMBER
        ```

=== "Columns key not provided"

    === "Columns in source model"
    
        ```text
        TRANSACTION_NUMBER
        CUSTOMER_DOB
        PHONE_NUMBER
        BOOKING_FK
        ORDER_FK
        CUSTOMER_HK
        LOAD_DATE
        RECORD_SOURCE
        ```

    === "hashed_columns configuration"
        
        ```yaml hl_lines="5"
        hashed_columns:
          CUSTOMER_HK: CUSTOMER_ID
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            exclude_columns: true
        ```
    
    === "Equivalent hashed_columns configuration"
    
        ```yaml
        hashed_columns:
          CUSTOMER_HK: CUSTOMER_ID
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            columns:
              - TRANSACTION_NUMBER
              - CUSTOMER_DOB
              - PHONE_NUMBER
              - BOOKING_FK
              - ORDER_FK
              - CUSTOMER_HK
              - LOAD_DATE
              - RECORD_SOURCE
        ```

!!! warning

    Care should be taken if using this feature on data sources where the columns may change. 
    If you expect columns in the data source to change for any reason, it will become hard to predict what columns 
    are used to generate the hashdiff. If your component columns change, then your hashdiff output will also change,
    and it will cause unpredictable results.

#### Functions (Derived Columns)

=== "Snowflake"

```yaml hl_lines="3"
source_model: "MY_STAGE"
derived_columns:
  CUSTOMER_DOB_UK: "TO_VARCHAR(CUSTOMER_DOB::date, 'DD-MM-YYYY')"
  SOURCE: "!RAW_CUSTOMER"
  EFFECTIVE_FROM: "BOOKING_DATE"
```

In the above example we can see the use of a function to convert the date format of the `CUSTOMER_DOB` to create a new
column `CUSTOMER_DOB_UK`. Functions are incredibly useful for calculating values for new columns in derived column
configurations.

In the highlighted derived column configuration in the snippet above, the generated SQL would be the following:

```sql
SELECT TO_VARCHAR(CUSTOMER_DOB::date, 'DD-MM-YYYY') AS CUSTOMER_DOB_UK
```

!!! Note
    Please ensure that your function has valid SQL syntax on your platform, for use in this context.

#### Constants (Derived Columns)

```yaml hl_lines="4"
source_model: "MY_STAGE"
derived_columns:
  CUSTOMER_DOB_UK: "TO_VARCHAR(CUSTOMER_DOB::date, 'DD-MM-YYYY')"
  RECORD_SOURCE: "!RAW_CUSTOMER"
  EFFECTIVE_FROM: "BOOKING_DATE"
```

In the above example we define a constant value for our new `SOURCE` column. We do this by prefixing our string with an
exclamation mark: `!`. This is syntactic sugar provided by dbtvault to avoid having to escape quotes and other
characters.

As an example, in the highlighted derived column configuration in the snippet above, the generated SQL would look like
the following:

```sql hl_lines="3"
SELECT 
    TO_VARCHAR(CUSTOMER_DOB::date, 'DD-MM-YYYY') AS CUSTOMER_DOB_UK,
    'RAW_CUSTOMER' AS RECORD_SOURCE,
    BOOKING_DATE AS EFFECTIVE_FROM
```

And the data would look like:

| CUSTOMER_DOB_UK  | RECORD_SOURCE  | EFFECTIVE_FROM  |
| ---------------- | -------------- | --------------- |
| 09-06-1994       | RAW_CUSTOMER   | 01-01-2021      |
| .                | RAW_CUSTOMER   | .               |
| .                | RAW_CUSTOMER   | .               |
| 02-01-1986       | RAW_CUSTOMER   | 07-03-2021      |

#### Composite columns (Derived Columns)

```yaml hl_lines="3 4 5 6"
source_model: "MY_STAGE"
derived_columns:
  CUSTOMER_NK:
    - "CUSTOMER_ID"
    - "CUSTOMER_NAME"
    - "!DEV"
  SOURCE: "!RAW_CUSTOMER"
  EFFECTIVE_FROM: "BOOKING_DATE"
```

You can create new columns, given a list of columns to extract values from, using derived columns.

Given the following values for the columns in the above example:

- `CUSTOMER_ID` = 0011
- `CUSTOMER_NAME` = Alex

The new column, `CUSTOMER_NK`, would contain `0011||Alex||DEV`. The values get joined in the order provided, using a
double pipe `||`. Currently, this `||` join string has been hard-coded, but in future it will be user-configurable.

The values provided in the list can use any of the previously described syntax (including functions and constants) to
generate new values, as the concatenation happens in pure SQL, as follows:

```sql
SELECT CONCAT_WS('||', CUSTOMER_ID, CUSTOMER_NAME, 'DEV') AS CUSTOMER_NK
FROM MY_DB.MY_SCHEMA.MY_TABLE
```

#### Defining and configuring Ranked columns

This stage configuration is a helper for the [vault_insert_by_rank](#vault_insert_by_rank) materialisation. The `ranked_columns`
configuration allows you to define ranked columns to generate, as follows:

=== "Single item parameters"

    ```yaml
    source_model: 'MY_STAGE'
    ranked_columns:
      DBTVAULT_RANK:
        partition_by: 'CUSTOMER_HK'
        order_by: 'LOAD_DATETIME'
      SAT_BOOKING_RANK:
        partition_by: 'BOOKING_HK'
        order_by: 'LOAD_DATETIME'
    ```

=== "Generated SQL"

    ```sql
    RANK() OVER(PARTITION BY CUSTOMER_HK ORDER BY LOAD_DATETIME) AS DBTVAULT_RANK,
    RANK() OVER(PARTITION BY BOOKING_HK ORDER BY LOAD_DATETIME) AS SAT_BOOKING_RANK
    ```

===! "Multi-item parameters"

    ```yaml
    source_model: 'MY_STAGE'
    ranked_columns:
      DBTVAULT_RANK:
        partition_by: 
            - 'CUSTOMER_HK'
            - 'CUSTOMER_REF'
        order_by: 
            - 'RECORD_SOURCE'
            - 'LOAD_DATETIME'
      SAT_BOOKING_RANK:
        partition_by: 'BOOKING_HK'
        order_by: 'LOAD_DATETIME'
    ```

=== "Generated SQL"

    ```sql
    RANK() OVER(PARTITION BY CUSTOMER_HK, CUSTOMER_REF ORDER BY RECORD_SOURCE, LOAD_DATETIME) AS DBTVAULT_RANK,
    RANK() OVER(PARTITION BY BOOKING_HK ORDER BY LOAD_DATETIME) AS SAT_BOOKING_RANK
    ```

##### Dense rank

=== "Dense Rank configuration"

    ```yaml
    source_model: 'MY_STAGE'
    ranked_columns:
      DBTVAULT_RANK:
        partition_by: 
            - 'CUSTOMER_HK'
            - 'CUSTOMER_REF'
        order_by: 
            - 'RECORD_SOURCE'
            - 'LOAD_DATETIME'
        dense_rank: true
      SAT_BOOKING_RANK:
        partition_by: 'BOOKING_HK'
        order_by: 'LOAD_DATETIME'
    ```

=== "Generated SQL"

    ```sql
    DENSE_RANK() OVER(PARTITION BY CUSTOMER_HK, CUSTOMER_REF ORDER BY RECORD_SOURCE, LOAD_DATETIME) AS DBTVAULT_RANK,
    RANK() OVER(PARTITION BY BOOKING_HK ORDER BY LOAD_DATETIME) AS SAT_BOOKING_RANK
    ```

##### Order by direction

=== "Single item parameters"

    ```yaml
    source_model: 'MY_STAGE'
    ranked_columns:
      DBTVAULT_RANK:
        partition_by: 'CUSTOMER_HK'
        order_by:
           LOAD_DATETIME: DESC
      SAT_BOOKING_RANK:
        partition_by: 'BOOKING_HK'
        order_by: 'LOAD_DATETIME'
    ```

=== "Generated SQL"

    ```sql
    RANK() OVER(PARTITION BY CUSTOMER_HK ORDER BY LOAD_DATETIME DESC) AS DBTVAULT_RANK,
    RANK() OVER(PARTITION BY BOOKING_HK ORDER BY LOAD_DATETIME) AS SAT_BOOKING_RANK
    ```

===! "Multi-item parameters"

    ```yaml
    source_model: 'MY_STAGE'
    ranked_columns:
      DBTVAULT_RANK:
        partition_by: 
            - 'CUSTOMER_HK'
            - 'CUSTOMER_REF'
        order_by: 
            - 'RECORD_SOURCE': 'DESC'
            - 'LOAD_DATETIME': 'ASC'
      SAT_BOOKING_RANK:
        partition_by: 'BOOKING_HK'
        order_by: 'LOAD_DATETIME'
    ```

=== "Generated SQL"

    ```sql
    RANK() OVER(PARTITION BY CUSTOMER_HK, CUSTOMER_REF ORDER BY RECORD_SOURCE DESC, LOAD_DATETIME ASC) AS DBTVAULT_RANK,
    RANK() OVER(PARTITION BY BOOKING_HK ORDER BY LOAD_DATETIME) AS SAT_BOOKING_RANK
    ```

___

### hash_columns

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/staging/hash_columns.sql))

!!! Note 
    This is a helper macro used within the stage macro, but can be used independently.

Generates SQL to create hash keys for a provided mapping of columns names to the list of columns to hash.

### derive_columns

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/staging/derive_columns.sql))

!!! Note 
    This is a helper macro used within the stage macro, but can be used independently.

Generates SQL to create columns based off of the values of other columns, provided as a mapping from column name to
column value.

### ranked_columns

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/staging/rank_columns.sql))

!!! Note 
    This is a helper macro used within the stage macro, but can be used independently.

Generates SQL to create columns using the `RANK()` or `DENSE_RANK()` window function.

___

## Supporting Macros

###### (macros/supporting)

Supporting macros are helper functions for use in models. It should not be necessary to call these macros directly,
however they are used extensively in the [table templates](#table-templates) and may be used for your own purposes if
you wish.

___

### hash

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/supporting/hash.sql))

!!! warning

    This macro ***should not be*** used for cryptographic purposes.

    The intended use is for creating checksum-like values only, so that we may compare records consistently.
    
    [Read More](https://www.md5online.org/blog/why-md5-is-not-safe/)

!!! seealso "See Also"
    - [hash_columns](#hash_columns)
    - Read [Hashing best practises and why we hash](best_practices.md#hashing)
    for more detailed information on the purposes of this macro and what it does.
    - You may choose between `MD5` and `SHA-256` hashing.
    [Learn how](best_practices.md#choosing-a-hashing-algorithm-in-dbtvault)
    
A macro for generating hashing SQL for columns.

#### Usage

=== "Input"

    ```yaml
    {{ dbtvault.hash('CUSTOMERKEY', 'CUSTOMER_HK') }},
    {{ dbtvault.hash(['CUSTOMERKEY', 'PHONE', 'DOB', 'NAME'], 'HASHDIFF', true) }}
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

    === "SHA"

        ```sql
        CAST(SHA2_BINARY(CONCAT_WS('||',
        IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'),
        IFNULL(NULLIF(UPPER(TRIM(CAST(DOB AS VARCHAR))), ''), '^^'), 
        IFNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR))), ''), '^^')
        )) AS BINARY(32)) AS HASHDIFF
        ```

!!! tip 
    The [hash_columns](#hash_columns) macro can be used to simplify the hashing process and generate multiple hashes
    with one macro.

#### Parameters

| Parameter        |  Description                                     | Type                | Required?                                        |
| ---------------- | -----------------------------------------------  | ------------------- | ------------------------------------------------ |
| columns          |  Columns to hash on                              | List[String]/String | :fontawesome-solid-check-circle:{ .required }     |
| alias            |  The name to give the hashed column              | String              | :fontawesome-solid-check-circle:{ .required }     |
| is_hashdiff      |  Will alpha sort columns if true, default false. | Boolean             | :fontawesome-solid-minus-circle:{ .not-required } |      

___

### prefix

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/supporting/prefix.sql))

A macro for quickly prefixing a list of columns with a string.

#### Parameters

| Parameter        |  Description                  | Type         | Required?                                      |
| ---------------- | ----------------------------- | ------------ | ---------------------------------------------- |
| columns          |  A list of column names       | List[String] | :fontawesome-solid-check-circle:{ .required } |
| prefix_str       |  The prefix for the columns   | String       | :fontawesome-solid-check-circle:{ .required } |

#### Usage

=== "Input"

    ```sql 
    {{ dbtvault.prefix(['CUSTOMERKEY', 'DOB', 'NAME', 'PHONE'], 'a') }} {{ dbtvault.prefix(['CUSTOMERKEY'], 'a') }}
    ```

=== "Output"

    ```sql 
    a.CUSTOMERKEY, a.DOB, a.NAME, a.PHONE a.CUSTOMERKEY
    ```

!!! Note
    Single columns must be provided as a 1-item list.

___

## Internal

###### (macros/internal)

Internal macros are used by other macros provided by dbtvault. They process provided metadata and should not need to
be called directly.

___

## Materialisations

###### (macros/materialisations)

Materialisations dictate how a model is created in the database.

dbt itself comes with 4 standard materialisations:

- Table
- View
- Incremental
- Ephemeral

[Read more about materialisations here](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/materializations/)

In dbtvault, we have created custom materialisations which support Data Vault 2.0 specific use cases. These are detailed below.

### vault_insert_by_period

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/materialisations/vault_insert_by_period_materialization.sql))

This materialisation is based on
the [insert_by_period](https://github.com/dbt-labs/dbt-utils/blob/master/macros/materializations/insert_by_period_materialization.sql)
materialisation developed by dbt Labs for the [dbt-utils](https://github.com/dbt-labs/dbt-utils)
package.

We have re-purposed it and provided support for Snowflake, as well as added a number of convenience features.

Features include:

- Idempotent loading
- Inference of date range to load with
- Manually configurable date range to load with
- Configurable granularity (day, month, year etc.)

The purpose of the materialisation is to insert data into a table iteratively and periodically, using a configured date
range. More detail on how this works is below.

#### Usage

=== "Manual Load range #1"

    ```jinja 
    {{ config(materialized='vault_insert_by_period', timestamp_field='LOAD_DATE', period='day',
    start_date='2020-01-30') }}
    
    {{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                        src_start_date=src_start_date, src_end_date=src_end_date,
                        src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                        source_model=source_model) }}
    ```

=== "Manual Load range #2"

    ```jinja 
    {{ config(materialized='vault_insert_by_period', timestamp_field='LOAD_DATE', period='day',
    start_date='2020-01-30', stop_date='2020-04-30') }}
    
    {{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                        src_start_date=src_start_date, src_end_date=src_end_date,
                        src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                        source_model=source_model) }}
    ```

=== "Manual Load range #3"

    ```jinja 
    {{ config(materialized='vault_insert_by_period', timestamp_field='LOAD_DATE', period='day',
    start_date='2020-01-30', stop_date='2020-04-30', date_source_models=var('source_model')) }}
    
    {{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                        src_start_date=src_start_date, src_end_date=src_end_date,
                        src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                        source_model=source_model) }}
    ```

=== "Inferred Load range"

    ```jinja 
    {{ config(materialized='vault_insert_by_period', timestamp_field='LOAD_DATE', period='day',
    date_source_models=var('source_model')) }}
    
    {{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                        src_start_date=src_start_date, src_end_date=src_end_date,
                        src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                        source_model=source_model) }}
    ```

#### Initial/Base Load vs. Incremental Load

Due to the way materialisations currently work in dbt, the model which the `vault_insert_by_period` materialisation is
applied to, must be run twice to complete a full load.

The first time a model with the materialisation applied is run, a `BASE LOAD` is executed. This loads all data for the
first period in the load date range (e.g. The first day's data). All subsequent runs of the same model will execute
incremental loads for each consecutive period.

The first period load will be repeated but no duplicates should be inserted when using dbtvault macros.

##### Run Output

Examples of output for dbt runs using the [eff_sat](#eff_sat) macro and this materialisation.

=== "Initial/Base load"

    ```text
    15:24:08 | Concurrency: 4 threads (target='snowflake')
    15:24:08 | 15:24:08 | 1 of 1 START vault_insert_by_period model TEST.EFF_SAT..... [RUN]
    15:24:10 | 1 of 1 OK created vault_insert_by_period model TEST.EFF_SAT [BASE LOAD 1 in 1.78s]
    15:24:10 | 15:24:10 | Finished running 1 vault_insert_by_period model in 3.99s.
    ```

=== "Incremental load"

    ```text 
    15:24:16 | Concurrency: 4 threads (target='snowflake')
    15:24:16 | 15:24:16 | 1 of 1 START vault_insert_by_period model TEST.EFF_SAT..... [RUN]
    15:24:17 + Running for day 1 of 4 (2020-01-10) [model.dbtvault_test.EFF_SAT]
    15:24:18 + Ran for day 1 of 4 (2020-01-10); 0 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:18 + Running for day 2 of 4 (2020-01-11) [model.dbtvault_test.EFF_SAT]
    15:24:20 + Ran for day 2 of 4 (2020-01-11); 0 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:20 + Running for day 3 of 4 (2020-01-12) [model.dbtvault_test.EFF_SAT]
    15:24:21 + Ran for day 3 of 4 (2020-01-12); 2 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:22 + Running for day 4 of 4 (2020-01-13) [model.dbtvault_test.EFF_SAT]
    15:24:24 + Ran for day 4 of 4 (2020-01-13); 2 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:24 | 1 of 1 OK created vault_insert_by_period model TEST.EFF_SAT [INSERT 4 in 8.13s]
    15:24:25 | 15:24:25 | Finished running 1 vault_insert_by_period model in 10.24s.
    ```

#### Configuring the load date range

The start and finish date of the load can be configured in a number of different ways. Depending on how the
materialisation is configured, the start and end of the load will get defined differently, as shown in the table below.

| Configuration                | Outcome                                                                                                                  | Usage                | 
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------ | -------------------- |
| `start_date`                 |  The load will start at `start_date`, and the `stop_date` will be set to the **current
date**.                           | Manual Load range #1 |
| `start_date` and `stop_date` |  The load will start at `start_date`, and stop at `stop_date`                                                            | Manual Load range #2 |                  
| `date_source_models`         |  The models will be unioned together, and the minimum and maximum dates extracted from the data in the `timestamp_field` | Inferred Load range  |                 
| All three config options     |  Manually provided configuration acts as an override. The load will start at `start_date`, and stop at `stop_date`       | Manual Load range #3 |    

Please refer to the _Usage_ section above to see examples.

#### Configuration Options

| Configuration      |  Description                                         | Type                 | Default | Required?                                          |
| ------------------ | ---------------------------------------------------- | -------------------- | ------- | -------------------------------------------------- |
| timestamp_field    |  A list of column names                              | List[String]         | None    | :fontawesome-solid-check-circle:{ .required }     |
| period             |  Time period to load over                            | String               | day     | :fontawesome-solid-minus-circle:{ .not-required }  |
| start_date         |  The date to start the load from                     | String (YYYY-MM-DD)  | None    | See: Configuring the load date range (above)       |
| stop_date          |  The date to stop the load on                        | String (YYYY-MM-DD)  | None    | See: Configuring the load date range (above)       |
| date_source_models |  A list of models containing the timestamp_field     | List[String]/String  | None    | See: Configuring the load date range (above)       |

#### Period

The period configuration option allows us to configure the granularity of the load.

The naming varies per platform, though some common examples are:

- hour
- day
- month
- year

See below for the platform-specific documentation.

- [Snowflake](https://docs.snowflake.com/en/sql-reference/functions-date-time.html#supported-date-and-time-parts)

#### Automatic load range inference

Providing a list of models with the `date_source_models` configuration option, will automatically load all data from the
source with date or date-times between the minimum and maximum values contained in the `timestamp_field` column.

When using the dbtvault table template macros, `date_source_models` should be the same as the `source_model` attribute
in the macro.

This does not necessarily have to be the case however, and it is possible to create a waterlevel-like table as follows:

=== "waterlevel.sql"

    | TYPE  | LOAD_DATE      | 
    | ----- | -------------- | 
    | Start | 2020-01-30     | 
    | Stop  | 2020-04-30     |

Where `LOAD_DATE` is provided to the materialisation as the `timestamp_field`, and `date_source_models` is provided
as `waterlevel` (the model name).

#### Using the materialisation with non-dbtvault SQL

Every [table template macro](macros.md#table-templates) includes a `__PERIOD_FILTER__` string in its SQL when used in
conjunction with this materialisation.

At runtime, this string is replaced with SQL which applies conditions to filter the dates contained in
the `timestamp_field` to those specified in the load date range. If you are only using dbtvault table template macros
with this materialisation, then there is no need for any additional work.

However, If you are writing your own models and wish to use this materialisation, then you must include
a `WHERE __PERIOD_FILTER__`
somewhere appropriate in your model. A CTE which selects from your source model and then includes the placeholder,
should provide best results.

See the [hub](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/tables/hub.sql) source code for 
a demonstration of this.

#### Idempotent loads

This materialisation supports idempotent loads when used with dbtvault macros. When calculating the `start` and `stop`
dates of the load, a `COALESCE` function is applied. This `COALESCE` call compares the maximum timestamp contained in
the `timestamp_field`, and the provided or inferred `start_date` and sets the `start_date`
to whatever is larger (more recent). This means that any aborted loads will continue where they left off, and any
duplicate loads will not have any effect (if using dbtvault macros).

If you wish support idempotent loads in your own models using this materialisation, the best approach is to
use `LEFT OUTER JOINS` to ensure duplicate records do not get loaded.

### vault_insert_by_rank

([view source](https://github.com/Datavault-UK/dbtvault/blob/release/0.7.8/macros/materialisations/vault_insert_by_rank_materialization.sql))

The `vault_insert_by_rank` custom materialisation provides the means to iteratively load raw vault structures from an
arbitrary rank column, created in the staging layer.

The `RANK()` window function is used to rank (using an `ORDER BY` clause) a row within the current 'window' of the
function, which is defined by the
`PARTITION BY` clause.

The custom materialisation uses this value as the value to iterate over when loading; a row with rank 1 will be loaded
prior to a row with rank 2, and so on.

This materialisation can be used to correctly load temporal structures (such as satellites) where records may have
millisecond timings between them, by partitioning by the primary/hash key of a table, and ordering by the timestamp
column.

#### Usage

```jinja
{{ config(materialized='vault_insert_by_rank', rank_column='DBTVAULT_RANK', rank_source_models='MY_STAGE') }}

{{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                    src_start_date=src_start_date, src_end_date=src_end_date,
                    src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                    source_model=source_model) }}
```

#### Configuration Options

| Configuration      |  Description                                         | Type                 | Default | Required?                                        |
| ------------------ | ---------------------------------------------------- | -------------------  | ------- | ------------------------------------------------ |
| rank_column        |  The column name containing the rank values          | String               | None    | :fontawesome-solid-check-circle:{ .required }   |
| rank_source_models |  A list of model names containing the `rank_column`  | List[String]         | None    | :fontawesome-solid-check-circle:{ .required }   |

#### Creating a rank column

A rank column can be created one of three ways:

1. Manually creating it in a model prior to the staging layer, and using this model as the stage's `source_model`.

2. Using the `ranked_columns` configuration of the [stage](#stage) macro

    ```yaml
    source_model: "MY_STAGE"
    ranked_columns:
      DBTVAULT_RANK:
        partition_by: "CUSTOMER_HK"
        order_by: "LOAD_DATETIME"
    ```

3. Using the `derived_columns` configuration of the [stage](#stage) macro

    ```yaml
    source_model: "MY_STAGE"
    derived_columns:
      DBTVAULT_RANK: "RANK() OVER(PARTITION BY CUSTOMER_HK ORDER BY LOAD_DATETIME)"
    ```

!!! note

    [Read more](#defining-ranked-columns) about defining ranked columns.

#### Which option?

- Method #2 is recommended, as makes it easier for rank columns to use user-defined derived or hashed columns created in the
  same staging layer.
- Method #3 is similar, except it will not have hashed or derived column definitions available to it.

!!! warning "Check your rank"

    It is important that once a rank column is created, it should be sense checked for correct and expected ordering. If your ranking is incorrect according to
    the business, then loading will not be executed correctly.