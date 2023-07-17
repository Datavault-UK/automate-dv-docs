WITH source_data AS (
    SELECT
    C_CUSTKEY,
    C_NAME,
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT
    FROM ALEX_HIGGS.AUTOMATE_DV_DOCS_SAMPLES.CUSTOMER
),
derived_columns AS (
    SELECT
    C_CUSTKEY,
    C_NAME,
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT,
    '1' AS ORDER_ID,
    c_custkey AS CUSTOMER_ID,
    1 AS CUSTOMER_PHONE_LOCATOR_ID,
    '1998-07-01' AS LOAD_DATETIME,
    '1998-01-01' AS EFFECTIVE_FROM,
    '1998-01-01' AS START_DATE,
    '1998-01-01' AS END_DATE,
    'TPCH_ORDERS' AS RECORD_SOURCE
    FROM source_data
),
hashed_columns AS (
    SELECT
    C_CUSTKEY,
    C_NAME,
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT,
    ORDER_ID,
    CUSTOMER_ID,
    CUSTOMER_PHONE_LOCATOR_ID,
    LOAD_DATETIME,
    EFFECTIVE_FROM,
    START_DATE,
    END_DATE,
    RECORD_SOURCE,
    CAST(MD5_BINARY(NULLIF(UPPER(TRIM(CAST(c_custkey AS VARCHAR))), '')) AS BINARY(16)) AS CUSTOMER_HK,
    CAST(MD5_BINARY(NULLIF(UPPER(TRIM(CAST(ORDER_ID AS VARCHAR))), '')) AS BINARY(16)) AS ORDER_HK,
    CAST(MD5_BINARY(NULLIF(CONCAT(
        IFNULL(NULLIF(UPPER(TRIM(CAST(c_custkey AS VARCHAR))), ''), '^^'), '||',
        IFNULL(NULLIF(UPPER(TRIM(CAST('1' AS VARCHAR))), ''), '^^')
    ), '^^||^^')) AS BINARY(16)) AS CUSTOMER_ORDER_HK
    FROM derived_columns
),
columns_to_select AS (
    SELECT
    C_CUSTKEY,
    C_NAME,
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT,
    ORDER_ID,
    CUSTOMER_ID,
    CUSTOMER_PHONE_LOCATOR_ID,
    LOAD_DATETIME,
    EFFECTIVE_FROM,
    START_DATE,
    END_DATE,
    RECORD_SOURCE,
    CUSTOMER_HK,
    ORDER_HK,
    CUSTOMER_ORDER_HK
    FROM hashed_columns
)
SELECT * FROM columns_to_select