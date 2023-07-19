WITH row_rank_1 AS (
    SELECT DISTINCT ON (rr.CUSTOMER_HK) rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATETIME, rr.RECORD_SOURCE
    FROM "dbtvault_db"."development"."stg_customer" AS rr
    WHERE rr.CUSTOMER_HK IS NOT NULL
    ORDER BY rr.CUSTOMER_HK, rr.LOAD_DATETIME
),
records_to_insert AS (
    SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM row_rank_1 AS a
    LEFT JOIN "dbtvault_db"."development"."hub_customer_incremental" AS d
    ON a.CUSTOMER_HK = d.CUSTOMER_HK
    WHERE d.CUSTOMER_HK IS NULL
)
SELECT * FROM records_to_insert