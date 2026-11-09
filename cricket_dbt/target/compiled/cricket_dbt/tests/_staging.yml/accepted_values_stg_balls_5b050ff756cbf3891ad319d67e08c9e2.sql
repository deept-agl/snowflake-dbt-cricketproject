
    
    

with all_values as (

    select
        ball_outcome as value_field,
        count(*) as n_records

    from LEAGUE_DB.DEV.stg_balls
    group by ball_outcome

)

select *
from all_values
where value_field not in (
    'RUNS','WICKET','WIDE','NOBALL'
)


