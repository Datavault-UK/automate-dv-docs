## Table templates
######(macros/tables)

These macros are the core of the package and can be called in your models to build the different types of tables needed
for your Data Vault.

### hub
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/tables/hub.sql))

Generates SQL to build a hub table using the provided parameters.

#### Usage

``` jinja

{{ dbtvault.hub(var('src_pk'), var('src_nk'), var('src_ldts'),
                var('src_source'), var('source_model'))        }}
```

#### Parameters

| Parameter     | Description                                         | Type (Single-Source) | Type (Multi-Source) | Required?                                    |
| ------------- | --------------------------------------------------- | -------------------- | ------------------- | -------------------------------------------- |
| src_pk        | Source primary key column                           | String               | String              | <i class="fas fa-check-circle required"></i> |
| src_nk        | Source natural key column                           | String               | String              | <i class="fas fa-check-circle required"></i> |
| src_ldts      | Source load date timestamp column                   | String               | String              | <i class="fas fa-check-circle required"></i> |
| src_source    | Name of the column containing the source ID         | String               | String              | <i class="fas fa-check-circle required"></i> |
| source_model  | Staging model name                                  | String               | List (YAML)         | <i class="fas fa-check-circle required"></i> |

#### Example Metadata

[See examples](metadata.md#hubs)

#### Example Output

=== "Snowflake"

    === "Single-Source (Base Load)"
    
        ```sql
        WITH rank_1 AS (
            SELECT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT_DEV.TEST.raw_stage_hashed
        ),
        stage_1 AS (
            SELECT DISTINCT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, SOURCE
            FROM rank_1
            WHERE row_number = 1
        ),
        stage_union AS (
            SELECT * FROM stage_1
        ),
        rank_union AS (
            SELECT *,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE, SOURCE ASC
                   ) AS row_number
            FROM stage_union
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        stage AS (
            SELECT DISTINCT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, SOURCE
            FROM rank_union
            WHERE row_number = 1
        ),
        records_to_insert AS (
            SELECT stage.* FROM stage
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Single-Source (Subsequent Loads)"
    
        ```sql
        WITH rank_1 AS (
            SELECT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT_DEV.TEST.raw_stage_hashed
        ),
        stage_1 AS (
            SELECT DISTINCT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, SOURCE
            FROM rank_1
            WHERE row_number = 1
        ),
        stage_union AS (
            SELECT * FROM stage_1
        ),
        -- include this CTE if using vault_insert_by_period materialisation
        stage_period_filter AS (
            SELECT *
            FROM stage_union
            WHERE __PERIOD_FILTER__
        ),
        rank_union AS (
            SELECT *,
                   ROW_NUMBER() OVER(
                       PARTITION BY CUSTOMER_PK
                       ORDER BY LOAD_DATE, SOURCE ASC
                   ) AS row_number
            FROM stage_union -- or stage_period_filter
            WHERE CUSTOMER_PK IS NOT NULL
        ),
        stage AS (
            SELECT DISTINCT CUSTOMER_PK, CUSTOMER_ID, LOAD_DATE, SOURCE
            FROM rank_union
            WHERE row_number = 1
        ),
        records_to_insert AS (
            SELECT stage.* FROM stage
            LEFT JOIN DBTVAULT_DEV.TEST.HUB AS d
            ON stage.CUSTOMER_PK = d.CUSTOMER_PK
            WHERE d.CUSTOMER_PK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        WITH rank_1 AS (
            SELECT PART_PK, PART_ID, LOAD_DATE, SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY PART_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT_DEV.TEST.raw_stage_supplier_seed_hashed
        ),
        stage_1 AS (
            SELECT DISTINCT PART_PK, PART_ID, LOAD_DATE, SOURCE
            FROM rank_1
            WHERE row_number = 1
        ),
        rank_2 AS (
            SELECT PART_PK, PART_ID, LOAD_DATE, SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY PART_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT_DEV.TEST.raw_stage_parts_seed_hashed
        ),
        stage_2 AS (
            SELECT DISTINCT PART_PK, PART_ID, LOAD_DATE, SOURCE
            FROM rank_2
            WHERE row_number = 1
        ),
        rank_3 AS (
            SELECT PART_PK, PART_ID, LOAD_DATE, SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY PART_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT_DEV.TEST.raw_stage_lineitem_seed_hashed
        ),
        stage_3 AS (
            SELECT DISTINCT PART_PK, PART_ID, LOAD_DATE, SOURCE
            FROM rank_3
            WHERE row_number = 1
        ),
        stage_union AS (
            SELECT * FROM stage_1
            UNION ALL
            SELECT * FROM stage_2
            UNION ALL
            SELECT * FROM stage_3
        ),
        rank_union AS (
            SELECT *,
                   ROW_NUMBER() OVER(
                       PARTITION BY PART_PK
                       ORDER BY LOAD_DATE, SOURCE ASC
                   ) AS row_number
            FROM stage_union
            WHERE PART_PK IS NOT NULL
        ),
        stage AS (
            SELECT DISTINCT PART_PK, PART_ID, LOAD_DATE, SOURCE
            FROM rank_union
            WHERE row_number = 1
        ),
        records_to_insert AS (
            SELECT stage.* FROM stage
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Multi-Source (Subsequent Loads)"
 
        ```sql
        WITH rank_1 AS (
            SELECT PART_PK, PART_ID, LOAD_DATE, SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY PART_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT_DEV.TEST.raw_stage_parts_seed_hashed
        ),
        stage_1 AS (
            SELECT DISTINCT PART_PK, PART_ID, LOAD_DATE, SOURCE
            FROM rank_1
            WHERE row_number = 1
        ),
        rank_2 AS (
            SELECT PART_PK, PART_ID, LOAD_DATE, SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY PART_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT_DEV.TEST.raw_stage_lineitem_seed_hashed
        ),
        stage_2 AS (
            SELECT DISTINCT PART_PK, PART_ID, LOAD_DATE, SOURCE
            FROM rank_2
            WHERE row_number = 1
        ),
        rank_3 AS (
            SELECT PART_PK, PART_ID, LOAD_DATE, SOURCE,
                   ROW_NUMBER() OVER(
                       PARTITION BY PART_PK
                       ORDER BY LOAD_DATE ASC
                   ) AS row_number
            FROM DBTVAULT_DEV.TEST.raw_stage_supplier_seed_hashed
        ),
        stage_3 AS (
            SELECT DISTINCT PART_PK, PART_ID, LOAD_DATE, SOURCE
            FROM rank_3
            WHERE row_number = 1
        ),
        stage_union AS (
            SELECT * FROM stage_1
            UNION ALL
            SELECT * FROM stage_2
            UNION ALL
            SELECT * FROM stage_3
        ),
        -- include this CTE if using vault_insert_by_period materialisation
        stage_period_filter AS (
            SELECT *
            FROM stage_union
            WHERE __PERIOD_FILTER__
        ),
        rank_union AS (
            SELECT *,
                   ROW_NUMBER() OVER(
                       PARTITION BY PART_PK
                       ORDER BY LOAD_DATE, SOURCE ASC
                   ) AS row_number
            FROM stage_union  -- or stage_period_filter
            WHERE PART_PK IS NOT NULL
        ),
        stage AS (
            SELECT DISTINCT PART_PK, PART_ID, LOAD_DATE, SOURCE
            FROM rank_union
            WHERE row_number = 1
        ),
        records_to_insert AS (
            SELECT stage.* FROM stage
            LEFT JOIN DBTVAULT_DEV.TEST.HUB AS d
            ON stage.PART_PK = d.PART_PK
            WHERE d.PART_PK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```
___

### link
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/tables/link.sql))

Generates sql to build a link table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.link(var('src_pk'), var('src_fk'), var('src_ldts'),
                 var('src_source'), var('source_model'))        }}
