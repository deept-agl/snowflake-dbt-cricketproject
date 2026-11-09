
    
    

with all_values as (

    select
        role_code as value_field,
        count(*) as n_records

    from LEAGUE_DB.DEV.stg_players
    group by role_code

)

select *
from all_values
where value_field not in (
    'BAT','WK','AR','BOWL'
)


