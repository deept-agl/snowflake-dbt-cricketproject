
    
    

select
    player_id as unique_field,
    count(*) as n_records

from LEAGUE_DB.DEV.batting_leaderboard
where player_id is not null
group by player_id
having count(*) > 1


