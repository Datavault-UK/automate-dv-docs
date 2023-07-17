WITH source_data AS (
    SELECT a.CUSTOMER_ORDER_HK, a.CUSTOMER_HK, a.ORDER_HK, a.START_DATE, a.END_DATE, a.EFFECTIVE_FROM, a.LOAD_DATETIME, a.RECORD_SOURCE
    FROM `hive_metastore`.`dbtvault`.`stg_customer` AS a
    WHERE a.CUSTOMER_HK IS NOT NULL
    AND a.ORDER_HK IS NOT NULL
),
latest_records AS (
    SELECT * FROM (
        SELECT b.CUSTOMER_ORDER_HK, b.CUSTOMER_HK, b.ORDER_HK, b.START_DATE, b.END_DATE, b.EFFECTIVE_FROM, b.LOAD_DATETIME, b.RECORD_SOURCE,
               ROW_NUMBER() OVER (
                    PARTITION BY b.CUSTOMER_ORDER_HK
                    ORDER BY b.LOAD_DATETIME DESC
               ) AS row_num
        FROM `hive_metastore`.`dbtvault`.`eff_sat_customer_phone_incremental` AS b
    )AS inner_rank
        WHERE row_num = 1),
latest_open AS (
    SELECT c.CUSTOMER_ORDER_HK, c.CUSTOMER_HK, c.ORDER_HK, c.START_DATE, c.END_DATE, c.EFFECTIVE_FROM, c.LOAD_DATETIME, c.RECORD_SOURCE
    FROM latest_records AS c
    WHERE TO_DATE(c.END_DATE) = TO_DATE(TO_TIMESTAMP('9999-12-31 23:59:59.999999'))
),
latest_closed AS (
    SELECT d.CUSTOMER_ORDER_HK, d.CUSTOMER_HK, d.ORDER_HK, d.START_DATE, d.END_DATE, d.EFFECTIVE_FROM, d.LOAD_DATETIME, d.RECORD_SOURCE
    FROM latest_records AS d
    WHERE TO_DATE(d.END_DATE) != TO_DATE(TO_TIMESTAMP('9999-12-31 23:59:59.999999'))
),
new_open_records AS (
    SELECT DISTINCT
        f.CUSTOMER_ORDER_HK,
        f.CUSTOMER_HK, f.ORDER_HK,
        f.START_DATE AS START_DATE,
        f.END_DATE AS END_DATE,
        f.EFFECTIVE_FROM AS EFFECTIVE_FROM,
        f.LOAD_DATETIME,
        f.RECORD_SOURCE
    FROM source_data AS f
    LEFT JOIN latest_records AS lr
    ON f.CUSTOMER_ORDER_HK = lr.CUSTOMER_ORDER_HK
    WHERE lr.CUSTOMER_ORDER_HK IS NULL
),
new_reopened_records AS (
    SELECT DISTINCT
        lc.CUSTOMER_ORDER_HK,
        lc.CUSTOMER_HK, lc.ORDER_HK,
        g.START_DATE AS START_DATE,
        g.END_DATE AS END_DATE,
        g.EFFECTIVE_FROM AS EFFECTIVE_FROM,
        g.LOAD_DATETIME,
        g.RECORD_SOURCE
    FROM source_data AS g
    INNER JOIN latest_closed AS lc
    ON g.CUSTOMER_ORDER_HK = lc.CUSTOMER_ORDER_HK
    WHERE TO_DATE(g.END_DATE) = TO_DATE(TO_TIMESTAMP('9999-12-31 23:59:59.999999'))
),
new_closed_records AS (
    SELECT DISTINCT
        lo.CUSTOMER_ORDER_HK,
        lo.CUSTOMER_HK, lo.ORDER_HK,
        h.START_DATE AS START_DATE,
        h.END_DATE AS END_DATE,
        h.EFFECTIVE_FROM AS EFFECTIVE_FROM,
        h.LOAD_DATETIME,
        lo.RECORD_SOURCE
    FROM source_data AS h
    LEFT JOIN latest_open AS lo
    ON lo.CUSTOMER_ORDER_HK = h.CUSTOMER_ORDER_HK
    LEFT JOIN latest_closed AS lc
    ON lc.CUSTOMER_ORDER_HK = h.CUSTOMER_ORDER_HK
    WHERE TO_DATE(h.END_DATE) != TO_DATE(TO_TIMESTAMP('9999-12-31 23:59:59.999999'))
    AND lo.CUSTOMER_ORDER_HK IS NOT NULL
    AND lc.CUSTOMER_ORDER_HK IS NULL
),
records_to_insert AS (
    SELECT * FROM new_open_records
    UNION
    SELECT * FROM new_reopened_records
    UNION
    SELECT * FROM new_closed_records
)
SELECT * FROM records_to_insert