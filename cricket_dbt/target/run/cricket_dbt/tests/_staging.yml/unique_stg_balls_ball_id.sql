select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    ball_id as unique_field,
    count(*) as n_records

from LEAGUE_DB.DEV.stg_balls
where ball_id is not null
group by ball_id
having count(*) > 1



      
    ) dbt_internal_test