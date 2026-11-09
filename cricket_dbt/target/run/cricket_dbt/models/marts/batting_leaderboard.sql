
  
    

        create or replace transient table LEAGUE_DB.DEV.batting_leaderboard
         as
        (-- goes to: cricket_dbt/models/marts/batting_leaderboard.sql
-- Step 7: what the league website reads. One row per batter for the season.
select
    d.player_id,
    d.player_name,
    d.team_name,
    d.role_name,
    count(distinct f.match_id)                                                  as matches,
    sum(f.runs_off_bat)                                                         as runs,
    count_if(f.is_ball_faced)                                                   as balls_faced,
    round(sum(f.runs_off_bat) / nullif(count_if(f.is_ball_faced), 0) * 100, 1)  as strike_rate,
    count_if(f.runs_off_bat = 4)                                                as fours,
    count_if(f.runs_off_bat = 6)                                                as sixes,
    count_if(f.is_wicket)                                                       as times_out
from LEAGUE_DB.DEV.fct_balls f
join LEAGUE_DB.DEV.dim_players d
    on f.batter_id = d.player_id
group by 1, 2, 3, 4
        );
      
  