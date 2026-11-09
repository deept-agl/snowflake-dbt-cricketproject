-- =====================================================================
-- 03_scoreboard_goes_backwards.sql
-- `dbt run` then `dbt test`   vs   `dbt build`
-- =====================================================================
USE ROLE SYSADMIN;
USE WAREHOUSE LEAGUE_WH;

-- 0. Player 701's season runs right now (note the number down)
SELECT PLAYER_ID, PLAYER_NAME, RUNS, BALLS_FACED
FROM LEAGUE_DB.DEV.BATTING_LEADERBOARD WHERE PLAYER_ID = 701;

-- 1. The scoring app ships a bug. Two bad rows land in RAW for match 28:
--    a typo'd outcome ('wicekt'), and a scorer's correction written as -4 runs.
INSERT INTO LEAGUE_DB.RAW.BALLS
  (BALL_ID, MATCH_ID, INNINGS, OVER_NO, BALL_NO, BATTER_ID, BOWLER_ID,
   RUNS_OFF_BAT, EXTRAS, BALL_OUTCOME, BALL_TS)
SELECT 999001, 28, 1, 19, 5, 701, 808,  0, 0, 'wicekt', DATEADD(MINUTE, 1, MAX(BALL_TS)) FROM LEAGUE_DB.RAW.BALLS
UNION ALL
SELECT 999002, 28, 1, 19, 6, 701, 808, -4, 0, 'runs',   DATEADD(MINUTE, 1, MAX(BALL_TS)) FROM LEAGUE_DB.RAW.BALLS;
-- (timestamped just after the newest ball, so the incremental model is sure to pick them up)

-- 2. In the workspace (target dev), run:   run      <- models only, no tests
--    Everything succeeds. Now look at the leaderboard:
SELECT PLAYER_ID, PLAYER_NAME, RUNS, BALLS_FACED
FROM LEAGUE_DB.DEV.BATTING_LEADERBOARD WHERE PLAYER_ID = 701;
-- Runs went DOWN by 4. In cricket that can't happen. The website already shows it.

--    Then run:   test
--    accepted_values on ball_outcome FAILS, assert_runs_off_bat_in_range FAILS.
--    Correct tests... that ran AFTER the bad number was published.

-- 3. The same night with `build`.
--    Reset first, so the marts hold good data again:
DELETE FROM LEAGUE_DB.RAW.BALLS WHERE BALL_ID IN (999001, 999002);
--    workspace: build --full-refresh      (clean slate, all green)

INSERT INTO LEAGUE_DB.RAW.BALLS
  (BALL_ID, MATCH_ID, INNINGS, OVER_NO, BALL_NO, BATTER_ID, BOWLER_ID,
   RUNS_OFF_BAT, EXTRAS, BALL_OUTCOME, BALL_TS)
SELECT 999001, 28, 1, 19, 5, 701, 808,  0, 0, 'wicekt', DATEADD(MINUTE, 1, MAX(BALL_TS)) FROM LEAGUE_DB.RAW.BALLS
UNION ALL
SELECT 999002, 28, 1, 19, 6, 701, 808, -4, 0, 'runs',   DATEADD(MINUTE, 1, MAX(BALL_TS)) FROM LEAGUE_DB.RAW.BALLS;
-- (timestamped just after the newest ball, so the incremental model is sure to pick them up)

--    workspace: build
--    stg_balls builds (it's a view), its tests run straight after it, they FAIL,
--    and dbt SKIPS fct_balls and batting_leaderboard.
SELECT PLAYER_ID, PLAYER_NAME, RUNS, BALLS_FACED
FROM LEAGUE_DB.DEV.BATTING_LEADERBOARD WHERE PLAYER_ID = 701;
-- Same number as step 0. The website still shows last night's good leaderboard.

-- 4. Fix at the source, build again, all green.
UPDATE LEAGUE_DB.RAW.BALLS SET BALL_OUTCOME = 'wicket' WHERE BALL_ID = 999001;
DELETE FROM LEAGUE_DB.RAW.BALLS WHERE BALL_ID = 999002;   -- corrections belong in their own table
--    workspace: build
