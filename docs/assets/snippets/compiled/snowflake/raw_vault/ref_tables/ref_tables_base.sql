WITH to_insert AS (
    SELECT DISTINCT
    a.DATE_PK, a.YEAR, a.MONTH, a.DAY, a.DAY_OF_WEEK
    FROM ALEX_HIGGS.AUTOMATE_DV_DOCS_SAMPLES.REF_DATE AS a
    WHERE a.DATE_PK IS NOT NULL
),

non_historized AS (
    SELECT
    a.DATE_PK, a.YEAR, a.MONTH, a.DAY, a.DAY_OF_WEEK
    FROM to_insert AS a
)

SELECT * FROM non_historized