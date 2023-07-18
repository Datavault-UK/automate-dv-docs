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
    FROM "DBTVAULT_DEV"."TEST"."CUSTOMER"
),
ranked_columns AS (
    SELECT *,
    RANK() OVER (PARTITION BY C_CUSTKEY ORDER BY C_NATIONKEY) AS AUTOMATE_DV_RANK
    FROM source_data
),
columns_to_select AS (
    SELECT
    AUTOMATE_DV_RANK
    FROM ranked_columns
)
SELECT * FROM columns_to_select