WITH row_rank_1 AS (
    SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATETIME, RECORD_SOURCE
    FROM (
        SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATETIME, rr.RECORD_SOURCE,
               ROW_NUMBER() OVER(
                   PARTITION BY rr.CUSTOMER_HK
                   ORDER BY rr.LOAD_DATETIME
               ) AS row_number
        FROM "DBTVAULT_DEV"."TEST"."stg_customer" AS rr
        WHERE rr.CUSTOMER_HK IS NOT NULL
    ) h
    WHERE h.row_number = 1
),
records_to_insert AS (
    SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM row_rank_1 AS a
    LEFT JOIN "DBTVAULT_DEV"."TEST"."hub_customer_incremental" AS d
    ON a.CUSTOMER_HK = d.CUSTOMER_HK
    WHERE d.CUSTOMER_HK IS NULL
)
SELECT * FROM records_to_insert