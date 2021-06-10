## Global usage notes

### source_model syntax

dbt itself supports references to data via
the `ref()` [function](https://docs.getdbt.com/reference/dbt-jinja-functions/ref/) for models, and the `source()`
function for [dbt sources](https://docs.getdbt.com/docs/building-a-dbt-project/using-sources/).

dbtvault provides the means for specifying sources for Data Vault structures with a `source_model` argument.

This behaves differently for the [stage](#stage) macro, which supports either style, shown below:

##### ref style

```yaml
stg_customer:
  source_model: 'raw_customer'
```

##### source style

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

## Table templates

###### (macros/tables)

These macros are the core of the package and can be called in your models to build the different types of tables needed
for your Data Vault.

### hub

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/tables/hub.sql))

Generates SQL to build a hub table using the provided parameters.

#### Usage

``` jinja

{{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter     | Description                                         | Type                 | Required?                                    |
| ------------- | --------------------------------------------------- | -------------------- | -------------------------------------------- |
| src_pk        | Source primary key column                           | List[String]/String  | <i class="fas fa-check-circle required"></i> |
| src_nk        | Source natural key column                           | List[String]/String  | <i class="fas fa-check-circle required"></i> |
| src_ldts      | Source load date timestamp column                   | String               | <i class="fas fa-check-circle required"></i> |
| src_source    | Name of the column containing the source ID         | List[String]/String  | <i class="fas fa-check-circle required"></i> |
| source_model  | Staging model name                                  | List[String]/String  | <i class="fas fa-check-circle required"></i> |

!!! tip
[Read the tutorial](tutorial/tut_hubs.md) for more details

#### Example Metadata

[See examples](metadata.md#hubs)

#### Example Output

=== "Snowflake"

    === "Single-Source (Base Load)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_PK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
        )

        SELECT * FROM records_to_insert
        ```
    
    === "Single-Source (Subsequent Loads)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_PK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
            LEFT JOIN DBTVAULT.TEST.hub AS d
            ON a.CUSTOMER_PK = d.CUSTOMER_PK
            WHERE d.CUSTOMER_PK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
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
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE, RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union
            WHERE CUSTOMER_PK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_PK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Subsequent Loads)"
 
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
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
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE, RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union
            WHERE CUSTOMER_PK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_PK, a.CUSTOMER_ID, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
            LEFT JOIN DBTVAULT.TEST.hub AS d
            ON a.CUSTOMER_PK = d.CUSTOMER_PK
            WHERE d.CUSTOMER_PK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

___

### link

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/tables/link.sql))

Generates sql to build a link table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                 src_source=src_source, source_model=source_model) }}
```                                             

#### Parameters

| Parameter     | Description                                         | Type                 | Required?                                    |
| ------------- | --------------------------------------------------- | ---------------------| -------------------------------------------- |
| src_pk        | Source primary key column                           | List[String]/String  | <i class="fas fa-check-circle required"></i> |
| src_fk        | Source foreign key column(s)                        | List[String]         | <i class="fas fa-check-circle required"></i> |
| src_ldts      | Source load date timestamp column                   | String               | <i class="fas fa-check-circle required"></i> |
| src_source    | Name of the column containing the source ID         | List[String]/String  | <i class="fas fa-check-circle required"></i> |
| source_model  | Staging model name                                  | List[String]/String  | <i class="fas fa-check-circle required"></i> |

!!! tip
[Read the tutorial](tutorial/tut_links.md) for more details

#### Example Metadata

[See examples](metadata.md#links)

#### Example Output

=== "Snowflake"

    === "Single-Source (Base Load)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_PK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_PK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Single-Source (Subsequent Loads)"
    
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_PK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_PK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_1 AS a
            LEFT JOIN DBTVAULT.TEST.link AS d
            ON a.CUSTOMER_PK = d.CUSTOMER_PK
            WHERE d.CUSTOMER_PK IS NULL
        )
        
        SELECT * FROM records_to_insert
                
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_PK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_PK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
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
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE, RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union
            WHERE ORDER_FK IS NOT NULL
            AND BOOKING_FK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_PK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Subsequent Loads)"
 
        ```sql
        WITH row_rank_1 AS (
            SELECT CUSTOMER_PK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT.TEST.MY_STAGE
            QUALIFY row_number = 1
        ),
        
        row_rank_2 AS (
            SELECT CUSTOMER_PK, ORDER_FK, BOOKING_FK, LOAD_DATE, RECORD_SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
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
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE, RECORD_SOURCE ASC
                   ) AS row_rank_number
            FROM stage_union
            WHERE ORDER_FK IS NOT NULL
            AND BOOKING_FK IS NOT NULL
            QUALIFY row_rank_number = 1
        ),
        
        records_to_insert AS (
            SELECT a.CUSTOMER_PK, a.ORDER_FK, a.BOOKING_FK, a.LOAD_DATE, a.RECORD_SOURCE
            FROM row_rank_union AS a
            LEFT JOIN DBTVAULT.TEST.link AS d
            ON a.CUSTOMER_PK = d.CUSTOMER_PK
            WHERE d.CUSTOMER_PK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

___

### t_link

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/tables/t_link.sql))

