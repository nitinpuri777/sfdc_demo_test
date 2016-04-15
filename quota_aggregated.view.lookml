
- view: quota_aggregated
  derived_table:
    sql: |
            SELECT 
              quota_quarter 
              , SUM(quota) as sales_team_quota
            FROM public.quota q
            GROUP BY quota_quarter
            ORDER BY quota_quarter asc

  fields:
  - measure: count
    type: count
    drill_fields: detail*

  - dimension_group: quota
    type: time
    timeframes: [quarter]
    convert_tz: false
    sql: ${TABLE}.quota_quarter

  - dimension: quota_quarter_string
    primary_key: true
    hidden: true
    sql: EXTRACT(YEAR FROM ${TABLE}.quota_quarter ) || ' - Q' || EXTRACT(QUARTER FROM ${TABLE}.quota_quarter)    

  - dimension: sales_team_quota
    type: number
    sql: ${TABLE}.sales_team_quota
  
  - measure: quota_sum
    type: sum
    sql: ${sales_team_quota}
    
  sets:
    detail:
      - quota_quarter_time
      - sales_team_quota

