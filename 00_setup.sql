USE ROLE ACCOUNTADMIN;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE SYSADMIN;   

USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS LEAGUE_WH
  WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS LEAGUE_DB;
CREATE SCHEMA IF NOT EXISTS LEAGUE_DB.RAW;    -- what the scoring app writes
CREATE SCHEMA IF NOT EXISTS LEAGUE_DB.DEV;    -- dbt target: dev 
CREATE SCHEMA IF NOT EXISTS LEAGUE_DB.PROD;   -- dbt target: prod 

USE WAREHOUSE LEAGUE_WH;
USE SCHEMA LEAGUE_DB.RAW;

-- ---------------------------------------------------------------------
-- 1. Teams (fictional names)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE TEAMS (TEAM_ID NUMBER, TEAM_NAME STRING, HOME_CITY STRING);
INSERT INTO TEAMS VALUES
  (1, 'Bengaluru Blazers', 'Bengaluru'),
  (2, 'Mumbai Mariners',   'Mumbai'),
  (3, 'Delhi Falcons',     'Delhi'),
  (4, 'Chennai Cyclones',  'Chennai'),
  (5, 'Kolkata Comets',    'Kolkata'),
  (6, 'Pune Pythons',      'Pune'),
  (7, 'Jaipur Jaguars',    'Jaipur'),
  (8, 'Hyderabad Hawks',   'Hyderabad');

-- ---------------------------------------------------------------------
-- 2. Players: 11 per team. PLAYER_ID = team * 100 + shirt slot (101..111, 201..211 ...)
--    ROLE_CODE arrives messy, like a hand-filled admin form.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE PLAYERS AS
SELECT
  t.TEAM_ID * 100 + s.N                         AS PLAYER_ID,
  'Player ' || (t.TEAM_ID * 100 + s.N)          AS PLAYER_NAME,
  t.TEAM_ID,
  CASE WHEN s.N <= 5 THEN 'bat'
       WHEN s.N = 6  THEN 'WK '
       WHEN s.N <= 8 THEN ' Ar'
       ELSE 'BOWL' END                          AS ROLE_CODE
FROM TEAMS t
CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS N
            FROM TABLE(GENERATOR(ROWCOUNT => 11))) s;

-- ---------------------------------------------------------------------
-- 3. Matches: every team plays every other team once = 28 matches
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE MATCHES AS
SELECT
  ROW_NUMBER() OVER (ORDER BY h.TEAM_ID, a.TEAM_ID)                                AS MATCH_ID,
  DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY h.TEAM_ID, a.TEAM_ID) - 40, CURRENT_DATE()) AS MATCH_DATE,
  h.TEAM_ID                                                                         AS HOME_TEAM_ID,
  a.TEAM_ID                                                                         AS AWAY_TEAM_ID,
  h.HOME_CITY                                                                       AS VENUE_CITY
FROM TEAMS h
JOIN TEAMS a ON h.TEAM_ID < a.TEAM_ID;

-- ---------------------------------------------------------------------
-- 4. Ball-by-ball: 2 innings x 20 overs x 6 balls per match. ~ 240 rows per match
--    BALL_ID = (match * 10 + innings) * 1000 + slot  ->  11000 = match 1, innings 1, ball 1
--    Home team bats first. Batters are shirt slots 1-7, bowlers 7-11.
--    BALL_OUTCOME arrives messy: 'runs', 'Runs ', ' RUNS', 'Wide', 'noball', 'wicket'.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TEMPORARY TABLE TMP_BALL_SLOTS AS
WITH SLOTS AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS SLOT          -- 0..119
  FROM TABLE(GENERATOR(ROWCOUNT => 120))
), INNINGS AS (
  SELECT MATCH_ID, MATCH_DATE, 1 AS INNINGS, HOME_TEAM_ID AS BAT_TEAM, AWAY_TEAM_ID AS BOWL_TEAM FROM MATCHES
  UNION ALL
  SELECT MATCH_ID, MATCH_DATE, 2,            AWAY_TEAM_ID,             HOME_TEAM_ID              FROM MATCHES
)
SELECT
  i.MATCH_ID, i.MATCH_DATE, i.INNINGS, i.BAT_TEAM, i.BOWL_TEAM, s.SLOT,
  UNIFORM(1, 100, RANDOM()) AS R                                   -- one dice roll per ball
FROM INNINGS i CROSS JOIN SLOTS s;

CREATE OR REPLACE TABLE BALLS AS
SELECT
  (MATCH_ID * 10 + INNINGS) * 1000 + SLOT                                   AS BALL_ID,
  MATCH_ID,
  INNINGS,
  FLOOR(SLOT / 6)                                                           AS OVER_NO,     -- 0..19
  MOD(SLOT, 6) + 1                                                          AS BALL_NO,     -- 1..6
  BAT_TEAM  * 100 + UNIFORM(1, 7,  RANDOM())                                AS BATTER_ID,
  BOWL_TEAM * 100 + UNIFORM(7, 11, RANDOM())                                AS BOWLER_ID,
  CASE WHEN R <= 11 THEN 0
       ELSE ARRAY_CONSTRUCT(0,0,0,1,1,1,1,2,2,3,4,4,6)[UNIFORM(0, 12, RANDOM())]::NUMBER
  END                                                                       AS RUNS_OFF_BAT,
  IFF(R BETWEEN 6 AND 11, 1, 0)                                             AS EXTRAS,      -- wide / no-ball = 1 run
  CASE WHEN R <= 5  THEN 'wicket'
       WHEN R <= 9  THEN 'Wide'
       WHEN R <= 11 THEN 'noball'
       ELSE ARRAY_CONSTRUCT('runs', 'Runs ', ' RUNS', 'runs')[MOD(R, 4)]::STRING
  END                                                                       AS BALL_OUTCOME,
  DATEADD(SECOND, 14 * 3600 + (INNINGS - 1) * 6000 + SLOT * 40,
          MATCH_DATE::TIMESTAMP_NTZ)                                        AS BALL_TS      -- 2 PM start
FROM TMP_BALL_SLOTS;

-- What we just landed
SELECT COUNT(*) AS BALLS, COUNT(DISTINCT MATCH_ID) AS MATCHES FROM BALLS;   -- 6,720 balls, 28 matches

-- The mess dbt's staging layer will clean up
SELECT BALL_OUTCOME, COUNT(*) FROM BALLS  GROUP BY 1 ORDER BY 2 DESC;
SELECT ROLE_CODE,    COUNT(*) FROM PLAYERS GROUP BY 1;
