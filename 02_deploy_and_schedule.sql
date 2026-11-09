-- =====================================================================
-- 02_deploy_and_schedule.sql
-- Run AFTER the whole project builds green on dev (step 8: build).
-- =====================================================================
USE ROLE SYSADMIN;
USE WAREHOUSE LEAGUE_WH;

-- 1. Check the dev build produced what we expect
SELECT * FROM LEAGUE_DB.DEV.BATTING_LEADERBOARD ORDER BY RUNS DESC LIMIT 10;
SELECT BALL_OUTCOME, COUNT(*) FROM LEAGUE_DB.DEV.FCT_BALLS GROUP BY 1;   -- 4 clean values now

-- 2. Deploy: turn the workspace files into a versioned DBT PROJECT object.
--    In the workspace: Connect > Deploy dbt project
--      database LEAGUE_DB, schema PROD, name CRICKET_DBT
--    The Output tab shows the exact CREATE DBT PROJECT it ran. It looks like:
--
--    CREATE DBT PROJECT LEAGUE_DB.PROD.CRICKET_DBT
--      FROM '<workspace path shown in the Output tab>';
--
--    To ship a new version later, use ALTER DBT PROJECT ... ADD VERSION
--    (CREATE OR REPLACE throws away the run history).

SHOW DBT PROJECTS IN SCHEMA LEAGUE_DB.PROD;

-- 3. Run the deployed project against prod
EXECUTE DBT PROJECT LEAGUE_DB.PROD.CRICKET_DBT ARGS = 'seed --target prod';
EXECUTE DBT PROJECT LEAGUE_DB.PROD.CRICKET_DBT ARGS = 'build --target prod';

SELECT COUNT(*) FROM LEAGUE_DB.PROD.BATTING_LEADERBOARD;

-- 4. Schedule it: every night at 11:30 PM IST, after the day's match.
--    The task must live in the same database + schema as the dbt project object,
--    and must use a warehouse (serverless tasks can't run dbt).
CREATE OR REPLACE TASK LEAGUE_DB.PROD.NIGHTLY_LEADERBOARD
  WAREHOUSE = LEAGUE_WH
  SCHEDULE = 'USING CRON 30 23 * * * Asia/Kolkata'
AS
  EXECUTE DBT PROJECT LEAGUE_DB.PROD.CRICKET_DBT ARGS = 'build --target prod';

ALTER TASK LEAGUE_DB.PROD.NIGHTLY_LEADERBOARD RESUME;
EXECUTE TASK LEAGUE_DB.PROD.NIGHTLY_LEADERBOARD;     -- one run now, so we can see it

SELECT NAME, STATE, ERROR_MESSAGE, SCHEDULED_TIME, COMPLETED_TIME
FROM TABLE(LEAGUE_DB.INFORMATION_SCHEMA.TASK_HISTORY(
  SCHEDULED_TIME_RANGE_START => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())))
ORDER BY SCHEDULED_TIME DESC;

-- Run history + logs: Snowsight > Monitoring > dbt Projects (or Task history > the run)
