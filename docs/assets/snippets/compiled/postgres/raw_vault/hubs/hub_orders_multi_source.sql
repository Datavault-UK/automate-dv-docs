WITH row_rank_1 AS (
    SELECT DISTINCT ON (rr.CUSTOMER_HK) rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATETIME, rr.RECORD_SOURCE
    FROM "dbtvault_db"."development"."stg_customer" AS rr
    WHERE rr.CUSTOMER_HK IS NOT NULL
    ORDER BY rr.CUSTOMER_HK, rr.LOAD_DATETIME
),
row_rank_2 AS (
    SELECT DISTINCT ON (rr.CUSTOMER_HK) rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATETIME, rr.RECORD_SOURCE
    FROM "dbtvault_db"."development"."stg_orders" AS rr
    WHERE rr.CUSTOMER_HK IS NOT NULL
    ORDER BY rr.CUSTOMER_HK, rr.LOAD_DATETIME
),
stage_union AS (
    SELECT * FROM row_rank_1
    UNION ALL
    SELECT * FROM row_rank_2
),
row_rank_union AS (SELECT DISTINCT ON (ru.CUSTOMER_HK) ru.*
    FROM stage_union AS ru
    WHERE ru.CUSTOMER_HK IS NOT NULL
    ORDER BY ru.CUSTOMER_HK, ru.LOAD_DATETIME, ru.RECORD_SOURCE ASC
),
records_to_insert AS (
    SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM row_rank_union AS a
)
SELECT * FROM records_to_insert