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
    FROM "dbtvault_db"."development"."ORDERS"
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
    '1998-07-01' AS LOAD_DATETIME,
    '1998-01-01' AS EFFECTIVE_FROM,
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
    RECORD_SOURCE,
    DECODE(MD5(NULLIF(CONCAT(
        COALESCE(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'), '||',
        COALESCE(NULLIF(UPPER(TRIM(CAST(ORDER_ID AS VARCHAR))), ''), '^^')
    ), '^^||^^')), 'hex') AS TRANSACTION_HK,
    DECODE(MD5(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), '')), 'hex') AS CUSTOMER_HK,
    DECODE(MD5(NULLIF(UPPER(TRIM(CAST(ORDER_ID AS VARCHAR))), '')), 'hex') AS ORDER_HK
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
    RECORD_SOURCE,
    TRANSACTION_HK,
    CUSTOMER_HK,
    ORDER_HK
    FROM hashed_columns
)
SELECT * FROM columns_to_select