-- goes to: cricket_dbt/models/staging/stg_players.sql
-- Step 3b: role codes arrive as 'bat', 'WK ', ' Ar', 'BOWL'
select
    player_id,
    player_name,
    team_id,
    upper(trim(role_code))          as role_code
from {{ source('raw', 'players') }}