```                                                  

#### Parameters

| Parameter     | Description                                         | Type (Single-Source) | Type (Union)         | Required?                                    |
| ------------- | --------------------------------------------------- | ---------------------| ---------------------| -------------------------------------------- |
| src_pk        | Source primary key column                           | String               | String               | <i class="fas fa-check-circle required"></i> |
| src_fk        | Source foreign key column(s)                        | List (YAML)          | List (YAML)          | <i class="fas fa-check-circle required"></i> |
| src_ldts      | Source load date timestamp column                   | String               | String               | <i class="fas fa-check-circle required"></i> |
| src_source    | Name of the column containing the source ID         | String               | String               | <i class="fas fa-check-circle required"></i> |
| source_model  | Staging model name                                  | String               | List (YAML)          | <i class="fas fa-check-circle required"></i> |

#### Example Metadata

[See examples](metadata.md#links)

#### Example Output

=== "Snowflake"

    === "Single-Source (Base Load)"
    
        ```sql
       
        ```
    
    === "Single-Source (Subsequent Loads)"
    
        ```sql
        
        ```
    
    === "Multi-Source (Base Load)"

        ```sql
        
        ```
    
    === "Multi-Source (Subsequent Loads)"
 
        ```sql
        
        ```

___

### t_link
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/tables/t_link.sql))

Generates sql to build a transactional link table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.t_link(var('src_pk'), var('src_fk'), var('src_payload'),
                   var('src_eff'), var('src_ldts'), var('src_source'),
                   var('source_model'))                                }}
```

#### Parameters

| Parameter     | Description                                         | Type           | Required?                                    |
| ------------- | --------------------------------------------------- | -------------- | -------------------------------------------- |
| src_pk        | Source primary key column                           | String         | <i class="fas fa-check-circle required"></i> |
| src_fk        | Source foreign key column(s)                        | List (YAML)    | <i class="fas fa-check-circle required"></i> |
| src_payload   | Source payload column(s)                            | List (YAML)    | <i class="fas fa-check-circle required"></i> |
| src_eff       | Source effective from column                        | String         | <i class="fas fa-check-circle required"></i> |
| src_ldts      | Source load date timestamp column                   | String         | <i class="fas fa-check-circle required"></i> |
| src_source    | Name of the column containing the source ID         | String         | <i class="fas fa-check-circle required"></i> |
| source_model  | Staging model name                                  | String         | <i class="fas fa-check-circle required"></i> |

#### Example Metadata

