
    
    

select
    player_id as unique_field,
    count(*) as n_records

from LEAGUE_DB.DEV.dim_players
where player_id is not null
group by player_id
having count(*) > 1


