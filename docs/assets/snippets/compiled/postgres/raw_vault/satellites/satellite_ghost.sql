WITH source_data AS (
    SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_ADDRESS, a.CUSTOMER_PHONE, a.ACCBAL, a.MKTSEGMENT, a.COMMENT, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM "dbtvault_db"."development"."stg_customer" AS a
    WHERE a.CUSTOMER_HK IS NOT NULL
),
first_record_in_set AS (
    SELECT * FROM (
        SELECT
        sd.CUSTOMER_HK, sd.HASHDIFF, sd.CUSTOMER_NAME, sd.CUSTOMER_ADDRESS, sd.CUSTOMER_PHONE, sd.ACCBAL, sd.MKTSEGMENT, sd.COMMENT, sd.EFFECTIVE_FROM, sd.LOAD_DATETIME, sd.RECORD_SOURCE,
        RANK() OVER (
                PARTITION BY sd.CUSTOMER_HK
                ORDER BY sd.LOAD_DATETIME ASC
            ) as asc_rank
        FROM source_data as sd ) rin
    WHERE rin.asc_rank = 1
),
unique_source_records AS (
    SELECT
        b.CUSTOMER_HK, b.HASHDIFF, b.CUSTOMER_NAME, b.CUSTOMER_ADDRESS, b.CUSTOMER_PHONE, b.ACCBAL, b.MKTSEGMENT, b.COMMENT, b.EFFECTIVE_FROM, b.LOAD_DATETIME, b.RECORD_SOURCE
    FROM (
        SELECT DISTINCT
            sd.CUSTOMER_HK, sd.HASHDIFF, sd.CUSTOMER_NAME, sd.CUSTOMER_ADDRESS, sd.CUSTOMER_PHONE, sd.ACCBAL, sd.MKTSEGMENT, sd.COMMENT, sd.EFFECTIVE_FROM, sd.LOAD_DATETIME, sd.RECORD_SOURCE,
            LAG(sd.HASHDIFF) OVER (
                PARTITION BY sd.CUSTOMER_HK
                ORDER BY sd.LOAD_DATETIME ASC) as prev_hashdiff
        FROM source_data as sd
        ) b
    WHERE b.HASHDIFF != b.prev_hashdiff
),
ghost AS (
    SELECT
    CAST(NULL AS text) AS customer_name,
    CAST(NULL AS text) AS customer_phone,
    CAST(NULL AS text) AS customer_address,
    CAST(NULL AS double precision) AS accbal,
    CAST(NULL AS text) AS mktsegment,
    CAST(NULL AS text) AS comment,
    TO_DATE('1900-01-01', 'YYY-MM-DD') AS load_datetime,
    TO_DATE('1900-01-01', 'YYY-MM-DD') AS effective_from,
    CAST('AUTOMATE_DV_SYSTEM' AS text) AS RECORD_SOURCE,
    CAST('00000000000000000000000000000000' AS BYTEA) AS customer_hk,
    CAST('00000000000000000000000000000000' AS BYTEA) AS hashdiff
),
records_to_insert AS (
    SELECT
        g.CUSTOMER_HK, g.HASHDIFF, g.CUSTOMER_NAME, g.CUSTOMER_ADDRESS, g.CUSTOMER_PHONE, g.ACCBAL, g.MKTSEGMENT, g.COMMENT, g.EFFECTIVE_FROM, g.LOAD_DATETIME, g.RECORD_SOURCE
        FROM ghost AS g
    UNION
        SELECT frin.CUSTOMER_HK, frin.HASHDIFF, frin.CUSTOMER_NAME, frin.CUSTOMER_ADDRESS, frin.CUSTOMER_PHONE, frin.ACCBAL, frin.MKTSEGMENT, frin.COMMENT, frin.EFFECTIVE_FROM, frin.LOAD_DATETIME, frin.RECORD_SOURCE
        FROM first_record_in_set AS frin
        UNION
        SELECT usr.CUSTOMER_HK, usr.HASHDIFF, usr.CUSTOMER_NAME, usr.CUSTOMER_ADDRESS, usr.CUSTOMER_PHONE, usr.ACCBAL, usr.MKTSEGMENT, usr.COMMENT, usr.EFFECTIVE_FROM, usr.LOAD_DATETIME, usr.RECORD_SOURCE
        FROM unique_source_records as usr
)
SELECT * FROM records_to_insert