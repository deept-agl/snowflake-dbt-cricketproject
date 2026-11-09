
  create or replace   view LEAGUE_DB.DEV.stg_matches
  
   as (
    -- goes to: cricket_dbt/models/staging/stg_matches.sql
select
    match_id,
    match_date,
    home_team_id,
    away_team_id,
    venue_city
from LEAGUE_DB.RAW.matches
  );

