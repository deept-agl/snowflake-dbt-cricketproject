
  
    

        create or replace transient table LEAGUE_DB.DEV.dim_players
         as
        (-- goes to: cricket_dbt/models/marts/dim_players.sql
-- Step 5: one row per player, with the team name and the role name from the seed.
-- ref() is how models point at each other. It's also how dbt works out the run order.
select
    p.player_id,
    p.player_name,
    p.team_id,
    t.team_name,
    p.role_code,
    coalesce(r.role_name, 'Unknown')    as role_name
from LEAGUE_DB.DEV.stg_players p
join LEAGUE_DB.DEV.stg_teams t
    on p.team_id = t.team_id
left join LEAGUE_DB.DEV.player_roles r
    on p.role_code = r.role_code
        );
      
  