select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select ball_id
from LEAGUE_DB.DEV.fct_balls
where ball_id is null



      
    ) dbt_internal_test