[See examples](metadata.md#transactional-links)

#### Example Output

=== "Snowflake"

    === "Base Load"
    
        ```sql
        WITH stage AS (
            SELECT TRANSACTION_PK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM DBTVAULT_DEV.TEST.raw_stage_hashed
        ),
        records_to_insert AS (
            SELECT DISTINCzT stg.TRANSACTION_PK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
        )
        
        SELECT * FROM records_to_insert
        ```
    
    === "Subsequent Loads"
        
        ```sql
        WITH stage AS (
            SELECT TRANSACTION_PK, CUSTOMER_FK, TRANSACTION_NUMBER, TRANSACTION_DATE, TYPE, AMOUNT, EFFECTIVE_FROM, LOAD_DATE, SOURCE
            FROM DBTVAULT_DEV.TEST.raw_stage_hashed
            WHERE __PERIOD_FILTER__
        ),
        records_to_insert AS (
            SELECT DISTINCT stg.TRANSACTION_PK, stg.CUSTOMER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOAD_DATE, stg.SOURCE
            FROM stage AS stg
            LEFT JOIN DBTVAULT_DEV.TEST.T_LINK AS tgt
            ON stg.TRANSACTION_PK = tgt.TRANSACTION_PK
            WHERE tgt.TRANSACTION_PK IS NULL
        )
        
        SELECT * FROM records_to_insert
        ```
___

### sat
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/tables/sat.sql))

Generates sql to build a satellite table using the provided parameters.


#### Usage

``` jinja
{{ dbtvault.sat(var('src_pk'), var('src_hashdiff'), var('src_payload'),
                var('src_eff'), var('src_ldts'), var('src_source'),
                var('source_model'))                                   }}
```

#### Parameters

| Parameter     | Description                                         | Type             | Required?                                    |
| ------------- | --------------------------------------------------- | ---------------- | -------------------------------------------- |
| src_pk        | Source primary key column                           | String           | <i class="fas fa-check-circle required"></i> |
| src_hashdiff  | Source hashdiff column                              | String           | <i class="fas fa-check-circle required"></i> |
| src_payload   | Source payload column(s)                            | List/Dict (YAML) | <i class="fas fa-check-circle required"></i> |
| src_eff       | Source effective from column                        | String           | <i class="fas fa-check-circle required"></i> |
| src_ldts      | Source load date timestamp column                   | String           | <i class="fas fa-check-circle required"></i> |
| src_source    | Name of the column containing the source ID         | String           | <i class="fas fa-check-circle required"></i> |
| source_model  | Staging model name                                  | String           | <i class="fas fa-check-circle required"></i> |

#### Example Metadata

[See examples](metadata.md#satellites)

#### Example Output

=== "Snowflake"

    === "Base Load"
    
        ```sql
        WITH source_data AS (
            SELECT *
            FROM DBTVAULT_DEV.TEST.raw_stage_hashed
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
            SELECT *
            FROM DBTVAULT_DEV.TEST.raw_stage_hashed
            -- if using vault_insert_by_period
            WHERE __PERIOD_FILTER__ 
        ),
        update_records AS (
            SELECT a.CUSTOMER_PK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_PHONE, a.CUSTOMER_DOB, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM DBTVAULT_DEV.TEST.SATELLITE as a
            JOIN source_data as b
            ON a.CUSTOMER_PK = b.CUSTOMER_PK
        ),
        rank AS (
            SELECT c.CUSTOMER_PK, c.HASHDIFF, c.CUSTOMER_NAME, c.CUSTOMER_PHONE, c.CUSTOMER_DOB, c.EFFECTIVE_FROM, c.LOAD_DATE, c.SOURCE,
                   CASE WHEN RANK()
                   OVER (PARTITION BY c.CUSTOMER_PK
                   ORDER BY c.LOAD_DATE DESC) = 1
            THEN 'Y' ELSE 'N' END AS latest
            FROM update_records as c
        ),
        stage AS (
            SELECT d.CUSTOMER_PK, d.HASHDIFF, d.CUSTOMER_NAME, d.CUSTOMER_PHONE, d.CUSTOMER_DOB, d.EFFECTIVE_FROM, d.LOAD_DATE, d.SOURCE
            FROM rank AS d
            WHERE d.latest = 'Y'
        ),
        records_to_insert AS (
            SELECT DISTINCT e.CUSTOMER_PK, e.HASHDIFF, e.CUSTOMER_NAME, e.CUSTOMER_PHONE, e.CUSTOMER_DOB, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
            LEFT JOIN stage
            ON stage.HASHDIFF = e.HASHDIFF
            WHERE stage.HASHDIFF IS NULL

        )
        
        SELECT * FROM records_to_insert
        ```

___

### eff_sat
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/tables/eff_sat.sql))

Generates sql to build an effectivity satellite table using the provided parameters.

#### Usage

``` jinja
{{ dbtvault.eff_sat(var('src_pk'), var('src_dfk'), var('src_sfk'),
                    var('src_start_date'), var('src_end_date'),
                    var('src_eff'), var('src_ldts'), var('src_source'),
                    var('source_model')) }}
```

#### Parameters

