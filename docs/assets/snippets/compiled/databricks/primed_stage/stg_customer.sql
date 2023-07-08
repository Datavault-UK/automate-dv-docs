-- Generated by AutomateDV (formerly known as dbtvault)
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
    c_custkey AS CUSTOMER_ID,
    '1998-01-01' AS LOAD_DATETIME,
    'TPCH_CUSTOMER' AS RECORD_SOURCE
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
    CUSTOMER_ID,
    LOAD_DATETIME,
    RECORD_SOURCE,
    CAST(UPPER(MD5(NULLIF(UPPER(TRIM(CAST(c_custkey AS VARCHAR(16)))), ''))) AS STRING) AS CUSTOMER_HK
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
    CUSTOMER_ID,
    LOAD_DATETIME,
    RECORD_SOURCE,
    CUSTOMER_HK
    FROM hashed_columns
)
SELECT * FROM columns_to_select