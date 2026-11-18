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
    LOAD_DATETIME,
    EFFECTIVE_FROM,
    START_DATE,
    END_DATE,
    RECORD_SOURCE,
    DECODE(MD5(NULLIF(UPPER(TRIM(CAST(o_custkey AS VARCHAR))), '')), 'hex') AS CUSTOMER_HK
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
    LOAD_DATETIME,
    EFFECTIVE_FROM,
    START_DATE,
    END_DATE,
    RECORD_SOURCE,
    CUSTOMER_HK
    FROM hashed_columns
)
SELECT * FROM columns_to_select