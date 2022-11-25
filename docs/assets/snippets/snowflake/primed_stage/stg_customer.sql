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
    FROM DBTVAULT_SAMPLE.SAMPLE_SCHEMA.CUSTOMER
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
    CAST((MD5_BINARY(NULLIF(UPPER(TRIM(CAST("C_CUSTKEY" AS VARCHAR))), ''))) AS BINARY(16)) AS "CUSTOMER_HK",
    CAST(MD5_BINARY(CONCAT_WS('||',
        IFNULL(NULLIF(UPPER(TRIM(CAST("C_ADDRESS" AS VARCHAR))), ''), '^^'),
        IFNULL(NULLIF(UPPER(TRIM(CAST("C_NAME" AS VARCHAR))), ''), '^^'),
        IFNULL(NULLIF(UPPER(TRIM(CAST("C_PHONE" AS VARCHAR))), ''), '^^')
    )) AS BINARY(16)) AS "CUST_CUSTOMER_HASHDIFF"
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
    "CUSTOMER_HK",
    "CUST_CUSTOMER_HASHDIFF"
    FROM hashed_columns
)
SELECT * FROM columns_to_select