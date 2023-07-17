WITH source_data AS (
    SELECT
    c_custkey,
    c_name,
    c_address,
    c_nationkey,
    c_phone,
    c_acctbal,
    c_mktsegment,
    c_comment
    FROM `hive_metastore`.`dbtvault`.`CUSTOMER`
),
derived_columns AS (
    SELECT
    c_custkey,
    c_name,
    c_address,
    c_nationkey,
    c_phone,
    c_acctbal,
    c_mktsegment,
    c_comment,
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
    c_custkey,
    c_name,
    c_address,
    c_nationkey,
    c_phone,
    c_acctbal,
    c_mktsegment,
    c_comment,
    ORDER_ID,
    CUSTOMER_ID,
    CUSTOMER_PHONE_LOCATOR_ID,
    LOAD_DATETIME,
    EFFECTIVE_FROM,
    START_DATE,
    END_DATE,
    RECORD_SOURCE,
    CAST(UPPER(MD5(NULLIF(UPPER(TRIM(CAST(c_custkey AS VARCHAR(16)))), ''))) AS STRING) AS CUSTOMER_HK,
    CAST(UPPER(MD5(NULLIF(UPPER(TRIM(CAST(ORDER_ID AS VARCHAR(16)))), ''))) AS STRING) AS ORDER_HK,
    CAST(UPPER(MD5(NULLIF(CONCAT(
        IFNULL(NULLIF(UPPER(TRIM(CAST(c_custkey AS VARCHAR(16)))), ''), '^^'), '||',
        IFNULL(NULLIF(UPPER(TRIM(CAST('1' AS VARCHAR(16)))), ''), '^^')
    ), '^^||^^'))) AS STRING) AS CUSTOMER_ORDER_HK
    FROM derived_columns
),
columns_to_select AS (
    SELECT
    c_custkey,
    c_name,
    c_address,
    c_nationkey,
    c_phone,
    c_acctbal,
    c_mktsegment,
    c_comment,
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