| Parameter      | Description                                         | Type             | Required?                                    |
| -------------- | --------------------------------------------------- | ---------------- | -------------------------------------------- |
| src_pk         | Source primary key column                           | String           | <i class="fas fa-check-circle required"></i> |
| src_dfk        | Source driving foreign key column                   | String/List      | <i class="fas fa-check-circle required"></i> |
| src_sfk        | Source secondary foreign key column                 | String/List      | <i class="fas fa-check-circle required"></i> |
| src_start_date | Source start date column                            | String           | <i class="fas fa-check-circle required"></i> |
| src_end_date   | Source end date column                              | String           | <i class="fas fa-check-circle required"></i> |
| src_eff        | Source effective from column                        | String           | <i class="fas fa-check-circle required"></i> |
| src_ldts       | Source load date timestamp column                   | String           | <i class="fas fa-check-circle required"></i> |
| src_source     | Name of the column containing the source ID         | String           | <i class="fas fa-check-circle required"></i> |
| source_model   | Staging model name                                  | String           | <i class="fas fa-check-circle required"></i> |


#### Example Metadata

[See examples](metadata.md#effectivity-satellites)

#### Example Output

=== "Snowflake"
    === "Base Load"
        
        ```sql
        WITH source_data AS (
            SELECT *
            FROM DBTVAULT_DEV.TEST.raw_stage_hashed
        ),
        records_to_insert AS (
            SELECT e.CUSTOMER_ORDER_PK, e.ORDER_PK, e.CUSTOMER_PK, e.START_DATE, e.END_DATE, e.EFFECTIVE_FROM, e.LOAD_DATE, e.SOURCE
            FROM source_data AS e
        )
        
        SELECT * FROM records_to_insert
        ```

    === "With auto end-dating (existing)"
    
        ```sql
        WITH source_data AS (
            SELECT *
            FROM DBTVAULT_DEV.TEST.raw_stage_hashed
            -- if using vault_insert_by_period
            WHERE __PERIOD_FILTER__  
        ),
        latest_eff AS
        (
            SELECT b.CUSTOMER_ORDER_PK, b.ORDER_PK, b.CUSTOMER_PK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATE, b.SOURCE,
                   ROW_NUMBER() OVER (
                        PARTITION BY b.CUSTOMER_ORDER_PK
                        ORDER BY b.LOAD_DATE DESC
                   ) AS row_number
            FROM DBTVAULT_DEV.TEST.EFF_SAT AS b
        ),
        latest_open_eff AS
        (
            SELECT a.CUSTOMER_ORDER_PK, a.ORDER_PK, a.CUSTOMER_PK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM latest_eff AS a 
            WHERE TO_DATE(a.END_DATE) = TO_DATE('9999-12-31')
            AND a.row_number = 1
        ),
        stage_slice AS
        (
            SELECT stage.CUSTOMER_ORDER_PK, stage.ORDER_PK, stage.CUSTOMER_PK, stage.START_DATE, stage.END_DATE, stage.EFFECTIVE_FROM, stage.LOAD_DATE, stage.SOURCE
            FROM source_data AS stage
        ),
        links_to_end_date AS (
            SELECT a.*
            FROM latest_open_eff AS a
            LEFT JOIN stage_slice AS b
            ON a.ORDER_PK = b.ORDER_PK
                
            WHERE b.CUSTOMER_PK IS NULL
            OR a.CUSTOMER_PK <> b.CUSTOMER_PK
                
        ),
        new_open_records AS (
            SELECT DISTINCT
                stage.CUSTOMER_ORDER_PK, stage.ORDER_PK, stage.CUSTOMER_PK, stage.START_DATE, stage.END_DATE, stage.EFFECTIVE_FROM, stage.LOAD_DATE, stage.SOURCE
            FROM stage_slice AS stage
            LEFT JOIN latest_open_eff AS e
            ON stage.CUSTOMER_ORDER_PK = e.CUSTOMER_ORDER_PK
            WHERE e.CUSTOMER_ORDER_PK IS NULL
            AND stage.ORDER_PK IS NOT NULL
            AND stage.CUSTOMER_PK IS NOT NULL
        ),
        new_end_dated_records AS (
            SELECT DISTINCT
                h.CUSTOMER_ORDER_PK,
                g.ORDER_PK, g.CUSTOMER_PK,
                h.EFFECTIVE_FROM AS START_DATE, h.SOURCE
            FROM latest_open_eff AS h
            INNER JOIN links_to_end_date AS g
            ON g.CUSTOMER_ORDER_PK = h.CUSTOMER_ORDER_PK
        ),
        amended_end_dated_records AS (
            SELECT DISTINCT
                a.CUSTOMER_ORDER_PK,
                a.ORDER_PK, a.CUSTOMER_PK,
                a.START_DATE,
                stage.EFFECTIVE_FROM AS END_DATE, stage.EFFECTIVE_FROM, stage.LOAD_DATE,
                a.SOURCE
            FROM new_end_dated_records AS a
            INNER JOIN stage_slice AS stage
            ON stage.ORDER_PK = a.ORDER_PK
                
            WHERE stage.CUSTOMER_PK IS NOT NULL
            AND stage.ORDER_PK IS NOT NULL
        ),
        records_to_insert AS (
            SELECT * FROM new_open_records
            UNION
            SELECT * FROM amended_end_dated_records
        )
        
        SELECT * FROM records_to_insert
        ```
        
    === "Without auto end-dating (existing)"   
        
        ```sql
        WITH source_data AS (
            SELECT *
            FROM DBTVAULT_DEV.TEST.raw_stage_hashed
            -- if using vault_insert_by_period
            WHERE __PERIOD_FILTER__ 
        ),
        latest_eff AS
        (
            SELECT b.CUSTOMER_ORDER_PK, b.ORDER_PK, b.CUSTOMER_PK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATE, b.SOURCE,
                   ROW_NUMBER() OVER (
                        PARTITION BY b.CUSTOMER_ORDER_PK
                        ORDER BY b.LOAD_DATE DESC
                   ) AS row_number
            FROM DBTVAULT_DEV.TEST.EFF_SAT AS b
        ),
        latest_open_eff AS
        (
            SELECT a.CUSTOMER_ORDER_PK, a.ORDER_PK, a.CUSTOMER_PK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATE, a.SOURCE
            FROM latest_eff AS a
            WHERE TO_DATE(a.END_DATE) = TO_DATE('9999-12-31')
            AND a.row_number = 1
        ),
        stage_slice AS
        (
            SELECT stage.CUSTOMER_ORDER_PK, stage.ORDER_PK, stage.CUSTOMER_PK, stage.START_DATE, stage.END_DATE, stage.EFFECTIVE_FROM, stage.LOAD_DATE, stage.SOURCE
            FROM source_data AS stage
        ),
        new_open_records AS (
            SELECT DISTINCT
                stage.CUSTOMER_ORDER_PK, stage.ORDER_PK, stage.CUSTOMER_PK, stage.START_DATE, stage.END_DATE, stage.EFFECTIVE_FROM, stage.LOAD_DATE, stage.SOURCE
            FROM stage_slice AS stage
            LEFT JOIN latest_open_eff AS e
            ON stage.CUSTOMER_ORDER_PK = e.CUSTOMER_ORDER_PK
            WHERE e.CUSTOMER_ORDER_PK IS NULL
            AND stage.ORDER_PK IS NOT NULL
            AND stage.CUSTOMER_PK IS NOT NULL
        ),
        records_to_insert AS (
            SELECT * FROM new_open_records
        )
        
        SELECT * FROM records_to_insert
        
        ```
    
___

## Staging Macros
######(macros/staging)

These macros are intended for use in the staging layer.
___

### stage
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/staging/stage.sql))

