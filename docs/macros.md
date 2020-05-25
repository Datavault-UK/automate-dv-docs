## Table templates
######(macros/tables)

These macros are the core of the package and can be called in your models to build the different types of tables needed
for your Data Vault.

### hub 
([view source](https://github.com/Datavault-UK/dbtvault/blob/v0.6/macros/tables/hub.sql))

!!! note
    In v0.6, we have made changes to the hub macro sql. The hub macro now deals with multi date loads.   

Generates SQL to build a hub table using the provided metadata in your `dbt_project.yml`.

``` sql

{{ dbtvault.hub(var('src_pk'), var('src_nk'), var('src_ldts'),
                var('src_source'), var('source_model'))        }}
```

#### Parameters

!!! note 
    Due to suggestions stating that the ```source``` var in the YAML file was causing confusion. We have decided to 
    refactor this into ```source_model``` to reduce confusion and add more clarity to the usage of dbtvault. Please see
    the YAML usage for examples.

| Parameter     | Description                                         | Type (Single-Source) | Type (Multi-Source) | Required?                                                          |
| ------------- | --------------------------------------------------- | -------------------- | ------------------- | ------------------------------------------------------------------ |
| src_pk        | Source primary key column                           | String               | String              | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_nk        | Source natural key column                           | String               | String              | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_ldts      | Source loaddate timestamp column                    | String               | String              | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_source    | Name of the column containing the source ID         | String               | String              | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| source_model  | Staging model name                                  | String               | List (YAML)         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
                                                                                                                    
#### Usage

``` sql

{{ dbtvault.hub(var('src_pk'), var('src_nk'), var('src_ldts'),
                var('src_source'), var('source_model'))        }}
```

#### Example YAML Metadata

[See examples](metadata.md#hubs)

#### Example Output

```mysql tab='Single-Source'
WITH STG AS (
    SELECT DISTINCT
    a.CUSTOMER_PK, a.CUSTOMER_ID, a.LOADDATE, a.SOURCE
    FROM (
        SELECT b.*,
        ROW_NUMBER() OVER(
            PARTITION BY b.CUSTOMER_PK
            ORDER BY b.LOADDATE, b.SOURCE ASC
        ) AS RN
        FROM MYDATABASE.MYSCHEMA.v_stg_orders AS b
        WHERE b.CUSTOMER_PK IS NOT NULL
    ) AS a
    WHERE RN = 1
)

SELECT c.* FROM STG AS c
LEFT JOIN MYDATABASE.MYSCHEMA.hub_customer AS d 
ON c.CUSTOMER_PK = d.CUSTOMER_PK
WHERE d.CUSTOMER_PK IS NULL
```

```mysql tab='Multi-Source'
WITH STG_1 AS (
    SELECT DISTINCT
    a.PART_PK, a.PART_ID, a.LOADDATE, a.SOURCE
    FROM (
        SELECT PART_PK, PART_ID, LOADDATE, SOURCE,
        ROW_NUMBER() OVER(
            PARTITION BY PART_PK
            ORDER BY LOADDATE ASC
        ) AS RN
        FROM MYDATABASE.MYSCHEMA.v_stg_parts
    ) AS a
    WHERE RN = 1
),
STG_2 AS (
    SELECT DISTINCT
    a.PART_PK, a.PART_ID, a.LOADDATE, a.SOURCE
    FROM (
        SELECT PART_PK, PART_ID, LOADDATE, SOURCE,
        ROW_NUMBER() OVER(
            PARTITION BY PART_PK
            ORDER BY LOADDATE ASC
        ) AS RN
        FROM MYDATABASE.MYSCHEMA.v_stg_supplier
    ) AS a
    WHERE RN = 1
),
STG_3 AS (
    SELECT DISTINCT
    a.PART_PK, a.PART_ID, a.LOADDATE, a.SOURCE
    FROM (
        SELECT PART_PK, PART_ID, LOADDATE, SOURCE,
        ROW_NUMBER() OVER(
            PARTITION BY PART_PK
            ORDER BY LOADDATE ASC
        ) AS RN
        FROM MYDATABASE.MYSCHEMA.v_stg_lineitem
    ) AS a
    WHERE RN = 1
),
STG AS (
    SELECT DISTINCT
    b.PART_PK, b.PART_ID, b.LOADDATE, b.SOURCE
    FROM (
            SELECT *,
            ROW_NUMBER() OVER(
                PARTITION BY PART_PK
                ORDER BY LOADDATE, SOURCE ASC
            ) AS RN
            FROM (
                SELECT * FROM STG_1
                UNION ALL
                SELECT * FROM STG_2
                UNION ALL
                SELECT * FROM STG_3
            )
        WHERE PART_PK IS NOT NULL
    ) AS b
    WHERE RN = 1
)

SELECT c.* FROM STG AS c
```
___

### link

!!! note
    In v0.6, we have made changes to the link macro sql. The link macro now deals with multi date loads. 

Generates sql to build a link table using the provided metadata in your `dbt_project.yml`.
``` sql
{{ dbtvault.link(var('src_pk'), var('src_fk'), var('src_ldts'),
                 var('src_source'), var('source_model'))        }}
```

#### Parameters

!!! note 
    Due to suggestions stating that the ```source``` var in the YAML file was causing confusion. We have decided to 
    refactor this into ```source_model``` to reduce confusion and add more clarity to the usage of dbtvault. Please see
    the YAML usage for examples.

| Parameter     | Description                                         | Type (Single-Source) | Type (Union)         | Required?                                                          |
| ------------- | --------------------------------------------------- | ---------------------| ---------------------| ------------------------------------------------------------------ |
| src_pk        | Source primary key column                           | String               | String               | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_fk        | Source foreign key column(s)                        | List (YAML)          | List (YAML)          | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_ldts      | Source loaddate timestamp column                    | String               | String               | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_source    | Name of the column containing the source ID         | String               | String               | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| source_model  | Staging model name                                  | String               | List (YAML)          | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |

#### Usage

``` sql
{{ dbtvault.link(var('src_pk'), var('src_fk'), var('src_ldts'),
                 var('src_source'), var('source_model'))        }}
```                                                  

#### Example YAML Metadata

[See examples](metadata.md#links)

#### Example Output

```mysql tab='Single-Source'
WITH STG AS (
    SELECT DISTINCT
    a.CUSTOMER_NATION_PK, a.CUSTOMER_FK, a.NATION_FK, a.LOADDATE, a.SOURCE
    FROM (
        SELECT b.*,
        ROW_NUMBER() OVER(
            PARTITION BY b.CUSTOMER_NATION_PK
            ORDER BY b.LOADDATE, b.SOURCE ASC
        ) AS RN
        FROM MYDATABASE.MYSCHEMA.v_stg_orders AS b
        WHERE
        b.CUSTOMER_FK IS NOT NULL AND
        b.NATION_FK IS NOT NULL
    ) AS a
    WHERE RN = 1
)

SELECT c.* FROM STG AS c
LEFT JOIN MYDATABASE.MYSCHEMA.link_customer_nation_current AS d 
ON c.CUSTOMER_NATION_PK = d.CUSTOMER_NATION_PK
WHERE d.CUSTOMER_NATION_PK IS NULL
```

```mysql tab='Union'
WITH STG_1 AS (
    SELECT DISTINCT
    a.CUSTOMER_NATION_PK, a.CUSTOMER_FK, a.NATION_FK, a.LOADDATE, a.SOURCE
    FROM (
        SELECT CUSTOMER_NATION_PK, CUSTOMER_FK, NATION_FK, LOADDATE, SOURCE,
        ROW_NUMBER() OVER(
            PARTITION BY CUSTOMER_NATION_PK
            ORDER BY LOADDATE ASC
        ) AS RN
        FROM MYDATABASE.MYSCHEMA.v_stg_customer_sap
    ) AS a
    WHERE RN = 1
),
STG_2 AS (
    SELECT DISTINCT
    a.CUSTOMER_NATION_PK, a.CUSTOMER_FK, a.NATION_FK, a.LOADDATE, a.SOURCE
    FROM (
        SELECT CUSTOMER_NATION_PK, CUSTOMER_FK, NATION_FK, LOADDATE, SOURCE,
        ROW_NUMBER() OVER(
            PARTITION BY CUSTOMER_NATION_PK
            ORDER BY LOADDATE ASC
        ) AS RN
        FROM MYDATABASE.MYSCHEMA.v_stg_customer_crm
    ) AS a
    WHERE RN = 1
),
STG_3 AS (
    SELECT DISTINCT
    a.CUSTOMER_NATION_PK, a.CUSTOMER_FK, a.NATION_FK, a.LOADDATE, a.SOURCE
    FROM (
        SELECT CUSTOMER_NATION_PK, CUSTOMER_FK, NATION_FK, LOADDATE, SOURCE,
        ROW_NUMBER() OVER(
            PARTITION BY CUSTOMER_NATION_PK
            ORDER BY LOADDATE ASC
        ) AS RN
        FROM MYDATABASE.MYSCHEMA.v_stg_customer_web
    ) AS a
    WHERE RN = 1
),
STG AS (
    SELECT DISTINCT
    b.CUSTOMER_NATION_PK, b.CUSTOMER_FK, b.NATION_FK, b.LOADDATE, b.SOURCE
    FROM (
        SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY CUSTOMER_NATION_PK
            ORDER BY LOADDATE, SOURCE ASC
        ) AS RN
        FROM (
            SELECT * FROM STG_1
            UNION ALL
            SELECT * FROM STG_2
            UNION ALL
            SELECT * FROM STG_3
        )
        WHERE
        CUSTOMER_FK IS NOT NULL AND
        NATION_FK IS NOT NULL
    ) AS b
    WHERE RN = 1
)

SELECT c.* FROM STG AS c
```

___

### sat

Generates sql to build a satellite table using the provided metadata in your `dbt_project.yml`.

``` sql
{{ dbtvault.sat(var('src_pk'), var('src_hashdiff'), var('src_payload'),
                var('src_eff'), var('src_ldts'), var('src_source'),
                var('source_model'))                                   }}
```

#### Parameters

| Parameter     | Description                                         | Type           | Required?                                                          |
| ------------- | --------------------------------------------------- | -------------- | ------------------------------------------------------------------ |
| src_pk        | Source primary key column                           | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_hashdiff  | Source hashdiff column                              | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_payload   | Source payload column(s)                            | List (YAML)    | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_eff       | Source effective from column                        | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_ldts      | Source loaddate timestamp column                    | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_source    | Name of the column containing the source ID         | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| source_model  | Staging model name                                  | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |

#### Usage


``` sql
{{ dbtvault.sat(var('src_pk'), var('src_hashdiff'), var('src_payload'),
                var('src_eff'), var('src_ldts'), var('src_source'),
                var('source_model'))                                   }}
```

#### Example YAML Metadata

[See examples](metadata.md#satellites)

#### Example Output

```mysql
SELECT DISTINCT 
                    e.CUSTOMER_PK,
                    e.CUSTOMER_HASHDIFF,
                    e.NAME,
                    e.ADDRESS,
                    e.PHONE,
                    e.ACCBAL,
                    e.MKTSEGMENT,
                    e.COMMENT,
                    e.EFFECTIVE_FROM,
                    e.LOADDATE,
                    e.SOURCE
FROM MYDATABASE.MYSCHEMA.v_stg_orders AS e
LEFT JOIN (
    SELECT d.CUSTOMER_PK, d.CUSTOMER_HASHDIFF, d.NAME, d.ADDRESS, d.PHONE, d.ACCBAL, d.MKTSEGMENT, d.COMMENT, d.EFFECTIVE_FROM, d.LOADDATE, d.SOURCE
    FROM (
          SELECT c.CUSTOMER_PK, c.CUSTOMER_HASHDIFF, c.NAME, c.ADDRESS, c.PHONE, c.ACCBAL, c.MKTSEGMENT, c.COMMENT, c.EFFECTIVE_FROM, c.LOADDATE, c.SOURCE,
          CASE WHEN RANK()
          OVER (PARTITION BY c.CUSTOMER_PK
          ORDER BY c.LOADDATE DESC) = 1
          THEN 'Y' ELSE 'N' END CURR_FLG
          FROM (
            SELECT a.CUSTOMER_PK, a.CUSTOMER_HASHDIFF, a.NAME, a.ADDRESS, a.PHONE, a.ACCBAL, a.MKTSEGMENT, a.COMMENT, a.EFFECTIVE_FROM, a.LOADDATE, a.SOURCE
            FROM MYDATABASE.MYSCHEMA.sat_order_customer_details as a
            JOIN MYDATABASE.MYSCHEMA.v_stg_orders as b
            ON a.CUSTOMER_PK = b.CUSTOMER_PK
          ) as c
    ) AS d
WHERE d.CURR_FLG = 'Y') AS src
ON src.CUSTOMER_HASHDIFF = e.CUSTOMER_HASHDIFF
WHERE src.CUSTOMER_HASHDIFF IS NULL
```
___

### t_link

Generates sql to build a transactional link table using the provided metadata in your `dbt_project.yml`.

``` sql
{{ dbtvault.t_link(var('src_pk'), var('src_fk'), var('src_payload'),
                   var('src_eff'), var('src_ldts'), var('src_source'),
                   var('source_model'))                                }}
```

#### Parameters

| Parameter     | Description                                         | Type           | Required?                                                          |
| ------------- | --------------------------------------------------- | -------------- | ------------------------------------------------------------------ |
| src_pk        | Source primary key column                           | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_fk        | Source foreign key column(s)                        | List (YAML)    | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_payload   | Source payload column(s)                            | List (YAML)    | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_eff       | Source effective from column                        | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_ldts      | Source loaddate timestamp column                    | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| src_source    | Name of the column containing the source ID         | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| source_model  | Staging model name                                  | String         | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |

#### Usage

``` sql
{{ dbtvault.t_link(var('src_pk'), var('src_fk'), var('src_payload'),
                   var('src_eff'), var('src_ldts'), var('src_source'),
                   var('source_model'))                                }}
```

#### Example YAML Metadata

[See examples](metadata.md#transactional-links-non-historized-links)

#### Example Output

```mysql
SELECT DISTINCT 
                    stg.TRANSACTION_PK,
                    stg.CUSTOMER_FK,
                    stg.ORDER_FK,
                    stg.TRANSACTION_NUMBER,
                    stg.TRANSACTION_DATE,
                    stg.TYPE,
                    stg.AMOUNT,
                    stg.EFFECTIVE_FROM,
                    stg.LOADDATE,
                    stg.SOURCE
FROM (
      SELECT stg.TRANSACTION_PK, stg.CUSTOMER_FK, stg.ORDER_FK, stg.TRANSACTION_NUMBER, stg.TRANSACTION_DATE, stg.TYPE, stg.AMOUNT, stg.EFFECTIVE_FROM, stg.LOADDATE, stg.SOURCE
      FROM MYDATABASE.MYSCHEMA.v_stg_transactions AS stg
) AS stg
LEFT JOIN MYDATABASE.MYSCHEMA.t_link_transactions AS tgt
ON stg.TRANSACTION_PK = tgt.TRANSACTION_PK
WHERE tgt.TRANSACTION_PK IS NULL
```
___

### eff_sat

This macro has not yet been released, it needs some further development. 

If you would like to test it out, it is available in [v0.6-b2](https://dbtvault.readthedocs.io/en/v0.6-b2/macros/#eff_sat). 

___

## Staging Macros
######(macros/staging)

These macros are intended for use in the staging layer.
___

### stage

Generates sql to build a staging area using the provided metadata in your `dbt_project.yml`.

#### Parameters

| Parameter              | Description                                       | Type           | Default    | Required?                                                          |
| ---------------------- | ------------------------------------------------- | -------------- | ---------- | ------------------------------------------------------------------ |
| include_source_columns | If true, select all columns in the `source_model` | Boolean        | true       | <i class="md-icon" style="color: red">clear</i>                    |
| source_model           | Staging model name                                | String/Mapping | N/A        | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| hashed_columns         | Mappings of hashes to their component columns     | String/Mapping | none       | <i class="md-icon" style="color: red">clear</i>                    |
| derived_columns        | Mappings of constants to their source columns     | String/Mapping | none       | <i class="md-icon" style="color: red">clear</i>                    |

#### Usage

``` sql
{{ dbtvault.stage(include_source_columns=var('include_source_columns', none), 
                  source_model=var('source_model', none), 
                  hashed_columns=var('hashed_columns', none), 
                  derived_columns=var('derived_columns', none)) }}
```

#### Example YAML Metadata

[See examples](metadata.md#staging)

#### Example Output

```sql tab='All variables'

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

```sql tab="Only source"

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

```sql tab='Only hashing'

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


```sql tab="Only derived"

SELECT

'STG_BOOKING' AS SOURCE,
BOOKING_DATE AS EFFECTIVE_FROM

FROM MY_DATABASE.MY_SCHEMA.raw_source
```

___

### hash_columns

Generates sql to create hashes from provided columns.

#### Parameters

| Parameter              | Description                                       | Type           | Default    | Required?                                                          |
| ---------------------- | ------------------------------------------------- | -------------- | ---------- | ------------------------------------------------------------------ |
| include_source_columns | If true, select all columns in the `source_model` | Boolean        | true       | <i class="md-icon" style="color: red">clear</i>                    |
| source_model           | Staging model name                                | String/Mapping | N/A        | <i class="md-icon" alt="Yes" style="color: green">check_circle</i> |
| hashed_columns         | Mappings of hashes to their component columns     | String/Mapping | none       | <i class="md-icon" style="color: red">clear</i>                    |
| derived_columns        | Mappings of constants to their source columns     | String/Mapping | none       | <i class="md-icon" style="color: red">clear</i>                    |

#### Usage

``` sql
{{ dbtvault.stage(include_source_columns=var('include_source_columns', none), 
                  source_model=var('source_model', none), 
                  hashed_columns=var('hashed_columns', none), 
                  derived_columns=var('derived_columns', none)) }}
```

#### Example YAML Metadata

```yaml tab='All variables'
models:
  my_dbtvault_project:
    staging:
      my_staging_model:
        vars:
          source_model: "raw_source"
          hashed_columns:
            CUSTOMER_PK: "CUSTOMER_ID"
            CUST_CUSTOMER_HASHDIFF:
              hashdiff: true
              columns:
                - "CUSTOMER_DOB"
                - "CUSTOMER_ID"
                - "CUSTOMER_NAME"
            CUSTOMER_HASHDIFF:
              hashdiff: true
              columns:
                - "CUSTOMER_ID"
                - "NATIONALITY"
                - "PHONE"
          derived_columns:
            SOURCE: "!STG_BOOKING"
            EFFECTIVE_FROM: "BOOKING_DATE"
```

#### Example Output

```sql tab='All variables'

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

### derive_columns

___

## Supporting Macros
######(macros/supporting)

Supporting macros are helper functions for use in models. It should not be necessary to call these macros directly, however they 
are used extensively in the [table templates](#table-templates) and may be used for your own purposes if you wish. 

___

### cast

A macro for generating cast sequences:

```mysql
CAST(prefix.column AS type) AS alias
```

#### Parameters

| Parameter        |  Description                  | Required?                                                |
| ---------------- | ----------------------------- | -------------------------------------------------------- |
| columns          |  Triples or strings           | <i class="md-icon" style="color: green">check_circle</i> |
| prefix           |  A string                     | <i class="md-icon" style="color: red">clear</i>          |

#### Usage

!!! note
    As shown in the snippet below, columns must be provided as a list. 
    The collection of items in this list can be any combination of:

    - ```(column, type, alias) ``` 3-tuples 
    - ```[column, type, alias] ``` 3-item lists
    - ```'DOB'``` Single strings.

```yaml

{%- set tgt_pk = ['PART_PK', 'BINARY(16)', 'PART_PK']        -%}

{{ dbtvault.cast([tgt_pk,
                  'DOB',
                  ('PART_PK', 'NUMBER(38,0)', 'PART_ID'),
                  ('LOADDATE', 'DATE', 'LOADDATE'),
                  ('SOURCE', 'VARCHAR(15)', 'SOURCE')], 
                  'stg')                                      }}
```

#### Output

```mysql
CAST(stg.PART_PK AS BINARY(16)) AS PART_PK,
stg.DOB,
CAST(stg.PART_ID AS NUMBER(38,0)) AS PART_ID,
CAST(stg.LOADDATE AS DATE) AS LOADDATE,
CAST(stg.SOURCE AS VARCHAR(15)) AS SOURCE
```

___

### hash

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
    
A macro for generating hashing SQL for columns:

```sql tab='MD5'
CAST(MD5_BINARY(UPPER(TRIM(CAST(column AS VARCHAR)))) AS BINARY(16)) AS alias
```

```sql tab='SHA'
CAST(SHA2_BINARY(UPPER(TRIM(CAST(column AS VARCHAR)))) AS BINARY(32)) AS alias
```

#### Parameters

| Parameter        |  Description                                     | Type        | Required?                                                |
| ---------------- | -----------------------------------------------  | ----------- | -------------------------------------------------------- |
| columns          |  Columns to hash on                              | String/List | <i class="md-icon" style="color: green">check_circle</i> |
| alias            |  The name to give the hashed column              | String      | <i class="md-icon" style="color: green">check_circle</i> |
| hashdiff         |  Will alpha sort columns if true, default false. | Boolean     | <i class="md-icon" style="color: red">clear</i>          |
                                

#### Usage

```yaml
{{ dbtvault.hash('CUSTOMERKEY', 'CUSTOMER_PK') }},
{{ dbtvault.hash(['CUSTOMERKEY', 'PHONE', 'DOB', 'NAME'], 'HASHDIFF', true) }}
```

!!! tip
    [hash_columns](#hash_columns) may be used to simplify the hashing process and generate multiple hashes with one macro.

#### Output

```mysql tab='MD5'
CAST(MD5_BINARY(UPPER(TRIM(CAST(CUSTOMERKEY AS VARCHAR)))) AS BINARY(16)) AS CUSTOMER_PK,
CAST(MD5_BINARY(CONCAT(IFNULL(UPPER(TRIM(CAST(CUSTOMERKEY AS VARCHAR))), '^^'), '||',
                       IFNULL(UPPER(TRIM(CAST(DOB AS VARCHAR))), '^^'), '||',
                       IFNULL(UPPER(TRIM(CAST(NAME AS VARCHAR))), '^^'), '||',
                       IFNULL(UPPER(TRIM(CAST(PHONE AS VARCHAR))), '^^') )) 
                       AS BINARY(16)) AS HASHDIFF
```

```mysql tab='SHA'
CAST(SHA2_BINARY(UPPER(TRIM(CAST(CUSTOMERKEY AS VARCHAR)))) AS BINARY(32)) AS CUSTOMER_PK,
CAST(SHA2_BINARY(CONCAT(IFNULL(UPPER(TRIM(CAST(CUSTOMERKEY AS VARCHAR))), '^^'), '||',
                        IFNULL(UPPER(TRIM(CAST(DOB AS VARCHAR))), '^^'), '||',
                        IFNULL(UPPER(TRIM(CAST(NAME AS VARCHAR))), '^^'), '||',
                        IFNULL(UPPER(TRIM(CAST(PHONE AS VARCHAR))), '^^') )) 
                        AS BINARY(32)) AS HASHDIFF
```

___

### prefix

A macro for quickly prefixing a list of columns with a string:
```mysql
a.column1, a.column2, a.column3, a.column4
```

#### Parameters

| Parameter        |  Description                  | Type   | Required?                                                |
| ---------------- | ----------------------------- | ------ | -------------------------------------------------------- |
| columns          |  A list of column names       | List   | <i class="md-icon" style="color: green">check_circle</i> |
| prefix_str       |  The prefix for the columns   | String | <i class="md-icon" style="color: green">check_circle</i> |

#### Usage

```sql
{{ dbtvault.prefix(['CUSTOMERKEY', 'DOB', 'NAME', 'PHONE'], 'a') }}
{{ dbtvault.prefix(['CUSTOMERKEY'], 'a') }}
```

!!! Note
    Single columns must be provided as a 1-item list, as in the second example above.

#### Output

```mysql
a.CUSTOMERKEY, a.DOB, a.NAME, a.PHONE
a.CUSTOMERKEY
```

___

## Internal
######(macros/internal)

Internal macros are used by other macros provided in this package. 
They are used to process provided metadata and should not need to be called directly. 

___