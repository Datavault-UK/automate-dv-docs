WITH as_of_dates AS (
    SELECT *
    FROM DBTVAULT.TEST.AS_OF_DATE
),
last_safe_load_datetime AS (
    SELECT MIN(LOAD_DATETIME) AS LAST_SAFE_LOAD_DATETIME
    FROM (
        SELECT MIN(LOAD_DATE) AS LOAD_DATETIME FROM DBTVAULT.TEST.STG_CUSTOMER_DETAILS
        UNION ALL
        SELECT MIN(LOAD_DATE) AS LOAD_DATETIME FROM DBTVAULT.TEST.STG_CUSTOMER_LOGIN
        UNION ALL
        SELECT MIN(LOAD_DATE) AS LOAD_DATETIME FROM DBTVAULT.TEST.STG_CUSTOMER_PROFILE
    ) a
),
as_of_grain_old_entries AS (
    SELECT DISTINCT AS_OF_DATE
    FROM DBTVAULT.TEST.PIT_CUSTOMER
),
as_of_grain_lost_entries AS (
    SELECT a.AS_OF_DATE
    FROM as_of_grain_old_entries AS a
    LEFT OUTER JOIN as_of_dates AS b
        ON a.AS_OF_DATE = b.AS_OF_DATE
    WHERE b.AS_OF_DATE IS NULL
),
as_of_grain_new_entries AS (
    SELECT a.AS_OF_DATE
    FROM as_of_dates AS a
    LEFT OUTER JOIN as_of_grain_old_entries AS b
        ON a.AS_OF_DATE = b.AS_OF_DATE
    WHERE b.AS_OF_DATE IS NULL
),
min_date AS (
    SELECT min(AS_OF_DATE) AS MIN_DATE
    FROM as_of_dates
),
backfill_as_of AS (
    SELECT AS_OF_DATE
    FROM as_of_dates AS a
    WHERE a.AS_OF_DATE < (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
),
new_rows_pks AS (
    SELECT a.CUSTOMER_PK
    FROM DBTVAULT.TEST.HUB_CUSTOMER AS a
    WHERE a.LOAD_DATE >= (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
),
new_rows_as_of AS (
    SELECT AS_OF_DATE
    FROM as_of_dates AS a
    WHERE a.AS_OF_DATE >= (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
    UNION
    SELECT AS_OF_DATE
    FROM as_of_grain_new_entries
),
overlap AS (
    SELECT a.*
    FROM DBTVAULT.TEST.PIT_CUSTOMER AS a
    INNER JOIN DBTVAULT.TEST.HUB_CUSTOMER as b
        ON a.CUSTOMER_PK = b.CUSTOMER_PK
    WHERE a.AS_OF_DATE >= (SELECT MIN_DATE FROM min_date)
        AND a.AS_OF_DATE < (SELECT LAST_SAFE_LOAD_DATETIME FROM last_safe_load_datetime)
        AND a.AS_OF_DATE NOT IN (SELECT AS_OF_DATE FROM as_of_grain_lost_entries)
),
-- Back-fill any newly arrived hubs, set all historical pit dates to ghost records
backfill_rows_as_of_dates AS (
    SELECT
        a.CUSTOMER_PK,
        b.AS_OF_DATE
    FROM new_rows_pks AS a
    INNER JOIN backfill_as_of AS b
        ON (1=1 )
),
backfill AS (
    SELECT
        a.CUSTOMER_PK,
        a.AS_OF_DATE,
        CAST('0000000000000000' AS BINARY(16)) AS SAT_CUSTOMER_DETAILS_PK,
        CAST('1900-01-01 00:00:00.000' AS timestamp_ntz) AS SAT_CUSTOMER_DETAILS_LDTS,
        CAST('0000000000000000' AS BINARY(16)) AS SAT_CUSTOMER_LOGIN_PK,
        CAST('1900-01-01 00:00:00.000' AS timestamp_ntz) AS SAT_CUSTOMER_LOGIN_LDTS,
        CAST('0000000000000000' AS BINARY(16)) AS SAT_CUSTOMER_PROFILE_PK,
        CAST('1900-01-01 00:00:00.000' AS timestamp_ntz) AS SAT_CUSTOMER_PROFILE_LDTS
    FROM backfill_rows_as_of_dates AS a
    LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_DETAILS AS sat_customer_details_src
        ON a.CUSTOMER_PK = sat_customer_details_src.CUSTOMER_PK
        AND sat_customer_details_src.LOAD_DATE <= a.AS_OF_DATE
    LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_LOGIN AS sat_customer_login_src
        ON a.CUSTOMER_PK = sat_customer_login_src.CUSTOMER_PK
        AND sat_customer_login_src.LOAD_DATE <= a.AS_OF_DATE
    LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_PROFILE AS sat_customer_profile_src
        ON a.CUSTOMER_PK = sat_customer_profile_src.CUSTOMER_PK
        AND sat_customer_profile_src.LOAD_DATE <= a.AS_OF_DATE
    GROUP BY
        a.CUSTOMER_PK, a.AS_OF_DATE
),
new_rows_as_of_dates AS (
    SELECT
        a.CUSTOMER_PK,
        b.AS_OF_DATE
    FROM DBTVAULT.TEST.HUB_CUSTOMER AS a
    INNER JOIN new_rows_as_of AS b
    ON (1=1)
),
new_rows AS (
    SELECT
        a.CUSTOMER_PK,
        a.AS_OF_DATE,
        COALESCE(MAX(sat_customer_details_src.CUSTOMER_PK), CAST('0000000000000000' AS BINARY(16))) AS SAT_CUSTOMER_DETAILS_PK,
        COALESCE(MAX(sat_customer_details_src.LOAD_DATE), CAST('1900-01-01 00:00:00.000' AS timestamp_ntz)) AS SAT_CUSTOMER_DETAILS_LDTS,
        COALESCE(MAX(sat_customer_login_src.CUSTOMER_PK), CAST('0000000000000000' AS BINARY(16))) AS SAT_CUSTOMER_LOGIN_PK,
        COALESCE(MAX(sat_customer_login_src.LOAD_DATE), CAST('1900-01-01 00:00:00.000' AS timestamp_ntz)) AS SAT_CUSTOMER_LOGIN_LDTS,
        COALESCE(MAX(sat_customer_profile_src.CUSTOMER_PK), CAST('0000000000000000' AS BINARY(16))) AS SAT_CUSTOMER_PROFILE_PK,
        COALESCE(MAX(sat_customer_profile_src.LOAD_DATE), CAST('1900-01-01 00:00:00.000' AS timestamp_ntz)) AS SAT_CUSTOMER_PROFILE_LDTS
    FROM new_rows_as_of_dates AS a
    LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_DETAILS AS sat_customer_details_src
        ON a.CUSTOMER_PK = sat_customer_details_src.CUSTOMER_PK
        AND sat_customer_details_src.LOAD_DATE <= a.AS_OF_DATE
    LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_LOGIN AS sat_customer_login_src
        ON a.CUSTOMER_PK = sat_customer_login_src.CUSTOMER_PK
        AND sat_customer_login_src.LOAD_DATE <= a.AS_OF_DATE
    LEFT JOIN DBTVAULT.TEST.SAT_CUSTOMER_PROFILE AS sat_customer_profile_src
        ON a.CUSTOMER_PK = sat_customer_profile_src.CUSTOMER_PK
        AND sat_customer_profile_src.LOAD_DATE <= a.AS_OF_DATE
    GROUP BY
        a.CUSTOMER_PK, a.AS_OF_DATE
),
pit AS (
    SELECT * FROM new_rows
    UNION ALL
    SELECT * FROM overlap
    UNION ALL
    SELECT * FROM backfill
)
SELECT DISTINCT * FROM pit