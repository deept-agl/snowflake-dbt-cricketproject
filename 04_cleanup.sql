-- 04_cleanup.sql
USE ROLE SYSADMIN;
ALTER TASK IF EXISTS LEAGUE_DB.PROD.NIGHTLY_LEADERBOARD SUSPEND;
DROP DATABASE IF EXISTS LEAGUE_DB;          -- also drops the DBT PROJECT object and the task
DROP WAREHOUSE IF EXISTS LEAGUE_WH;
-- The workspace itself stays in Projects > Workspaces. Delete it there if you want.
