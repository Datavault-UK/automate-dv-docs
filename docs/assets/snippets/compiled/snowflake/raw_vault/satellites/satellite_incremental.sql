WITH source_data AS (
    SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_ADDRESS, a.CUSTOMER_PHONE, a.ACCBAL, a.MKTSEGMENT, a.COMMENT, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM ALEX_HIGGS.AUTOMATE_DV_DOCS_SAMPLES.stg_customer AS a
    WHERE a.CUSTOMER_HK IS NOT NULL
),
latest_records AS (
    SELECT current_records.CUSTOMER_HK, current_records.HASHDIFF, current_records.CUSTOMER_NAME, current_records.CUSTOMER_ADDRESS, current_records.CUSTOMER_PHONE, current_records.ACCBAL, current_records.MKTSEGMENT, current_records.COMMENT, current_records.EFFECTIVE_FROM, current_records.LOAD_DATETIME, current_records.RECORD_SOURCE,
        RANK() OVER (
           PARTITION BY current_records.CUSTOMER_HK
           ORDER BY current_records.LOAD_DATETIME DESC
        ) AS rank_num
    FROM ALEX_HIGGS.AUTOMATE_DV_DOCS_SAMPLES.satellite_incremental AS current_records
        JOIN (
            SELECT DISTINCT source_data.CUSTOMER_HK
            FROM source_data
        ) AS source_records
            ON source_records.CUSTOMER_HK = current_records.CUSTOMER_HK
    QUALIFY rank_num = 1
),
first_record_in_set AS (
    SELECT
    sd.CUSTOMER_HK, sd.HASHDIFF, sd.CUSTOMER_NAME, sd.CUSTOMER_ADDRESS, sd.CUSTOMER_PHONE, sd.ACCBAL, sd.MKTSEGMENT, sd.COMMENT, sd.EFFECTIVE_FROM, sd.LOAD_DATETIME, sd.RECORD_SOURCE,
    RANK() OVER (
            PARTITION BY sd.CUSTOMER_HK
            ORDER BY sd.LOAD_DATETIME ASC
        ) as asc_rank
    FROM source_data as sd
    QUALIFY asc_rank = 1
),
unique_source_records AS (
    SELECT DISTINCT
        sd.CUSTOMER_HK, sd.HASHDIFF, sd.CUSTOMER_NAME, sd.CUSTOMER_ADDRESS, sd.CUSTOMER_PHONE, sd.ACCBAL, sd.MKTSEGMENT, sd.COMMENT, sd.EFFECTIVE_FROM, sd.LOAD_DATETIME, sd.RECORD_SOURCE
    FROM source_data as sd
    QUALIFY sd.HASHDIFF != LAG(sd.HASHDIFF) OVER (
        PARTITION BY sd.CUSTOMER_HK
        ORDER BY sd.LOAD_DATETIME ASC)
),
records_to_insert AS (
    SELECT frin.CUSTOMER_HK, frin.HASHDIFF, frin.CUSTOMER_NAME, frin.CUSTOMER_ADDRESS, frin.CUSTOMER_PHONE, frin.ACCBAL, frin.MKTSEGMENT, frin.COMMENT, frin.EFFECTIVE_FROM, frin.LOAD_DATETIME, frin.RECORD_SOURCE
    FROM first_record_in_set AS frin
    LEFT JOIN LATEST_RECORDS lr
        ON lr.CUSTOMER_HK = frin.CUSTOMER_HK
        AND lr.HASHDIFF = frin.HASHDIFF
        WHERE lr.HASHDIFF IS NULL
    UNION
    SELECT usr.CUSTOMER_HK, usr.HASHDIFF, usr.CUSTOMER_NAME, usr.CUSTOMER_ADDRESS, usr.CUSTOMER_PHONE, usr.ACCBAL, usr.MKTSEGMENT, usr.COMMENT, usr.EFFECTIVE_FROM, usr.LOAD_DATETIME, usr.RECORD_SOURCE
    FROM unique_source_records as usr
)
SELECT * FROM records_to_insert