Generates sql to build a staging area using the provided parameters.

#### Usage

=== "Input"
    ``` jinja
    {{ dbtvault.stage(include_source_columns=var('include_source_columns', none), 
                      source_model=var('source_model', none), 
                      hashed_columns=var('hashed_columns', none), 
                      derived_columns=var('derived_columns', none)) }}
    ```
=== "Example Output (Snowflake)"
    === "All variables"
        ```sql
        
        SELECT
        
        CAST((MD5_BINARY(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''))) AS BINARY(16)) AS CUSTOMER_PK,
        CAST(MD5_BINARY(CONCAT(
            IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_DOB AS VARCHAR))), ''), '^^'), '||',
            IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'), '||',
            IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_NAME AS VARCHAR))), ''), '^^') ))
        AS BINARY(16)) AS CUST_CUSTOMER_HASHDIFF,
        CAST(MD5_BINARY(CONCAT(
            IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'), '||',
            IFNULL(NULLIF(UPPER(TRIM(CAST(NATIONALITY AS VARCHAR))), ''), '^^'), '||',
            IFNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR))), ''), '^^') ))
        AS BINARY(16)) AS CUSTOMER_HASHDIFF,
        
        'STG_BOOKING' AS SOURCE,
        BOOKING_DATE AS EFFECTIVE_FROM,
        BOOKING_FK,
        ORDER_FK,
        CUSTOMER_PK,
        CUSTOMER_ID,   
        BOOKING_DATE,
        LOAD_DATETIME,
        RECORD_SOURCE,
        CUSTOMER_DOB,
        CUSTOMER_NAME,
        NATIONALITY,
        PHONE
        
        FROM MY_DATABASE.MY_SCHEMA.raw_source
        ```
    === "Only source"
        ```sql
        
        SELECT
        
        BOOKING_FK,
        ORDER_FK,
        CUSTOMER_PK,
        CUSTOMER_ID,
        BOOKING_DATE,
        LOAD_DATETIME,
        RECORD_SOURCE,
        CUSTOMER_DOB,
        CUSTOMER_NAME,
        NATIONALITY,
        PHONE
        
        FROM MY_DATABASE.MY_SCHEMA.raw_source
        ```
    === "Only hashing"
        ```sql
        
        SELECT
        
        CAST((MD5_BINARY(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''))) AS BINARY(16)) AS CUSTOMER_PK,
        CAST(MD5_BINARY(CONCAT(
            IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_DOB AS VARCHAR))), ''), '^^'), '||',
            IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'), '||',
            IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_NAME AS VARCHAR))), ''), '^^') ))
        AS BINARY(16)) AS CUST_CUSTOMER_HASHDIFF,
        CAST(MD5_BINARY(CONCAT(
            IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'), '||',
            IFNULL(NULLIF(UPPER(TRIM(CAST(NATIONALITY AS VARCHAR))), ''), '^^'), '||',
            IFNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR))), ''), '^^') ))
        AS BINARY(16)) AS CUSTOMER_HASHDIFF
        
        FROM MY_DATABASE.MY_SCHEMA.raw_source
        ```
    === "Only derived"
        ```sql
        
        SELECT
        
        'STG_BOOKING' AS SOURCE,
        BOOKING_DATE AS EFFECTIVE_FROM
        
        FROM MY_DATABASE.MY_SCHEMA.raw_source
        ```
