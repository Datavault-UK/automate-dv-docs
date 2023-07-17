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
columns_to_select AS (
    SELECT
    C_CUSTKEY,
    C_NAME,
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT
    FROM source_data
)
SELECT * FROM columns_to_select