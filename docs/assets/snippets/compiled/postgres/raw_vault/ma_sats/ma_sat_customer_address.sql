    WITH source_data AS (
    SELECT DISTINCT s.CUSTOMER_HK, s.HASHDIFF, s.CUSTOMER_PHONE, s.CUSTOMER_PHONE_LOCATOR_ID, s.CUSTOMER_NAME, s.EFFECTIVE_FROM, s.LOAD_DATETIME, s.RECORD_SOURCE
    FROM "dbtvault_db"."development"."stg_customer" AS s
    WHERE s.CUSTOMER_HK IS NOT NULL
        AND s.CUSTOMER_PHONE IS NOT NULL
        AND s.CUSTOMER_PHONE_LOCATOR_ID IS NOT NULL
),
records_to_insert AS (
SELECT source_data.CUSTOMER_HK, source_data.HASHDIFF, source_data.CUSTOMER_PHONE, source_data.CUSTOMER_PHONE_LOCATOR_ID, source_data.CUSTOMER_NAME, source_data.EFFECTIVE_FROM, source_data.LOAD_DATETIME, source_data.RECORD_SOURCE
    FROM source_data
)
SELECT * FROM records_to_insert