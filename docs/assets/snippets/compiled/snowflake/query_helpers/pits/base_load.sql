WITH as_of_dates AS (
    SELECT *
    FROM DBTVAULT.TEST.AS_OF_DATE AS a
),

new_rows_as_of_dates AS (
    SELECT
        a.CUSTOMER_PK,
        b.AS_OF_DATE
    FROM DBTVAULT.TEST.HUB_CUSTOMER AS a
    INNER JOIN as_of_dates AS b
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
)

SELECT DISTINCT * FROM pit