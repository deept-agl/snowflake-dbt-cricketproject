select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select match_id
from LEAGUE_DB.DEV.stg_matches
where match_id is null



      
    ) dbt_internal_test