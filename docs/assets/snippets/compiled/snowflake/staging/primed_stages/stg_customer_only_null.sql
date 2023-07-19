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
null_columns AS (
    SELECT
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT,
    C_CUSTKEY AS C_CUSTKEY_ORIGINAL,
        IFNULL(C_CUSTKEY, '-1') AS C_CUSTKEY,
    C_NAME AS C_NAME_ORIGINAL,
        IFNULL(C_NAME, '-2') AS C_NAME
    FROM source_data
),
columns_to_select AS (
    SELECT
    C_ADDRESS,
    C_NATIONKEY,
    C_PHONE,
    C_ACCTBAL,
    C_MKTSEGMENT,
    C_COMMENT,
    C_CUSTKEY,
    C_CUSTKEY_ORIGINAL,
    C_NAME,
    C_NAME_ORIGINAL
    FROM null_columns
)
SELECT * FROM columns_to_select