Generates sql to build a transactional link table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.t_link(src_pk=src_pk, src_fk=src_fk, src_payload=src_payload,
                   src_eff=src_eff, src_ldts=src_ldts, 
                   src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter     | Description                                         | Type                | Required?                                        |
| ------------- | --------------------------------------------------- | ------------------- | ------------------------------------------------ |
| src_pk        | Source primary key column                           | List[String]/String | <i class="fas fa-check-circle required"></i>     |
| src_fk        | Source foreign key column(s)                        | List[String]        | <i class="fas fa-check-circle required"></i>     |
| src_payload   | Source payload column(s)                            | List[String]        | <i class="fas fa-minus-circle not-required"></i> |
| src_eff       | Source effective from column                        | String              | <i class="fas fa-check-circle required"></i>     |
| src_ldts      | Source load date timestamp column                   | String              | <i class="fas fa-check-circle required"></i>     |
| src_source    | Name of the column containing the source ID         | String              | <i class="fas fa-check-circle required"></i>     |
| source_model  | Staging model name                                  | String              | <i class="fas fa-check-circle required"></i>     |

!!! tip
[Read the tutorial](tutorial/tut_t_links.md) for more details

#### Example Metadata

[See examples](metadata.md#transactional-links)

#### Example Output

=== "Snowflake"

    === "Base Load"
    
        ```sql
        WITH stage AS (
            SELECT TRANSACTION_PK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.MY_STAGE
        ),
        records_to_insert AS (
            SELECT DISTINCT stg.TRANSACTION_PK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH stage AS (
            SELECT TRANSACTION_PK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM DBTVAULT.TEST.raw_stage_hashed
        ),
        records_to_insert AS (
            SELECT DISTINCT stg.TRANSACTION_PK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
            LEFT JOIN DBTVAULT.TEST.t_link AS tgt
            ON stg.TRANSACTION_PK = tgt.TRANSACTION_PK
            WHERE tgt.TRANSACTION_PK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```

___

### sat

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/tables/sat.sql))

Generates sql to build a satellite table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.sat(src_pk=src_pk, src_hashdiff=src_hashdiff, src_payload=src_payload,
                src_eff=src_eff, src_ldts=src_ldts, 
                src_source=src_source, source_model=source_model) }}
```

#### Parameters

| Parameter     | Description                                         | Type             | Required?                                        |
| ------------- | --------------------------------------------------- | ---------------- | ------------------------------------------------ |
| src_pk        | Source primary key column                           | String           | <i class="fas fa-check-circle required"></i>     |
| src_hashdiff  | Source hashdiff column                              | String           | <i class="fas fa-check-circle required"></i>     |
| src_payload   | Source payload column(s)                            | List[String]     | <i class="fas fa-check-circle required"></i>     |
| src_eff       | Source effective from column                        | String           | <i class="fas fa-minus-circle not-required"></i> |
| src_ldts      | Source load date timestamp column                   | String           | <i class="fas fa-check-circle required"></i>     |
| src_source    | Name of the column containing the source ID         | String           | <i class="fas fa-check-circle required"></i>     |
| source_model  | Staging model name                                  | String           | <i class="fas fa-check-circle required"></i>     |

!!! tip
[Read the tutorial](tutorial/tut_satellites.md) for more details

#### Example Metadata

[See examples](metadata.md#satellites)

#### Example Output

=== "Snowflake"

    === "Base Load"
    
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_PK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.MY_STAGE AS a
            WHERE CUSTOMER_PK IS NOT NULL
        ),

        records_to_insert AS (
            SELECT DISTINCT e.CUSTOMER_PK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
        )

        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_PK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.MY_STAGE AS a
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        
        update_records AS (
            SELECT a.CUSTOMER_PK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.SATELLITE as a
            JOIN source_data as b
            ON a.CUSTOMER_PK = b.CUSTOMER_PK
        ),
        
        latest_records AS (
            SELECT c.CUSTOMER_PK, c.HASHDIFF, c.LOAD_DATE,
                RANK() OVER (
                   PARTITION BY c.CUSTOMER_PK
                   ORDER BY c.LOAD_DATE DESC
                   ) AS rank
            FROM update_records as c
            QUALIFY rank = 1
        ),
        
        records_to_insert AS (
            SELECT DISTINCT e.CUSTOMER_PK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
            LEFT JOIN latest_records
            ON latest_records.CUSTOMER_PK = e.CUSTOMER_PK
            WHERE latest_records.HASHDIFF != e.HASHDIFF
            OR latest_records.HASHDIFF IS NULL
        )
        
        SELECT * FROM records_to_insert
    ```

