WITH source_data AS (
    SELECT
    o_orderkey,
    o_custkey,
    o_orderstatus,
    o_totalprice,
    o_orderdate,
    o_orderpriority,
    o_clerk,
    o_shippriority,
    o_comment
    FROM `hive_metastore`.`dbtvault`.`ORDERS`
),
derived_columns AS (
    SELECT
    o_orderkey,
    o_custkey,
    o_orderstatus,
    o_totalprice,
    o_orderdate,
    o_orderpriority,
    o_clerk,
    o_shippriority,
    o_comment,
    o_custkey AS CUSTOMER_ID,
    o_orderkey AS ORDER_ID,
    cast('1998-07-01' as date) AS LOAD_DATETIME,
    cast('1998-01-01' as date) AS EFFECTIVE_FROM,
    cast('1998-01-01' as date) AS START_DATE,
    cast('1998-01-01' as date) AS END_DATE,
    'TPCH_ORDERS' AS RECORD_SOURCE
    FROM source_data
),
hashed_columns AS (
    SELECT
    o_orderkey,
    o_custkey,
    o_orderstatus,
    o_totalprice,
    o_orderdate,
    o_orderpriority,
    o_clerk,
    o_shippriority,
    o_comment,
    CUSTOMER_ID,
    ORDER_ID,
    LOAD_DATETIME,
    EFFECTIVE_FROM,
    START_DATE,
    END_DATE,
    RECORD_SOURCE,
    CAST(UPPER(MD5(NULLIF(CONCAT(
        IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(16)))), ''), '^^'), '||',
        IFNULL(NULLIF(UPPER(TRIM(CAST(ORDER_ID AS VARCHAR(16)))), ''), '^^')
    ), '^^||^^'))) AS STRING) AS TRANSACTION_HK,
    CAST(UPPER(MD5(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(16)))), ''))) AS STRING) AS CUSTOMER_HK,
    CAST(UPPER(MD5(NULLIF(UPPER(TRIM(CAST(ORDER_ID AS VARCHAR(16)))), ''))) AS STRING) AS ORDER_HK
    FROM derived_columns
),
columns_to_select AS (
    SELECT
    o_orderkey,
    o_custkey,
    o_orderstatus,
    o_totalprice,
    o_orderdate,
    o_orderpriority,
    o_clerk,
    o_shippriority,
    o_comment,
    CUSTOMER_ID,
    ORDER_ID,
    LOAD_DATETIME,
    EFFECTIVE_FROM,
    START_DATE,
    END_DATE,
    RECORD_SOURCE,
    TRANSACTION_HK,
    CUSTOMER_HK,
    ORDER_HK
    FROM hashed_columns
)
SELECT * FROM columns_to_select