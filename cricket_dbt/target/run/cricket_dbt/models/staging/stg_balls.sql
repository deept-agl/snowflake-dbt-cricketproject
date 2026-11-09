
  create or replace   view LEAGUE_DB.DEV.stg_balls
  
   as (
    -- goes to: cricket_dbt/models/staging/stg_balls.sql
-- Step 3a: one row per ball, cleaned. Outcome arrives as 'runs', 'Runs ', ' RUNS', 'Wide'...
with cleaned as (
    select
        ball_id,
        match_id,
        innings,
        over_no,
        ball_no,
        batter_id,
        bowler_id,
        runs_off_bat,
        extras,
        upper(trim(ball_outcome))   as ball_outcome,
        ball_ts
    from LEAGUE_DB.RAW.balls
)

select
    *,
    runs_off_bat + extras           as total_runs,
    ball_outcome = 'WICKET'         as is_wicket,
    ball_outcome <> 'WIDE'          as is_ball_faced     -- a wide doesn't count as a ball faced
from cleaned
  );

