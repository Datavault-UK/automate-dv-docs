WITH

satellite_a AS (
    SELECT s.CUSTOMER_PK, s.HASHDIFF_1 AS HASHDIFF, s.SATELLITE_1 AS SATELLITE_NAME, s.LOAD_DATE, s.SOURCE
    FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT AS s
    WHERE s.CUSTOMER_PK IS NOT NULL
),

satellite_b AS (
    SELECT s.CUSTOMER_PK, s.HASHDIFF_2 AS HASHDIFF, s.SATELLITE_2 AS SATELLITE_NAME, s.LOAD_DATE, s.SOURCE
    FROM DBTVAULT.TEST.STG_CUSTOMER_2SAT AS s
    WHERE s.CUSTOMER_PK IS NOT NULL
),

union_satellites AS (
    SELECT * FROM satellite_a
    UNION ALL
    SELECT * FROM satellite_b
),

records_to_insert AS (
    SELECT DISTINCT union_satellites.* FROM union_satellites
    LEFT JOIN DBTVAULT.TEST.XTS_2SAT AS d
        ON (union_satellites.HASHDIFF = d.HASHDIFF
        AND union_satellites.LOAD_DATE = d.LOAD_DATE
        AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
    )
    WHERE d.HASHDIFF IS NULL
    AND d.LOAD_DATE IS NULL
    AND d.SATELLITE_NAME IS NULL
)

SELECT * FROM records_to_insert