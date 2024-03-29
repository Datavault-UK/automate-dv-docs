WITH row_rank_1 AS (
    SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATETIME, RECORD_SOURCE
    FROM (
        SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATETIME, rr.RECORD_SOURCE,
               ROW_NUMBER() OVER(
                   PARTITION BY rr.CUSTOMER_HK
                   ORDER BY rr.LOAD_DATETIME
               ) AS row_number
        FROM "AUTOMATE_DV_TEST"."TEST"."stg_customer" AS rr
        WHERE rr.CUSTOMER_HK IS NOT NULL
    ) h
    WHERE h.row_number = 1
),
row_rank_2 AS (
    SELECT CUSTOMER_HK, CUSTOMER_ID, LOAD_DATETIME, RECORD_SOURCE
    FROM (
        SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATETIME, rr.RECORD_SOURCE,
               ROW_NUMBER() OVER(
                   PARTITION BY rr.CUSTOMER_HK
                   ORDER BY rr.LOAD_DATETIME
               ) AS row_number
        FROM "AUTOMATE_DV_TEST"."TEST"."stg_orders" AS rr
        WHERE rr.CUSTOMER_HK IS NOT NULL
    ) h
    WHERE h.row_number = 1
),
stage_union AS (
    SELECT * FROM row_rank_1
    UNION ALL
    SELECT * FROM row_rank_2
),
row_rank_union AS (
    SELECT *
    FROM (
        SELECT ru.*,
               ROW_NUMBER() OVER(
                   PARTITION BY ru.CUSTOMER_HK
                   ORDER BY ru.LOAD_DATETIME, ru.RECORD_SOURCE ASC
               ) AS row_rank_number
        FROM stage_union AS ru
        WHERE ru.CUSTOMER_HK IS NOT NULL
    ) h
    WHERE h.row_rank_number = 1
),
records_to_insert AS (
    SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM row_rank_union AS a
    LEFT JOIN "AUTOMATE_DV_TEST"."TEST"."hub_orders_multi_source_incremental" AS d
    ON a.CUSTOMER_HK = d.CUSTOMER_HK
    WHERE d.CUSTOMER_HK IS NULL
)
SELECT * FROM records_to_insert