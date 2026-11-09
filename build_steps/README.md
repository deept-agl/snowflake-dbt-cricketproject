# build_steps: grow the dbt project one file at a time

You start with an **empty** `cricket_dbt/` folder in your workspace and copy each file below into it,
in this order. After each step there's something to run, so you see the project grow.

| Step | Copy | Into | Then run |
|---|---|---|---|
| 01 | `01_project/dbt_project.yml`, `profiles.yml` | `cricket_dbt/` | `compile` (the project is valid, it just has nothing in it yet) |
| 02 | `02_sources/_sources.yml` | `cricket_dbt/models/staging/` | nothing yet, sources are just pointers |
| 03 | `03_staging/stg_*.sql` (4 files) | `cricket_dbt/models/staging/` | `run`: four views appear in `LEAGUE_DB.DEV` |
| 04 | `04_seed/player_roles.csv` | `cricket_dbt/seeds/` | `seed`: a table from a CSV |
| 05 | `05_dimension/dim_players.sql` | `cricket_dbt/models/marts/` | `run`, then open the lineage (DAG) view |
| 06 | `06_fact/fct_balls.sql` | `cricket_dbt/models/marts/` | `run`, then `01_new_match_incremental.sql` and `run` again |
| 07 | `07_leaderboard/batting_leaderboard.sql` | `cricket_dbt/models/marts/` | `run`: the table the website reads |
| 08 | `08_tests/_staging.yml`, `_marts.yml` → their model folders; `assert_runs_off_bat_in_range.sql` → `cricket_dbt/tests/` | | `build`: every model and every test, in order |

Each `.sql` and `.yml` file starts with a `goes to:` line, so you always know where it belongs.

Want to skip ahead? `../finished/cricket_dbt/` has every file already in place.
