WITH row_rank_1 AS (
    SELECT rr.CUSTOMER_HK, rr.CUSTOMER_ID, rr.LOAD_DATETIME, rr.RECORD_SOURCE,
           ROW_NUMBER() OVER(
               PARTITION BY rr.CUSTOMER_HK
               ORDER BY rr.LOAD_DATETIME
           ) AS row_number
    FROM `dbtvault`.`stg_customer` AS rr
    WHERE rr.CUSTOMER_HK IS NOT NULL
    AND rr.CUSTOMER_ID IS NOT NULL
    QUALIFY row_number = 1
),
records_to_insert AS (
    SELECT a.CUSTOMER_HK, a.CUSTOMER_ID, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM row_rank_1 AS a
)
SELECT * FROM records_to_insert