
    
    

with child as (
    select batter_id as from_field
    from LEAGUE_DB.DEV.stg_balls
    where batter_id is not null
),

parent as (
    select player_id as to_field
    from LEAGUE_DB.DEV.stg_players
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


