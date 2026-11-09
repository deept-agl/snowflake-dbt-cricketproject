-- goes to: cricket_dbt/models/staging/stg_teams.sql
select
    team_id,
    team_name,
    home_city
from {{ source('raw', 'teams') }}