#### Hashdiff Aliasing

If you have multiple satellites using a single stage as its data source, then you will need to use [hashdiff aliasing](best_practices.md#hashdiff-aliasing)

___

### eff_sat

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/tables/eff_sat.sql))

Generates sql to build an effectivity satellite table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                    src_start_date=src_start_date, src_end_date=src_end_date,
                    src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                    source_model=source_model) }}
```

#### Parameters

| Parameter      | Description                                         | Type                    | Required?                                    |
| -------------- | --------------------------------------------------- | ----------------------- | -------------------------------------------- |
| src_pk         | Source primary key column                           | String                  | <i class="fas fa-check-circle required"></i> |
| src_dfk        | Source driving foreign key column                   | List[String]/String     | <i class="fas fa-check-circle required"></i> |
| src_sfk        | Source secondary foreign key column                 | List[String]/String     | <i class="fas fa-check-circle required"></i> |
| src_start_date | Source start date column                            | String                  | <i class="fas fa-check-circle required"></i> |
| src_end_date   | Source end date column                              | String                  | <i class="fas fa-check-circle required"></i> |
| src_eff        | Source effective from column                        | String                  | <i class="fas fa-check-circle required"></i> |
| src_ldts       | Source load date timestamp column                   | String                  | <i class="fas fa-check-circle required"></i> |
| src_source     | Name of the column containing the source ID         | String                  | <i class="fas fa-check-circle required"></i> |
| source_model   | Staging model name                                  | String                  | <i class="fas fa-check-circle required"></i> |

!!! tip
[Read the tutorial](tutorial/tut_eff_satellites.md) for more details

#### Example Metadata

[See examples](metadata.md#effectivity-satellites)

#### Example Output

=== "Snowflake"

    === "Base Load"
        
        ```sql
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_PK, a.ORDER_PK, a.CUSTOMER_PK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_PK IS NOT NULL
            AND a.CUSTOMER_PK IS NOT NULL
    ),
    
        records_to_insert AS (
            SELECT i.ORDER_CUSTOMER_PK, i.ORDER_PK, i.CUSTOMER_PK, i.START_DATE, i.END_DATE, i.EFFECTIVE_FROM, i.LOAD_DATETIME, i.SOURCE
            FROM source_data AS i
    )
    
        SELECT * FROM records_to_insert
        ```

    === "With auto end-dating (Subsequent)"
    
        ```sql
        WITH source_data AS (
            SELECT a.ORDER_CUSTOMER_PK, a.ORDER_PK, a.CUSTOMER_PK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_PK IS NOT NULL
            AND a.CUSTOMER_PK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT b.ORDER_CUSTOMER_PK, b.ORDER_PK, b.CUSTOMER_PK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATETIME, b.SOURCE,
                   ROW_NUMBER() OVER (
                        PARTITION BY b.ORDER_CUSTOMER_PK
                        ORDER BY b.LOAD_DATETIME DESC
                   ) AS row_num
            FROM DBTVAULT.TEST.EFF_SAT_ORDER_CUSTOMER AS b
            QUALIFY row_num = 1
        ),
        
        latest_open AS (
            SELECT c.ORDER_CUSTOMER_PK, c.ORDER_PK, c.CUSTOMER_PK, c.START_DATE, c.END_DATE, c.EFFECTIVE_FROM, c.LOAD_DATETIME, c.SOURCE
            FROM latest_records AS c
            WHERE TO_DATE(c.END_DATE) = TO_DATE('9999-12-31')
        ),
        
        latest_closed AS (
            SELECT d.ORDER_CUSTOMER_PK, d.ORDER_PK, d.CUSTOMER_PK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.SOURCE
            FROM latest_records AS d
            WHERE TO_DATE(d.END_DATE) != TO_DATE('9999-12-31')
        ),
        
        new_open_records AS (
            SELECT DISTINCT
                f.ORDER_CUSTOMER_PK, f.ORDER_PK, f.CUSTOMER_PK, f.START_DATE, f.END_DATE, f.EFFECTIVE_FROM, f.LOAD_DATETIME, f.SOURCE
            FROM source_data AS f
            LEFT JOIN latest_records AS lr
            ON f.ORDER_CUSTOMER_PK = lr.ORDER_CUSTOMER_PK
            WHERE lr.ORDER_CUSTOMER_PK IS NULL
        ),
        
        new_reopened_records AS (
            SELECT DISTINCT
                lc.ORDER_CUSTOMER_PK,
                lc.ORDER_PK, lc.CUSTOMER_PK,
                lc.START_DATE AS START_DATE,
                g.END_DATE AS END_DATE,
                g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                g.LOAD_DATETIME,
                g.SOURCE
            FROM source_data AS g
            INNER JOIN latest_closed lc
            ON g.ORDER_CUSTOMER_PK = lc.ORDER_CUSTOMER_PK
        ),
        
        new_closed_records AS (
            SELECT DISTINCT
                lo.ORDER_CUSTOMER_PK,
                lo.ORDER_PK, lo.CUSTOMER_PK,
                lo.START_DATE AS START_DATE,
                h.EFFECTIVE_FROM AS END_DATE,
                h.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                h.LOAD_DATETIME,
                lo.SOURCE
            FROM source_data AS h
            INNER JOIN latest_open AS lo
            ON lo.ORDER_PK = h.ORDER_PK
            WHERE (lo.CUSTOMER_PK <> h.CUSTOMER_PK)
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
            SELECT a.ORDER_CUSTOMER_PK, a.ORDER_PK, a.CUSTOMER_PK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.SOURCE
            FROM DBTVAULT.TEST.STG_ORDER_CUSTOMER AS a
            WHERE a.ORDER_PK IS NOT NULL
            AND a.CUSTOMER_PK IS NOT NULL
        ),
        
        latest_records AS (
            SELECT b.ORDER_CUSTOMER_PK, b.ORDER_PK, b.CUSTOMER_PK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATETIME, b.SOURCE,
                   ROW_NUMBER() OVER (
                        PARTITION BY b.ORDER_CUSTOMER_PK
                        ORDER BY b.LOAD_DATETIME DESC
                   ) AS row_num
            FROM DBTVAULT.TEST.EFF_SAT_ORDER_CUSTOMER AS b
            QUALIFY row_num = 1
        ),
        
        latest_open AS (
            SELECT c.ORDER_CUSTOMER_PK, c.ORDER_PK, c.CUSTOMER_PK, c.START_DATE, c.END_DATE, c.EFFECTIVE_FROM, c.LOAD_DATETIME, c.SOURCE
            FROM latest_records AS c
            WHERE TO_DATE(c.END_DATE) = TO_DATE('9999-12-31')
        ),
        
        latest_closed AS (
            SELECT d.ORDER_CUSTOMER_PK, d.ORDER_PK, d.CUSTOMER_PK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.SOURCE
            FROM latest_records AS d
            WHERE TO_DATE(d.END_DATE) != TO_DATE('9999-12-31')
        ),
        
        new_open_records AS (
            SELECT DISTINCT
                f.ORDER_CUSTOMER_PK, f.ORDER_PK, f.CUSTOMER_PK, f.START_DATE, f.END_DATE, f.EFFECTIVE_FROM, f.LOAD_DATETIME, f.SOURCE
            FROM source_data AS f
            LEFT JOIN latest_records AS lr
            ON f.ORDER_CUSTOMER_PK = lr.ORDER_CUSTOMER_PK
            WHERE lr.ORDER_CUSTOMER_PK IS NULL
        ),
        
        new_reopened_records AS (
            SELECT DISTINCT
                lc.ORDER_CUSTOMER_PK,
                lc.ORDER_PK, lc.CUSTOMER_PK,
                lc.START_DATE AS START_DATE,
                g.END_DATE AS END_DATE,
                g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
                g.LOAD_DATETIME,
                g.SOURCE
            FROM source_data AS g
            INNER JOIN latest_closed lc
            ON g.ORDER_CUSTOMER_PK = lc.ORDER_CUSTOMER_PK
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
{{ config(
    is_auto_end_dating=true
) }}

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

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/tables/ma_sat.sql))

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
| src_pk         | Source primary key column                           | String           | <i class="fas fa-check-circle required"></i>      |
| src_cdk        | Source child dependent key(s) column(s)             | List[String]     | <i class="fas fa-check-circle required"></i>      |
| src_hashdiff   | Source hashdiff column                              | String           | <i class="fas fa-check-circle required"></i>      |
| src_payload    | Source payload column(s)                            | List[String]     | <i class="fas fa-check-circle required"></i>      |
| src_eff        | Source effective from column                        | String           | <i class="fas fa-minus-circle not-required"></i>  |
| src_ldts       | Source load date timestamp column                   | String           | <i class="fas fa-check-circle required"></i>      |
| src_source     | Name of the column containing the source ID         | String           | <i class="fas fa-check-circle required"></i>      |
| source_model   | Staging model name                                  | String           | <i class="fas fa-check-circle required"></i>      |

