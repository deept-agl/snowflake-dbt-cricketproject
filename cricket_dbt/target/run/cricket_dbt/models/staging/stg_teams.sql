
  create or replace   view LEAGUE_DB.DEV.stg_teams
  
   as (
    -- goes to: cricket_dbt/models/staging/stg_teams.sql
select
    team_id,
    team_name,
    home_city
from LEAGUE_DB.RAW.teams
  );

