WITH source_data AS (
    SELECT
    "C_CUSTKEY",
    "C_NAME",
    "C_ADDRESS",
    "C_NATIONKEY",
    "C_PHONE",
    "C_ACCTBAL",
    "C_MKTSEGMENT",
    "C_COMMENT"
    FROM "DBTVAULT_DEV"."TEST"."CUSTOMER"
),
derived_columns AS (
    SELECT
    "C_CUSTKEY",
    "C_NAME",
    "C_ADDRESS",
    "C_NATIONKEY",
    "C_PHONE",
    "C_ACCTBAL",
    "C_MKTSEGMENT",
    "C_COMMENT",
    C_CUSTKEY AS "CUSTOMER_ID",
    '1998-01-01' AS "LOAD_DATETIME",
    'TPCH_CUSTOMER' AS "RECORD_SOURCE"
    FROM source_data
),
hashed_columns AS (
    SELECT
    "C_CUSTKEY",
    "C_NAME",
    "C_ADDRESS",
    "C_NATIONKEY",
    "C_PHONE",
    "C_ACCTBAL",
    "C_MKTSEGMENT",
    "C_COMMENT",
    "CUSTOMER_ID",
    "LOAD_DATETIME",
    "RECORD_SOURCE",
    CAST(HASHBYTES('MD5', NULLIF(UPPER(TRIM(CAST("C_CUSTKEY" AS VARCHAR(max)))), '')) AS BINARY(16)) AS "CUSTOMER_HK"
    FROM derived_columns
),
columns_to_select AS (
    SELECT
    "C_CUSTKEY",
    "C_NAME",
    "C_ADDRESS",
    "C_NATIONKEY",
    "C_PHONE",
    "C_ACCTBAL",
    "C_MKTSEGMENT",
    "C_COMMENT",
    "CUSTOMER_ID",
    "LOAD_DATETIME",
    "RECORD_SOURCE",
    "CUSTOMER_HK"
    FROM hashed_columns
)
SELECT * FROM columns_to_select