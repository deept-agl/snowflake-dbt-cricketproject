select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select batter_id
from LEAGUE_DB.DEV.stg_balls
where batter_id is null



      
    ) dbt_internal_test