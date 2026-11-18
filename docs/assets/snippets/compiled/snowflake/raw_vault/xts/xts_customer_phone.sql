WITH satellite_a AS (
    SELECT CUSTOMER_PK, HASHDIFF AS HASHDIFF, SATELLITE_NAME AS SATELLITE_NAME, LOAD_DATE, SOURCE
    FROM DBTVAULT.TEST.STG_CUSTOMER
    WHERE CUSTOMER_PK IS NOT NULL
),
union_satellites AS (
    SELECT *
    FROM satellite_a
),
records_to_insert AS (
    SELECT DISTINCT union_satellites.*
    FROM union_satellites
    LEFT JOIN DBTVAULT.TEST.XTS AS d
        ON (union_satellites.HASHDIFF = d.HASHDIFF
        AND union_satellites.LOAD_DATE = d.LOAD_DATE
        AND union_satellites.SATELLITE_NAME = d.SATELLITE_NAME
        )
    WHERE d.HASHDIFF IS NULL
        AND d.LOAD_DATE IS NULL
        AND d.SATELLITE_NAME IS NULL
)
SELECT * FROM records_to_insert