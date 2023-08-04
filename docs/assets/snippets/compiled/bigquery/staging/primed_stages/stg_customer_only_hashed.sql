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
    FROM `dbtvault-341416`.`dbtvault`.`CUSTOMER`
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
    CAST(UPPER(TO_HEX(MD5(NULLIF(UPPER(TRIM(CAST(C_CUSTKEY AS STRING))), '')))) AS STRING) AS CUSTOMER_HK
    FROM source_data
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
    CUSTOMER_HK
    FROM hashed_columns
)
SELECT * FROM columns_to_select