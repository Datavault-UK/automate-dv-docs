WITH stage AS (
    SELECT TRANSACTION_HK, CUSTOMER_HK, ORDER_HK, o_orderdate, o_orderpriority, o_clerk, o_shippriority, o_comment, o_totalprice, o_orderstatus, EFFECTIVE_FROM, LOAD_DATETIME, RECORD_SOURCE
    FROM `dbtvault`.`stg_transactions`
    WHERE TRANSACTION_HK IS NOT NULL
    AND CUSTOMER_HK IS NOT NULL
    AND ORDER_HK IS NOT NULL
),
records_to_insert AS (
    SELECT DISTINCT stg.TRANSACTION_HK, stg.CUSTOMER_HK, stg.ORDER_HK, stg.o_orderdate, stg.o_orderpriority, stg.o_clerk, stg.o_shippriority, stg.o_comment, stg.o_totalprice, stg.o_orderstatus, stg.EFFECTIVE_FROM, stg.LOAD_DATETIME, stg.RECORD_SOURCE
    FROM stage AS stg
)
SELECT * FROM records_to_insert