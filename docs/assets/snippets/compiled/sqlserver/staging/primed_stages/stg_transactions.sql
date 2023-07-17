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
    FROM "AUTOMATE_DV_TEST"."TEST"."ORDERS"
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
    CONVERT(BINARY(16), HASHBYTES('MD5', NULLIF(CONCAT(
        ISNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(MAX)))), ''), '^^'), '||',
        ISNULL(NULLIF(UPPER(TRIM(CAST(ORDER_ID AS VARCHAR(MAX)))), ''), '^^')
    ), '^^||^^')), 2) AS TRANSACTION_HK,
    CONVERT(BINARY(16), HASHBYTES('MD5', NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR(MAX)))), '')), 2) AS CUSTOMER_HK,
    CONVERT(BINARY(16), HASHBYTES('MD5', NULLIF(UPPER(TRIM(CAST(ORDER_ID AS VARCHAR(MAX)))), '')), 2) AS ORDER_HK
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