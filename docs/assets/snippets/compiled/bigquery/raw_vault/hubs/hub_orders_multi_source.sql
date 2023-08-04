WITH row_rank_1 AS (
    SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATETIME, rr.RECORD_SOURCE,
           ROW_NUMBER() OVER(
               PARTITION BY rr.CUSTOMER_HK
               ORDER BY rr.LOAD_DATETIME
           ) AS row_number
    FROM `dbtvault-341416`.`dbtvault`.`stg_customer` AS rr
    WHERE rr.CUSTOMER_HK IS NOT NULL
    QUALIFY row_number = 1
),
row_rank_2 AS (
    SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATETIME, rr.RECORD_SOURCE,
           ROW_NUMBER() OVER(
               PARTITION BY rr.CUSTOMER_HK
               ORDER BY rr.LOAD_DATETIME
           ) AS row_number
    FROM `dbtvault-341416`.`dbtvault`.`stg_orders` AS rr
    WHERE rr.CUSTOMER_HK IS NOT NULL
    QUALIFY row_number = 1
),
stage_union AS (
    SELECT * FROM row_rank_1
    UNION ALL
    SELECT * FROM row_rank_2
),
    row_rank_union AS (
    SELECT ru.*,
           ROW_NUMBER() OVER(
               PARTITION BY ru.CUSTOMER_HK
               ORDER BY ru.LOAD_DATETIME, ru.RECORD_SOURCE ASC
           ) AS row_rank_number
    FROM stage_union AS ru
    WHERE ru.CUSTOMER_HK IS NOT NULL
    QUALIFY row_rank_number = 1
),
records_to_insert AS (
    SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM row_rank_union AS a
)
SELECT * FROM records_to_insert