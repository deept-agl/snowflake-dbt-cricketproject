-- goes to: cricket_dbt/tests/assert_runs_off_bat_in_range.sql
-- Step 8b: a singular test is just a query. Any row returned = failure.
-- Off the bat, a batter scores 0 to 6 on one ball. Never negative.
select ball_id, runs_off_bat
from {{ ref('stg_balls') }}
where runs_off_bat < 0 or runs_off_bat > 6
