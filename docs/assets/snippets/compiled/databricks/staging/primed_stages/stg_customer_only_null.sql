WITH source_data AS (
    SELECT
    c_custkey,
    c_name,
    c_address,
    c_nationkey,
    c_phone,
    c_acctbal,
    c_mktsegment,
    c_comment
    FROM `hive_metastore`.`dbtvault`.`CUSTOMER`
),
null_columns AS (
    SELECT
    c_name,
    c_address,
    c_phone,
    c_acctbal,
    c_mktsegment,
    c_comment,
    C_CUSTKEY AS C_CUSTKEY_ORIGINAL,
        IFNULL(C_CUSTKEY, '-1') AS C_CUSTKEY,
    C_NATIONKEY AS C_NATIONKEY_ORIGINAL,
        IFNULL(C_NATIONKEY, '-2') AS C_NATIONKEY
    FROM source_data
),
columns_to_select AS (
    SELECT
    c_name,
    c_address,
    c_phone,
    c_acctbal,
    c_mktsegment,
    c_comment,
    C_CUSTKEY,
    C_CUSTKEY_ORIGINAL,
    C_NATIONKEY,
    C_NATIONKEY_ORIGINAL
    FROM null_columns
)
SELECT * FROM columns_to_select