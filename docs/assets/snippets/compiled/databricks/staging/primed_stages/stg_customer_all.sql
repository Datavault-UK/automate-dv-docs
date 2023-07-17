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
    C_CUSTKEY AS CUSTOMER_ID,
    '1998-01-01' AS LOAD_DATETIME,
    'TPCH_CUSTOMER' AS RECORD_SOURCE
    FROM source_data
),
null_columns AS (
    SELECT
    c_custkey,
    c_address,
    c_nationkey,
    c_phone,
    c_acctbal,
    c_mktsegment,
    c_comment,
    LOAD_DATETIME,
    RECORD_SOURCE,
    CUSTOMER_ID AS CUSTOMER_ID_ORIGINAL,
        IFNULL(CUSTOMER_ID, '-1') AS CUSTOMER_ID,
    C_NAME AS C_NAME_ORIGINAL,
        IFNULL(C_NAME, '-2') AS C_NAME
    FROM derived_columns
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
    CUSTOMER_ID_ORIGINAL,
    C_NAME_ORIGINAL,
    CAST(UPPER(MD5(NULLIF(UPPER(TRIM(CAST(C_CUSTKEY AS VARCHAR(16)))), ''))) AS STRING) AS CUSTOMER_HK
    FROM null_columns
),
ranked_columns AS (
    SELECT *,
    RANK() OVER (PARTITION BY CUSTOMER_HK ORDER BY LOAD_DATETIME) AS AUTOMATE_DV_RANK
    FROM hashed_columns
),
columns_to_select AS (
    SELECT
    c_custkey,
    c_address,
    c_nationkey,
    c_phone,
    c_acctbal,
    c_mktsegment,
    c_comment,
    CUSTOMER_ID,
    LOAD_DATETIME,
    RECORD_SOURCE,
    CUSTOMER_ID_ORIGINAL,
    C_NAME,
    C_NAME_ORIGINAL,
    CUSTOMER_HK,
    AUTOMATE_DV_RANK
    FROM ranked_columns
)
SELECT * FROM columns_to_select