    WITH source_data AS (
    SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_ADDRESS, a.CUSTOMER_PHONE, a.ACCBAL, a.MKTSEGMENT, a.COMMENT, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM "dbtvault_db"."development"."stg_customer" AS a
    WHERE a.CUSTOMER_HK IS NOT NULL
),
latest_records AS (
    SELECT a.CUSTOMER_HK, a.HASHDIFF, a.LOAD_DATETIME
    FROM (
        SELECT current_records.CUSTOMER_HK, current_records.HASHDIFF, current_records.LOAD_DATETIME,
            RANK() OVER (
                PARTITION BY current_records.CUSTOMER_HK
                ORDER BY current_records.LOAD_DATETIME DESC
            ) AS rank
        FROM "dbtvault_db"."development"."satellite_ghost_incremental" AS current_records
            JOIN (
                SELECT DISTINCT source_data.CUSTOMER_HK
                FROM source_data
            ) AS source_records
                ON current_records.CUSTOMER_HK = source_records.CUSTOMER_HK
    ) AS a
    WHERE a.rank = 1
),
ghost AS (SELECT
    CAST(NULL AS text) AS customer_name,
    CAST(NULL AS text) AS customer_phone,
    CAST(NULL AS text) AS customer_address,
    CAST(NULL AS double precision) AS accbal,
    CAST(NULL AS text) AS mktsegment,
    CAST(NULL AS text) AS comment,
    to_char(timestamp '1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS.MS')::timestamp AS load_datetime,
    to_char(timestamp '1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS.MS')::timestamp AS effective_from,
    CAST('AUTOMATE_DV_SYSTEM' AS text) AS RECORD_SOURCE,
    CAST('00000000000000000000000000000000' AS BYTEA) AS customer_hk,
    CAST('00000000000000000000000000000000' AS BYTEA) AS hashdiff
),
records_to_insert AS (SELECT
        g.CUSTOMER_HK, g.HASHDIFF, g.CUSTOMER_NAME, g.CUSTOMER_ADDRESS, g.CUSTOMER_PHONE, g.ACCBAL, g.MKTSEGMENT, g.COMMENT, g.EFFECTIVE_FROM, g.LOAD_DATETIME, g.RECORD_SOURCE
        FROM ghost AS g
        WHERE NOT EXISTS ( SELECT 1 FROM "dbtvault_db"."development"."satellite_ghost_incremental" AS h WHERE h.HASHDIFF = g.HASHDIFF )
    UNION
    SELECT DISTINCT stage.CUSTOMER_HK, stage.HASHDIFF, stage.CUSTOMER_NAME, stage.CUSTOMER_ADDRESS, stage.CUSTOMER_PHONE, stage.ACCBAL, stage.MKTSEGMENT, stage.COMMENT, stage.EFFECTIVE_FROM, stage.LOAD_DATETIME, stage.RECORD_SOURCE
    FROM source_data AS stage
    LEFT JOIN latest_records
    ON latest_records.CUSTOMER_HK = stage.CUSTOMER_HK
        AND latest_records.HASHDIFF = stage.HASHDIFF
    WHERE latest_records.HASHDIFF IS NULL
)
SELECT * FROM records_to_insert