WITH source_data AS (
    SELECT a.CUSTOMER_HK, a.HASHDIFF, a.CUSTOMER_NAME, a.CUSTOMER_ADDRESS, a.CUSTOMER_PHONE, a.ACCBAL, a.MKTSEGMENT, a.COMMENT, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM "DBTVAULT_DEV"."TEST"."stg_customer" AS a
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
        FROM "DBTVAULT_DEV"."TEST"."satellite_ghost_incremental" AS current_records
            JOIN (
                SELECT DISTINCT source_data.CUSTOMER_HK
                FROM source_data
            ) AS source_records
                ON current_records.CUSTOMER_HK = source_records.CUSTOMER_HK
    ) AS a
    WHERE a.rank = 1
),
ghost AS (
    SELECT
    CAST(NULL AS varchar) AS CUSTOMER_NAME,
    CAST(NULL AS varchar) AS CUSTOMER_PHONE,
    CAST(NULL AS varchar) AS CUSTOMER_ADDRESS,
    CAST(NULL AS float) AS ACCBAL,
    CAST(NULL AS varchar) AS MKTSEGMENT,
    CAST(NULL AS varchar) AS COMMENT,
    CONVERT(DATETIME2, '1900-01-01 00:00:00') AS LOAD_DATETIME,
    CONVERT(DATETIME2, '1900-01-01 00:00:00') AS EFFECTIVE_FROM,
    CAST('AUTOMATE_DV_SYSTEM' AS varchar) AS RECORD_SOURCE,
    CAST(REPLICATE(CAST(CAST('0' AS tinyint) AS BINARY(16)), 16) AS BINARY(16)) AS CUSTOMER_HK,
    CAST(REPLICATE(CAST(CAST('0' AS tinyint) AS BINARY(16)), 16) AS BINARY(16)) AS HASHDIFF
),

records_to_insert AS (
    SELECT
        g.CUSTOMER_HK, g.HASHDIFF, g.CUSTOMER_NAME, g.CUSTOMER_ADDRESS, g.CUSTOMER_PHONE, g.ACCBAL, g.MKTSEGMENT, g.COMMENT, g.EFFECTIVE_FROM, g.LOAD_DATETIME, g.RECORD_SOURCE
        FROM ghost AS g
        WHERE NOT EXISTS ( SELECT 1 FROM "DBTVAULT_DEV"."TEST"."satellite_ghost_incremental" AS h WHERE h.HASHDIFF = g.HASHDIFF )
    UNION
    SELECT DISTINCT stage.CUSTOMER_HK, stage.HASHDIFF, stage.CUSTOMER_NAME, stage.CUSTOMER_ADDRESS, stage.CUSTOMER_PHONE, stage.ACCBAL, stage.MKTSEGMENT, stage.COMMENT, stage.EFFECTIVE_FROM, stage.LOAD_DATETIME, stage.RECORD_SOURCE
    FROM source_data AS stage
    LEFT JOIN latest_records
    ON latest_records.CUSTOMER_HK = stage.CUSTOMER_HK
        AND latest_records.HASHDIFF = stage.HASHDIFF
    WHERE latest_records.HASHDIFF IS NULL
)

SELECT * FROM records_to_insert