WITH source_data AS (
    SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_ADDRESS, a.CUSTOMER_PHONE, a.ACCBAL, a.MKTSEGMENT, a.COMMENT, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM ALEX_HIGGS.AUTOMATE_DV_DOCS_SAMPLES.stg_customer AS a
    WHERE a.CUSTOMER_HK IS NOT NULL
),
records_to_insert AS (
    SELECT DISTINCT stage.CUSTOMER_HK, stage.HASHDIFF, stage.CUSTOMER_NAME, stage.CUSTOMER_ADDRESS, stage.CUSTOMER_PHONE, stage.ACCBAL, stage.MKTSEGMENT, stage.COMMENT, stage.EFFECTIVE_FROM, stage.LOAD_DATETIME, stage.RECORD_SOURCE
    FROM source_data AS stage
)
SELECT * FROM records_to_insert