    WITH source_data AS (
    SELECT DISTINCT s.CUSTOMER_HK, s.HASHDIFF, s.CUSTOMER_PHONE, s.CUSTOMER_PHONE_LOCATOR_ID, s.CUSTOMER_NAME, s.EFFECTIVE_FROM, s.LOAD_DATETIME, s.RECORD_SOURCE
    FROM "dbtvault_db"."development"."stg_customer" AS s
    WHERE s.CUSTOMER_HK IS NOT NULL
        AND s.CUSTOMER_PHONE IS NOT NULL
        AND s.CUSTOMER_PHONE_LOCATOR_ID IS NOT NULL
),
source_data_with_count AS (
    SELECT a.*,
           b.source_count
    FROM source_data a
    INNER JOIN
    (
        SELECT t.CUSTOMER_HK,
               COUNT(*) AS source_count
        FROM (
            SELECT DISTINCT s.CUSTOMER_HK,
                            s.HASHDIFF,
                            s.CUSTOMER_PHONE, s.CUSTOMER_PHONE_LOCATOR_ID
            FROM source_data AS s
        ) AS t
        GROUP BY t.CUSTOMER_HK
    ) AS b
    ON a.CUSTOMER_HK = b.CUSTOMER_HK
),
latest_records AS (
    SELECT mas.CUSTOMER_HK, mas.HASHDIFF, mas.CUSTOMER_PHONE, mas.CUSTOMER_PHONE_LOCATOR_ID, mas.LOAD_DATETIME,
           mas.latest_rank,
           DENSE_RANK() OVER (PARTITION BY mas.CUSTOMER_HK
                              ORDER BY mas.HASHDIFF, mas.CUSTOMER_PHONE, mas.CUSTOMER_PHONE_LOCATOR_ID ASC
           ) AS check_rank
    FROM (
    SELECT inner_mas.CUSTOMER_HK, inner_mas.HASHDIFF, inner_mas.CUSTOMER_PHONE, inner_mas.CUSTOMER_PHONE_LOCATOR_ID, inner_mas.LOAD_DATETIME,
           RANK() OVER (PARTITION BY inner_mas.CUSTOMER_HK
                        ORDER BY inner_mas.LOAD_DATETIME DESC
           ) AS latest_rank
    FROM "dbtvault_db"."development"."ma_sat_customer_address_incremental" AS inner_mas
    INNER JOIN (SELECT DISTINCT s.CUSTOMER_HK FROM source_data as s ) AS spk
        ON inner_mas.CUSTOMER_HK = spk.CUSTOMER_HK
    ) AS mas
    WHERE latest_rank = 1
    ),
latest_group_details AS (
    SELECT lr.CUSTOMER_HK,
           lr.LOAD_DATETIME,
           MAX(lr.check_rank) AS latest_count
    FROM latest_records AS lr
    GROUP BY lr.CUSTOMER_HK, lr.LOAD_DATETIME
),
records_to_insert AS (
    SELECT source_data_with_count.CUSTOMER_HK, source_data_with_count.HASHDIFF, source_data_with_count.CUSTOMER_PHONE, source_data_with_count.CUSTOMER_PHONE_LOCATOR_ID, source_data_with_count.CUSTOMER_NAME, source_data_with_count.EFFECTIVE_FROM, source_data_with_count.LOAD_DATETIME, source_data_with_count.RECORD_SOURCE
    FROM source_data_with_count
    WHERE EXISTS (
        SELECT 1
        FROM source_data_with_count AS stage
        WHERE NOT EXISTS (
            SELECT 1
            FROM (
                SELECT lr.CUSTOMER_HK, lr.HASHDIFF, lr.CUSTOMER_PHONE, lr.CUSTOMER_PHONE_LOCATOR_ID, lr.LOAD_DATETIME,
                lg.latest_count
                FROM latest_records AS lr
                INNER JOIN latest_group_details AS lg
                    ON lr.CUSTOMER_HK = lg.CUSTOMER_HK
                    AND lr.LOAD_DATETIME = lg.LOAD_DATETIME
            ) AS active_records
            WHERE stage.CUSTOMER_HK = active_records.CUSTOMER_HK
                AND stage.HASHDIFF = active_records.HASHDIFF
                AND stage.CUSTOMER_PHONE = active_records.CUSTOMER_PHONE AND stage.CUSTOMER_PHONE_LOCATOR_ID = active_records.CUSTOMER_PHONE_LOCATOR_ID
                AND stage.source_count = active_records.latest_count
        )
        AND source_data_with_count.CUSTOMER_HK = stage.CUSTOMER_HK
    )
)
SELECT * FROM records_to_insert