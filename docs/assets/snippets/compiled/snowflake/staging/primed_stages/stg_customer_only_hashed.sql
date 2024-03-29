WITH source_data AS (
    SELECT
    C_CUSTKEY,
    C_NAME,
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT
    FROM ALEX_HIGGS.AUTOMATE_DV_DOCS_SAMPLES.CUSTOMER
),
hashed_columns AS (
    SELECT
    C_CUSTKEY,
    C_NAME,
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT,
    CAST(MD5_BINARY(NULLIF(UPPER(TRIM(CAST(C_CUSTKEY AS VARCHAR))), '')) AS BINARY(16)) AS CUSTOMER_HK
    FROM source_data
),
columns_to_select AS (
    SELECT
    C_CUSTKEY,
    C_NAME,
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT,
    CUSTOMER_HK
    FROM hashed_columns
)
SELECT * FROM columns_to_select