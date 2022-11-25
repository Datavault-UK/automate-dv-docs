WITH source_data AS (
    SELECT
    `C_CUSTKEY`,
    `C_NAME`,
    `C_ADDRESS`,
    `C_NATIONKEY`,
    `C_PHONE`,
    `C_ACCTBAL`,
    `C_MKTSEGMENT`,
    `C_COMMENT`
    FROM `dbtvault-341416`.`dbtvault`.`CUSTOMER`
),
derived_columns AS (
    SELECT
    `C_CUSTKEY`,
    `C_NAME`,
    `C_ADDRESS`,
    `C_NATIONKEY`,
    `C_PHONE`,
    `C_ACCTBAL`,
    `C_MKTSEGMENT`,
    `C_COMMENT`,
    C_CUSTKEY AS `CUSTOMER_ID`,
    '1998-01-01' AS `LOAD_DATETIME`,
    'TPCH_CUSTOMER' AS `RECORD_SOURCE`
    FROM source_data
),
hashed_columns AS (
    SELECT
    `C_CUSTKEY`,
    `C_NAME`,
    `C_ADDRESS`,
    `C_NATIONKEY`,
    `C_PHONE`,
    `C_ACCTBAL`,
    `C_MKTSEGMENT`,
    `C_COMMENT`,
    `CUSTOMER_ID`,
    `LOAD_DATETIME`,
    `RECORD_SOURCE`,
    CAST(UPPER(TO_HEX(MD5(NULLIF(UPPER(TRIM(CAST(`C_CUSTKEY` AS STRING))), '')))) AS STRING) AS `CUSTOMER_HK`,
    UPPER(TO_HEX(MD5(CONCAT(
        IFNULL(NULLIF(UPPER(TRIM(CAST(`C_ADDRESS` AS STRING))), ''), '^^'),'||',
        IFNULL(NULLIF(UPPER(TRIM(CAST(`C_NAME` AS STRING))), ''), '^^'),'||',
        IFNULL(NULLIF(UPPER(TRIM(CAST(`C_PHONE` AS STRING))), ''), '^^')
    )))) AS `CUST_CUSTOMER_HASHDIFF`
    FROM derived_columns
),
columns_to_select AS (
    SELECT
    `C_CUSTKEY`,
    `C_NAME`,
    `C_ADDRESS`,
    `C_NATIONKEY`,
    `C_PHONE`,
    `C_ACCTBAL`,
    `C_MKTSEGMENT`,
    `C_COMMENT`,
    `CUSTOMER_ID`,
    `LOAD_DATETIME`,
    `RECORD_SOURCE`,
    `CUSTOMER_HK`,
    `CUST_CUSTOMER_HASHDIFF`
    FROM hashed_columns
)
SELECT * FROM columns_to_select