#### Parameters

| Parameter              | Description                                       | Type           | Default    | Required?                                        |
| ---------------------- | ------------------------------------------------- | -------------- | ---------- | ------------------------------------------------ |
| include_source_columns | If true, select all columns in the `source_model` | Boolean        | true       | <i class="fas fa-minus-circle not-required"></i> |
| source_model           | Staging model name                                | String/Mapping | N/A        | <i class="fas fa-check-circle required"></i>     |
| hashed_columns         | Mappings of hashes to their component columns     | String/Mapping | none       | <i class="fas fa-minus-circle not-required"></i> |
| derived_columns        | Mappings of constants to their source columns     | String/Mapping | none       | <i class="fas fa-minus-circle not-required"></i> |

#### Example Metadata

[See examples](metadata.md#staging)

___

### hash_columns
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/staging/hash_columns.sql))

Generates SQL to create hashes from provided columns.

### derive_columns
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/staging/derive_columns.sql))

Generates SQL to generate columns based off of the values of other columns.

___

## Supporting Macros
######(macros/supporting)

Supporting macros are helper functions for use in models. It should not be necessary to call these macros directly, however they 
are used extensively in the [table templates](#table-templates) and may be used for your own purposes if you wish. 

___

### hash
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/supporting/hash.sql))

!!! warning
    This macro ***should not be*** used for cryptographic purposes.
    
    The intended use is for creating checksum-like values only, so that we may compare records accurately.
    
    [Read More](https://www.md5online.org/blog/why-md5-is-not-safe/)

!!! seealso "See Also"
    - [hash_columns](#hash_columns)
    - Read [Hashing best practises and why we hash](best_practices.md#hashing)
      for more detailed information on the purposes of this macro and what it does.

    - You may choose between ```MD5``` and ```SHA-256``` hashing. 
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
        CAST(MD5_BINARY(UPPER(TRIM(CAST(CUSTOMERKEY AS VARCHAR)))) AS BINARY(16)) AS CUSTOMER_PK,
        CAST(MD5_BINARY(CONCAT(IFNULL(UPPER(TRIM(CAST(CUSTOMERKEY AS VARCHAR))), '^^'), '||',
                               IFNULL(UPPER(TRIM(CAST(DOB AS VARCHAR))), '^^'), '||',
                               IFNULL(UPPER(TRIM(CAST(NAME AS VARCHAR))), '^^'), '||',
                               IFNULL(UPPER(TRIM(CAST(PHONE AS VARCHAR))), '^^') )) 
                               AS BINARY(16)) AS HASHDIFF
        ```
    === "SHA"
        ```sql
        CAST(SHA2_BINARY(UPPER(TRIM(CAST(CUSTOMERKEY AS VARCHAR)))) AS BINARY(32)) AS CUSTOMER_PK,
        CAST(SHA2_BINARY(CONCAT(IFNULL(UPPER(TRIM(CAST(CUSTOMERKEY AS VARCHAR))), '^^'), '||',
                                IFNULL(UPPER(TRIM(CAST(DOB AS VARCHAR))), '^^'), '||',
                                IFNULL(UPPER(TRIM(CAST(NAME AS VARCHAR))), '^^'), '||',
                                IFNULL(UPPER(TRIM(CAST(PHONE AS VARCHAR))), '^^') )) 
                                AS BINARY(32)) AS HASHDIFF
        ```


!!! tip
    [hash_columns](#hash_columns) may be used to simplify the hashing process and generate multiple hashes with one macro.

#### Parameters

| Parameter        |  Description                                     | Type        | Required?                                        |
| ---------------- | -----------------------------------------------  | ----------- | ------------------------------------------------ |
| columns          |  Columns to hash on                              | String/List | <i class="fas fa-check-circle required"></i>     |
| alias            |  The name to give the hashed column              | String      | <i class="fas fa-check-circle required"></i>     |
| is_hashdiff      |  Will alpha sort columns if true, default false. | Boolean     | <i class="fas fa-minus-circle not-required"></i> |      

___

### prefix
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/supporting/prefix.sql))

A macro for quickly prefixing a list of columns with a string.

#### Parameters

| Parameter        |  Description                  | Type   | Required?                                    |
| ---------------- | ----------------------------- | ------ | -------------------------------------------- |
| columns          |  A list of column names       | List   | <i class="fas fa-check-circle required"></i> |
| prefix_str       |  The prefix for the columns   | String | <i class="fas fa-check-circle required"></i> |

#### Usage

=== "Input"
    ```sql
    {{ dbtvault.prefix(['CUSTOMERKEY', 'DOB', 'NAME', 'PHONE'], 'a') }}
    {{ dbtvault.prefix(['CUSTOMERKEY'], 'a') }}
    ```
=== "Output"
    ```sql
    a.CUSTOMERKEY, a.DOB, a.NAME, a.PHONE
    a.CUSTOMERKEY
    ```

!!! Note
    Single columns must be provided as a 1-item list, as in the second example above.

___

## Internal
######(macros/internal)

Internal macros are used by other macros provided in this package. 
They are used to process provided metadata and should not need to be called directly. 

___

## Materialisations
######(macros/materialisations)

Materialisations dictate how a model is created in the database. 

dbt comes with 4 standard materialisations:

- Table
- View
- Incremental
- Ephemeral

[Read more about materialisations here](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/materializations/)

For dbtvault, we have created some custom materialisations which will provide assistance Data Vault 2.0 specific use cases

### vault_insert_by_period
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/materialisations/vault_insert_by_period_materialization.sql))

This materialisation is based on the [insert_by_period](https://github.com/fishtown-analytics/dbt-utils/blob/master/macros/materializations/insert_by_period_materialization.sql) 
materialisation developed by Fishtown Analytics for the [dbt-utils](https://github.com/fishtown-analytics/dbt-utils) package.

We have re-purposed it provided support for Snowflake, as well as added a number of convenience features. 

Features include:

- Idempotent loading
- Inference of date range to load with
- Manually configurable date range to load with
- Configurable granularity (day, month, year etc.)

The purpose of the materialisation is to insert data into a table iteratively and periodically, using a configured date range. More detail on how this works is below.

#### Usage

=== "Manual Load range #1"
    ```jinja
    {{ config(materialized='vault_insert_by_period', 
              timestamp_field='LOAD_DATE', period='day', 
              start_date='2020-01-30') }}
    
    {{ dbtvault.eff_sat(var('src_pk'), var('src_dfk'), var('src_sfk'),
                        var('src_start_date'), var('src_end_date'),
                        var('src_eff'), var('src_ldts'), var('src_source'),
                        var('source_model')) }}
    ```

=== "Manual Load range #2"
    ```jinja
    {{ config(materialized='vault_insert_by_period', 
              timestamp_field='LOAD_DATE', period='day', 
              start_date='2020-01-30', stop_date='2020-04-30') }}
    
    {{ dbtvault.eff_sat(var('src_pk'), var('src_dfk'), var('src_sfk'),
                        var('src_start_date'), var('src_end_date'),
                        var('src_eff'), var('src_ldts'), var('src_source'),
                        var('source_model')) }}
    ```

=== "Manual Load range #3"
    ```jinja
    {{ config(materialized='vault_insert_by_period', 
              timestamp_field='LOAD_DATE', period='day', 
              start_date='2020-01-30', stop_date='2020-04-30',
              date_source_models=var('source_model')) }}
    
    {{ dbtvault.eff_sat(var('src_pk'), var('src_dfk'), var('src_sfk'),
                        var('src_start_date'), var('src_end_date'),
                        var('src_eff'), var('src_ldts'), var('src_source'),
                        var('source_model')) }}
    ```
    
=== "Inferred Load range"
    ```jinja
    {{ config(materialized='vault_insert_by_period', 
              timestamp_field='LOAD_DATE', period='day', 
              date_source_models=var('source_model')) }}
    
    {{ dbtvault.eff_sat(var('src_pk'), var('src_dfk'), var('src_sfk'),
                        var('src_start_date'), var('src_end_date'),
                        var('src_eff'), var('src_ldts'), var('src_source'),
                        var('source_model')) }}
    ```
    
#### Initial/Base Load vs. Incremental Load

Due to the way materialisations currently work in dbt, the model which the `vault_insert_by_period` materialisation is applied to, must be run twice to complete a full load.

The first time a model with the materialisation applied is run, a `BASE LOAD` is executed. This loads all data for the first period in the load date range 
(e.g. The first day's data). All subsequent runs of the same model will execute incremental loads for each consecutive period. 

The first period load will be repeated but no duplicates should be inserted when using dbtvault macros. 

##### Run Output

Examples of output for dbt runs using the `eff_sat` macro and this materialisation.

=== "Initial/Base load"
    ```
    15:24:08 | Concurrency: 4 threads (target='snowflake')
    15:24:08 | 
    15:24:08 | 1 of 1 START vault_insert_by_period model TEST.EFF_SAT..... [RUN]
    15:24:10 | 1 of 1 OK created vault_insert_by_period model TEST.EFF_SAT [BASE LOAD 1 in 1.78s]
    15:24:10 | 
    15:24:10 | Finished running 1 vault_insert_by_period model in 3.99s.
    ```
=== "Incremental load"
    ```
    15:24:16 | Concurrency: 4 threads (target='snowflake')
    15:24:16 | 
    15:24:16 | 1 of 1 START vault_insert_by_period model TEST.EFF_SAT..... [RUN]
    15:24:17 + Running for day 1 of 4 (2020-01-10) [model.dbtvault_test.EFF_SAT]
    15:24:18 + Ran for day 1 of 4 (2020-01-10); 0 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:18 + Running for day 2 of 4 (2020-01-11) [model.dbtvault_test.EFF_SAT]
    15:24:20 + Ran for day 2 of 4 (2020-01-11); 0 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:20 + Running for day 3 of 4 (2020-01-12) [model.dbtvault_test.EFF_SAT]
    15:24:21 + Ran for day 3 of 4 (2020-01-12); 2 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:22 + Running for day 4 of 4 (2020-01-13) [model.dbtvault_test.EFF_SAT]
    15:24:24 + Ran for day 4 of 4 (2020-01-13); 2 records inserted [model.dbtvault_test.EFF_SAT]
    15:24:24 | 1 of 1 OK created vault_insert_by_period model TEST.EFF_SAT [INSERT 4 in 8.13s]
    15:24:25 | 
    15:24:25 | Finished running 1 vault_insert_by_period model in 10.24s.
    ```

#### Configuring the load date range

The start and finish date of the load can be configured in a number of different ways using the above configuration options. 
Depending on how the materialisation is configured, the start and end of the load will get defined differently, as shown in the table below.

| Configuration                | Outcome                                                                                                                  | Usage                | 
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------ | -------------------- |
| `start_date`                 |  The load will start at `start_date`, and the `stop_date` will be set to the **current date**.                           | Manual Load range #1 |
| `start_date` and `stop_date` |  The load will start at `start_date`, and stop at `stop_date`                                                            | Manual Load range #2 |                  
| `date_source_models`         |  The models will be unioned together, and the minimum and maximum dates extracted from the data in the `timestamp_field` | Inferred Load range  |                 
| All three config options     |  Manually provided configuration acts as an override. The load will start at `start_date`, and stop at `stop_date`       | Manual Load range #3 |    

Please refer to the _Usage_ section above to see examples.

#### Required Configuration Options

| Configuration      |  Description                                         | Type                 | Default | Required?                                        |
| ------------------ | ---------------------------------------------------- | -------------------  | ------- | ------------------------------------------------ |
| timestamp_field    |  A list of column names                              | List                 | None    | <i class="fas fa-check-circle required"></i>     |
| period             |  Time period to load over                            | String               | day     | <i class="fas fa-minus-circle not-required"></i> |
| start_date         |  The date to start the load from                     | String (YYYY-MM-DD)  | None    | See: Configuring the load date range             |
| stop_date          |  The date to stop the load on                        | String (YYYY-MM-DD)  | None    | See: Configuring the load date range             |
| date_source_models |  A list of models containing the timestamp_field     | List/String          | None    | See: Configuring the load date range             |

#### Period

The period configuration option allows us to configure the granularity of the load. 

The naming varies per platform, though some common examples are:

- hour
- day
- month
- year

See below for platform specific documentation.

[Snowflake](https://docs.snowflake.com/en/sql-reference/functions-date-time.html#supported-date-and-time-parts)

#### Automatic load range inference

Providing a list of models with the `date_source_models` configuration option, will automatically load all data from the source with
date or date-times between the minimum and maximum values contained in the `timestamp_field` column. 

When using the dbtvault table template macros, `date_source_models` should be the same as the `source_model` attribute in the macro. 

This does not necessarily have to be the case however, and it is possible to create a waterlevel-like table as follows:

=== "waterlevel.sql"
    | TYPE  | LOAD_DATE      |
    | ----- | -------------- |
    | Start | 2020-01-30     |
    | Stop  | 2020-04-30     |

Where `LOAD_DATE` is provided to the materialisation as the `timestamp_field`, and `date_source_models` is provided as `waterlevel` (the model name).

!!! note
    In future versions of dbtvault we will provide configuration options to define different layouts for the `date_source_models`. This would
    allow for more conventional waterlevel tables which store last load dates and start and stop dates on a per-table basis. 

#### Using the materialisation with non-dbtvault SQL

Every [table template macro](macros.md#table-templates) includes a `__PERIOD_FILTER__` string in its SQL when used in conjunction with this materialisation.

At runtime, this string is replaced with SQL which applies conditions to filter the dates contained in the `timestamp_field` to those specified
in the load date range. If you are only using dbtvault table template macros with this materialisation, then there is no need for any additional work.

However, If you are writing your own models and wish to use the this materialisation, then you must include a `WHERE __PERIOD_FILTER__` 
somewhere appropriate in your model. A CTE which selects from your source model and then includes the placeholder, should provide best results. 

See the [hub](https://github.com/Datavault-UK/dbtvault/blob/v0.7.0/macros/tables/hub.sql) source code for further understanding.

#### Idempotent loads

This materialisation supports idempotent loads when used with dbtvault macros. When calculating the `start` and `stop` dates of the load, a `COALESCE` function is applied. 
This `COALESCE` call compares the maximum timestamp contained in the `timestamp_field`, and the provided or inferred `start_date` and sets the `start_date`
to whatever is larger (more recent). This means that any aborted loads will continue where they left off, and any duplicate loads will not have any effect (if using dbtvault macros). 

If you wish support idempotent loads in your own models using this materialisation, the best approach is to use `LEFT OUTER JOINS` to ensure duplicate records are not loaded.