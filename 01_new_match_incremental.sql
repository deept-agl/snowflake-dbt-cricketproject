-- =====================================================================
-- 01_new_match_incremental.sql
-- Run AFTER step 6 (fct_balls) is built once on dev.
-- A new match is played today. Watch the incremental model pick up only its balls.
-- =====================================================================
USE ROLE SYSADMIN;
USE WAREHOUSE LEAGUE_WH;
USE SCHEMA LEAGUE_DB.RAW;

-- 1. Before: how many balls does dbt's fact table have?
SELECT COUNT(*) AS BALLS_IN_FACT, MAX(BALL_TS) AS LATEST_BALL FROM LEAGUE_DB.DEV.FCT_BALLS;   -- 6,720

-- 2. Match 29: the final, played today. Blazers (1) v Mariners (2).
INSERT INTO MATCHES (MATCH_ID, MATCH_DATE, HOME_TEAM_ID, AWAY_TEAM_ID, VENUE_CITY)
VALUES (29, CURRENT_DATE(), 1, 2, 'Bengaluru');

CREATE OR REPLACE TEMPORARY TABLE TMP_FINAL_SLOTS AS
WITH SLOTS AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS SLOT FROM TABLE(GENERATOR(ROWCOUNT => 120))
), INNINGS AS (
  SELECT 29 AS MATCH_ID, CURRENT_DATE() AS MATCH_DATE, 1 AS INNINGS, 1 AS BAT_TEAM, 2 AS BOWL_TEAM
  UNION ALL
  SELECT 29, CURRENT_DATE(), 2, 2, 1
)
SELECT i.*, s.SLOT, UNIFORM(1, 100, RANDOM()) AS R
FROM INNINGS i CROSS JOIN SLOTS s;

INSERT INTO BALLS
SELECT
  (MATCH_ID * 10 + INNINGS) * 1000 + SLOT,
  MATCH_ID, INNINGS, FLOOR(SLOT / 6), MOD(SLOT, 6) + 1,
  BAT_TEAM  * 100 + UNIFORM(1, 7,  RANDOM()),
  BOWL_TEAM * 100 + UNIFORM(7, 11, RANDOM()),
  CASE WHEN R <= 11 THEN 0
       ELSE ARRAY_CONSTRUCT(0,0,0,1,1,1,1,2,2,3,4,4,6)[UNIFORM(0, 12, RANDOM())]::NUMBER END,
  IFF(R BETWEEN 6 AND 11, 1, 0),
  CASE WHEN R <= 5 THEN 'wicket' WHEN R <= 9 THEN 'Wide' WHEN R <= 11 THEN 'noball'
       ELSE ARRAY_CONSTRUCT('runs', 'Runs ', ' RUNS', 'runs')[MOD(R, 4)]::STRING END,
  DATEADD(SECOND, 14 * 3600 + (INNINGS - 1) * 6000 + SLOT * 40, MATCH_DATE::TIMESTAMP_NTZ)
FROM TMP_FINAL_SLOTS;

SELECT COUNT(*) FROM BALLS WHERE MATCH_ID = 29;    -- 240 new balls in RAW

-- 3. In the workspace (target dev), run:   run
--    Then come back here.
SELECT COUNT(*) AS BALLS_IN_FACT, MAX(BALL_TS) AS LATEST_BALL FROM LEAGUE_DB.DEV.FCT_BALLS;   -- 6,960

-- 4. Proof it was incremental: the last statement dbt ran on FCT_BALLS was a MERGE
--    of only the new rows, not a full rebuild.
SELECT QUERY_TEXT, ROWS_INSERTED, TOTAL_ELAPSED_TIME
FROM TABLE(LEAGUE_DB.INFORMATION_SCHEMA.QUERY_HISTORY(RESULT_LIMIT => 200))
WHERE QUERY_TEXT ILIKE 'merge into%fct_balls%'
ORDER BY START_TIME DESC
LIMIT 1;
