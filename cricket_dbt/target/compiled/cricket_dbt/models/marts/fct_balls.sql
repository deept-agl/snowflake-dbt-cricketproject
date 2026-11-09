-- goes to: cricket_dbt/models/marts/fct_balls.sql
-- Step 6: incremental. The first run builds every ball. After that, only balls newer
-- than what's already in the table. unique_key: a re-sent ball updates instead of duplicating.


select
    b.ball_id,
    b.match_id,
    m.match_date,
    m.venue_city,
    b.innings,
    b.over_no,
    b.ball_no,
    b.batter_id,
    b.bowler_id,
    b.ball_outcome,
    b.runs_off_bat,
    b.extras,
    b.total_runs,
    b.is_wicket,
    b.is_ball_faced,
    b.ball_ts
from LEAGUE_DB.DEV.stg_balls b
join LEAGUE_DB.DEV.stg_matches m
    on b.match_id = m.match_id


where b.ball_ts > (select max(ball_ts) from LEAGUE_DB.DEV.fct_balls)
