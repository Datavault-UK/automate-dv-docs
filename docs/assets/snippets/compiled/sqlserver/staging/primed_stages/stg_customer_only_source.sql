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
    FROM "AUTOMATE_DV_TEST"."TEST"."CUSTOMER"
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
    c_comment
    FROM source_data
)
SELECT * FROM columns_to_select