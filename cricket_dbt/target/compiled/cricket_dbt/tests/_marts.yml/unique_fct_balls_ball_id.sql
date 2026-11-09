
    
    

select
    ball_id as unique_field,
    count(*) as n_records

from LEAGUE_DB.DEV.fct_balls
where ball_id is not null
group by ball_id
having count(*) > 1


