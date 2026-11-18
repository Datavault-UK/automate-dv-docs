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