!!! tip
    [Read the tutorial](tutorial/tut_multi_active_satellites.md) for more details

#### Example Metadata

[See examples](metadata.md#multi-active-satellites-mas)

#### Example Output

=== "Snowflake"
    
    === "Base Load"
    
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_PK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT.TEST.MY_STAGE AS a
        ),
        
        records_to_insert AS (
            SELECT stage.CUSTOMER_PK, stage.HASHDIFF, stage.CUSTOMER_PHONE, stage.CUSTOMER_NAME, stage.EFFECTIVE_FROM, stage.LOAD_DATE, stage.SOURCE
            FROM source_data AS stage
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH source_data AS (
            SELECT a.CUSTOMER_PK, a.HASHDIFF, a.CUSTOMER_PHONE, a.CUSTOMER_NAME, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            ,COUNT(DISTINCT a.HASHDIFF, a.CUSTOMER_PHONE )
                OVER (PARTITION BY a.CUSTOMER_PK) AS source_count
            FROM DBTVAULT.TEST.MY_STAGE AS a
            WHERE a.CUSTOMER_PK IS NOT NULL
                AND a.CUSTOMER_PHONE IS NOT NULL
        ),
        latest_records AS (
            SELECT *, COUNT(DISTINCT latest_selection.HASHDIFF, latest_selection.CUSTOMER_PHONE )
                    OVER (PARTITION BY latest_selection.CUSTOMER_PK) AS target_count
            FROM (
                SELECT target_records.CUSTOMER_PHONE, target_records.CUSTOMER_PK, target_records.HASHDIFF, target_records.LOAD_DATE
                    ,RANK() OVER (PARTITION BY target_records.CUSTOMER_PK
                            ORDER BY target_records.LOAD_DATE DESC) AS rank_value
                FROM DBTVAULT.TEST.MULTI_ACTIVE_SATELLITE AS target_records
                INNER JOIN
                    (SELECT DISTINCT source_pks.CUSTOMER_PK
                    FROM source_data AS source_pks) AS source_records
                        ON target_records.CUSTOMER_PK = source_records.CUSTOMER_PK
                QUALIFY rank_value = 1
                ) AS latest_selection
        ),
        matching_records AS (
            SELECT stage.CUSTOMER_PK
                ,COUNT(DISTINCT stage.HASHDIFF, stage.CUSTOMER_PHONE) AS match_count
            FROM source_data AS stage
            INNER JOIN latest_records
                ON stage.CUSTOMER_PK = latest_records.CUSTOMER_PK
                AND stage.HASHDIFF = latest_records.HASHDIFF
                AND stage.CUSTOMER_PHONE = latest_records.CUSTOMER_PHONE
            GROUP BY stage.CUSTOMER_PK
        ),
        satellite_update AS (
            SELECT DISTINCT stage.CUSTOMER_PK
            FROM source_data AS stage
            INNER JOIN latest_records
                ON latest_records.CUSTOMER_PK = stage.CUSTOMER_PK
            LEFT OUTER JOIN matching_records
                ON matching_records.CUSTOMER_PK = latest_records.CUSTOMER_PK
            WHERE (stage.source_count != latest_records.target_count
                OR COALESCE(matching_records.match_count, 0) != latest_records.target_count)
        ),
        satellite_insert AS (
            SELECT DISTINCT stage.CUSTOMER_PK
            FROM source_data AS stage
            LEFT OUTER JOIN latest_records
                ON stage.CUSTOMER_PK = latest_records.CUSTOMER_PK
            WHERE latest_records.CUSTOMER_PK IS NULL
        ),
        records_to_insert AS (
            SELECT  stage.CUSTOMER_PK, stage.HASHDIFF, stage.CUSTOMER_PHONE, stage.CUSTOMER_NAME, stage.EFFECTIVE_FROM, stage.LOAD_DATE, stage.SOURCE
            FROM source_data AS stage
            INNER JOIN satellite_update
                ON satellite_update.CUSTOMER_PK = stage.CUSTOMER_PK
        
            UNION
        
            SELECT stage.CUSTOMER_PK, stage.HASHDIFF, stage.CUSTOMER_PHONE, stage.CUSTOMER_NAME, stage.EFFECTIVE_FROM, stage.LOAD_DATE, stage.SOURCE
            FROM source_data AS stage
            INNER JOIN satellite_insert
                ON satellite_insert.CUSTOMER_PK = stage.CUSTOMER_PK
        )
        
        SELECT * FROM records_to_insert
        ```

___

## Staging Macros

###### (macros/staging)

These macros are intended for use in the staging layer.
___

### stage

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/staging/stage.sql))

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
            CUSTOMER_PK,
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
            CUSTOMER_PK,
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
        
            CAST((MD5_BINARY(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''))) AS BINARY(16)) AS CUSTOMER_PK,
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
            CUSTOMER_PK,
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
            CUSTOMER_PK,
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
            CUSTOMER_PK,
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
            CUSTOMER_PK,
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
            CUSTOMER_PK,
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
        
            CAST((MD5_BINARY(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''))) AS BINARY(16)) AS CUSTOMER_PK,
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
        
            CUSTOMER_PK,
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
            CUSTOMER_PK,
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

| Parameter              | Description                                                                 | Type           | Default    | Required?                                        |
| ---------------------- | --------------------------------------------------------------------------- | -------------- | ---------- | ------------------------------------------------ |
| include_source_columns | If true, select all columns in the `source_model`                           | Boolean        | true       | <i class="fas fa-minus-circle not-required"></i> |
| source_model           | Staging model name                                                          | Mapping        | N/A        | <i class="fas fa-check-circle required"></i>     |
| derived_columns        | Mappings of constants to their source columns                               | Mapping        | none       | <i class="fas fa-minus-circle not-required"></i> |
| hashed_columns         | Mappings of hashes to their component columns                               | Mapping        | none       | <i class="fas fa-minus-circle not-required"></i> |
| ranked_columns         | Mappings of ranked columns names to their order by and partition by columns | Mapping        | none       | <i class="fas fa-minus-circle not-required"></i> |

#### Example Metadata

[See examples](metadata.md#staging)

### stage macro configurations

The stage macro supports some helper syntax and functionality to make your life easier when staging. These are
documented in this section.

#### Column scoping

The hashed column configuration in the stage macro may refer to columns which have been newly created in the derived
column configuration. This allows hashes to be created using values generated by the user via the derived column
configuration.

For example:

=== "Snowflake"

```yaml hl_lines="3 12"
source_model: "MY_STAGE"
derived_columns:
  CUSTOMER_DOB_UK: "TO_VARCHAR(CUSTOMER_DOB::date, 'DD-MM-YYYY')"
  SOURCE: "!RAW_CUSTOMER"
  EFFECTIVE_FROM: "BOOKING_DATE"
hashed_columns:
  CUSTOMER_PK: "CUSTOMER_ID"
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

The snippets below demonstrate the use of an `exclude_columns` flag. This will inform dbtvault to exclude the columns
listed under the `columns` key, instead of using them to create the hashdiff. You may also omit the `columns` key to
hash every column.

##### Examples:

=== "Columns provided"

    === "Columns in source model"
    
        ```text
        TRANSACTION_NUMBER
        CUSTOMER_DOB
        PHONE_NUMBER
        BOOKING_FK
        ORDER_FK
        CUSTOMER_PK
        LOAD_DATE
        RECORD_SOURCE
        ```
    
    === "hashed_columns configuration"
        
        ```yaml hl_lines="5"
        hashed_columns:
          CUSTOMER_PK: CUSTOMER_ID
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            exclude_columns: true
            columns:
              - BOOKING_FK
              - ORDER_FK
              - CUSTOMER_PK
              - LOAD_DATE
              - RECORD_SOURCE
        ```

    === "Equivalent hashed_columns configuration"
    
        ```yaml
        hashed_columns:
          CUSTOMER_PK: CUSTOMER_ID
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            columns:
              - TRANSACTION_NUMBER
              - CUSTOMER_DOB
              - PHONE_NUMBER
        ```

=== "Columns not provided"

    === "Columns in source model"
    
        ```text
        TRANSACTION_NUMBER
        CUSTOMER_DOB
        PHONE_NUMBER
        BOOKING_FK
        ORDER_FK
        CUSTOMER_PK
        LOAD_DATE
        RECORD_SOURCE
        ```

    === "hashed_columns configuration"
        
        ```yaml hl_lines="5"
        hashed_columns:
          CUSTOMER_PK: CUSTOMER_ID
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            exclude_columns: true
        ```
    
    === "Equivalent hashed_columns configuration"
    
        ```yaml
        hashed_columns:
          CUSTOMER_PK: CUSTOMER_ID
          CUSTOMER_HASHDIFF:
            is_hashdiff: true
            columns:
              - TRANSACTION_NUMBER
              - CUSTOMER_DOB
              - PHONE_NUMBER
              - BOOKING_FK
              - ORDER_FK
              - CUSTOMER_PK
              - LOAD_DATE
              - RECORD_SOURCE
        ```

This is extremely useful when a hashdiff composed of many columns needs to be generated, and you do not wish to
individually provide all the columns.

!!! warning

    Care should be taken if using this feature on dynamic data sources. If you expect columns in the data source to 
    change for any reason, it will become hard to predict what columns are used to generate the hashdiff. If your 
    component columns change, then your hashdiff output will also change and it will cause unpredictable results.

#### Functions (Derived Columns)

=== "Snowflake"

```yaml hl_lines="5"
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

Please ensure that your function has valid SQL syntax on your platform, for use in this context.

#### Constants (Derived Columns)

```yaml hl_lines="6"
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

```yaml hl_lines="6 7"
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

Given the following values in the above example:

- `CUSTOMER_ID` = 0011
- `CUSTOMER_NAME` = Alex

Then a new column, `CUSTOMER_NK`, would contain `0011||Alex||DEV`. The values are joined in the order provided, using a
double pipe `||`. Currently, this `||` join string is hard-coded, but in future it will be user-configurable.

The values provided in the list can use any of the previously described syntax (including functions and constants) to
generate new values, as the concatenation is made in pure SQL as follows:

```sql
SELECT CONCAT_WS('||', CUSTOMER_ID, CUSTOMER_NAME, 'DEV')
FROM MY_DB.MY_SCHEMA.MY_TABLE
```

#### Ranked columns

To make it easier to use the [vault_insert_by_rank](#vault_insert_by_rank) materialisation, the `ranked_columns`
configuration allows you to define ranked columns to generate, as follows:

```yaml
source_model: "MY_STAGE"
ranked_columns:
  DBTVAULT_RANK:
    partition_by: "CUSTOMER_PK"
    order_by: "LOAD_DATETIME"
  SAT_BOOKING_RANK:
    partition_by: "BOOKING_PK"
    order_by: "LOAD_DATETIME"
```

This will create columns like so:

```
RANK() OVER(PARTITION BY CUSTOMER_PK ORDER BY LOAD_DATETIME) AS DBTVAULT_RANK,
RANK() OVER(PARTITION BY BOOKING_PK ORDER BY LOAD_DATETIME) AS SAT_BOOKING_RANK
```

You may also provide multiple columns to the `partition_by` and `order_by` parameters, as follows:

```yaml
source_model: "MY_STAGE"
ranked_columns:
  DBTVAULT_RANK:
    partition_by: "CUSTOMER_PK"
    order_by: "LOAD_DATETIME"
  SAT_BOOKING_RANK:
    partition_by: 
      - "BOOKING_PK"
      - "BOOKING_DATE"
    order_by: 
      - "LOAD_DATETIME"
      - "BOOKING_DATE"
```


___

### hash_columns

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/staging/hash_columns.sql))

!!! note 
    This is a helper macro used within the stage macro, but can be used independently.

Generates SQL to create hash keys for a provided mapping of columns names to the list of columns to hash.

### derive_columns

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/staging/derive_columns.sql))

!!! note 
    This is a helper macro used within the stage macro, but can be used independently.

Generates SQL to create columns based off of the values of other columns, provided as a mapping from column name to
column value.

### ranked_columns

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/staging/rank_columns.sql))

!!! note 
    This is a helper macro used within the stage macro, but can be used independently.

Generates SQL to create columns using the `RANK()` window function.

___

## Supporting Macros

###### (macros/supporting)

Supporting macros are helper functions for use in models. It should not be necessary to call these macros directly,
however they are used extensively in the [table templates](#table-templates) and may be used for your own purposes if
you wish.

___

### hash

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/supporting/hash.sql))

!!! warning 
    
    This macro ***should not be*** used for cryptographic purposes.

    The intended use is for creating checksum-like values only, so that we may compare records accurately.
    
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
    {{ dbtvault.hash('CUSTOMERKEY', 'CUSTOMER_PK') }},
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
    The [hash_columns](#hash_columns) macro can be used to simplify the hashing process and generate multiple hashes with one macro.

#### Parameters

| Parameter        |  Description                                     | Type                | Required?                                        |
| ---------------- | -----------------------------------------------  | ------------------- | ------------------------------------------------ |
| columns          |  Columns to hash on                              | List[String]/String | <i class="fas fa-check-circle required"></i>     |
| alias            |  The name to give the hashed column              | String              | <i class="fas fa-check-circle required"></i>     |
| is_hashdiff      |  Will alpha sort columns if true, default false. | Boolean             | <i class="fas fa-minus-circle not-required"></i> |      

___

### prefix

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/supporting/prefix.sql))

A macro for quickly prefixing a list of columns with a string.

#### Parameters

| Parameter        |  Description                  | Type         | Required?                                    |
| ---------------- | ----------------------------- | ------------ | -------------------------------------------- |
| columns          |  A list of column names       | List[String] | <i class="fas fa-check-circle required"></i> |
| prefix_str       |  The prefix for the columns   | String       | <i class="fas fa-check-circle required"></i> |

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
    Single columns must be provided as a 1-item list, as in the second example above.

___

## Internal

###### (macros/internal)

Internal macros are used by other macros provided in this package. They process provided metadata and should not need to
be called directly.

___

## Materialisations

###### (macros/materialisations)

Materialisations dictate how a model is created in the database.

dbt comes with 4 standard materialisations:

- Table
- View
- Incremental
- Ephemeral

[Read more about materialisations here](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/materializations/)

For dbtvault, we have created some custom materialisations which will provide assistance Data Vault 2.0 specific use
cases

### vault_insert_by_period

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/materialisations/vault_insert_by_period_materialization.sql))

This materialisation is based on
the [insert_by_period](https://github.com/fishtown-analytics/dbt-utils/blob/master/macros/materializations/insert_by_period_materialization.sql)
materialisation developed by Fishtown Analytics for the [dbt-utils](https://github.com/fishtown-analytics/dbt-utils)
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

| Configuration      |  Description                                         | Type                 | Default | Required?                                        |
| ------------------ | ---------------------------------------------------- | -------------------- | ------- | ------------------------------------------------ |
| timestamp_field    |  A list of column names                              | List[String]         | None    | <i class="fas fa-check-circle required"></i>     |
| period             |  Time period to load over                            | String               | day     | <i class="fas fa-minus-circle not-required"></i> |
| start_date         |  The date to start the load from                     | String (YYYY-MM-DD)  | None    | See: Configuring the load date range             |
| stop_date          |  The date to stop the load on                        | String (YYYY-MM-DD)  | None    | See: Configuring the load date range             |
| date_source_models |  A list of models containing the timestamp_field     | List[String]/String  | None    | See: Configuring the load date range             |

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

However, If you are writing your own models and wish to use the this materialisation, then you must include
a `WHERE __PERIOD_FILTER__`
somewhere appropriate in your model. A CTE which selects from your source model and then includes the placeholder,
should provide best results.

See the [hub](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/tables/hub.sql) source code for further
understanding.

#### Idempotent loads

This materialisation supports idempotent loads when used with dbtvault macros. When calculating the `start` and `stop`
dates of the load, a `COALESCE` function is applied. This `COALESCE` call compares the maximum timestamp contained in
the `timestamp_field`, and the provided or inferred `start_date` and sets the `start_date`
to whatever is larger (more recent). This means that any aborted loads will continue where they left off, and any
duplicate loads will not have any effect (if using dbtvault macros).

If you wish support idempotent loads in your own models using this materialisation, the best approach is to
use `LEFT OUTER JOINS` to ensure duplicate records are not loaded.

### vault_insert_by_rank

([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.4/macros/materialisations/vault_insert_by_rank_materialization.sql))

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
| rank_column        |  The column name containing the rank values          | String               | None    | <i class="fas fa-check-circle required"></i>     |
| rank_source_models |  A list of model names containing the `rank_column`  | List[String]         | None    | <i class="fas fa-check-circle required"></i>     |

#### Creating a rank column

A rank column can be created one of three ways:

1. Manually creating it in a model prior to the staging layer, and using this model as the stage `source_model`.

2. Using the `ranked_columns` configuration of the [stage](#stage) macro

    ```yaml
    source_model: "MY_STAGE"
    ranked_columns:
      DBTVAULT_RANK:
        partition_by: "CUSTOMER_PK"
        order_by: "LOAD_DATETIME"
    ```

3. Using the `derived_columns` configuration of the [stage](#stage) macro

    ```yaml
    source_model: "MY_STAGE"
    derived_columns:
      DBTVAULT_RANK: "RANK() OVER(PARTITION BY CUSTOMER_PK ORDER BY LOAD_DATETIME)"
    ```

#### Which option?

- Method #2 is recommended, as it allows ranked columns to use user-defined derived or hashed columns created in the
  same staging layer.
- Method #3 is similar, except it will not have hashed or derived column definitions available to it.

!!! warning "Check your rank"

    It is important that once a rank column is created, it should be sense checked for correct and expected ordering. If your ranking is incorrect according to
    the business, then loading will not be executed correctly.