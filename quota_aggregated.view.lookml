# Similar to the quota table, we created this to get team-level quotas. 
# For most customers, this data would be stored in a different format, 
# and a single quota table would likely suffice to give both individual and team-level aggregates.

- view: quota_aggregated
  derived_table:
    persist_for: 24 hours
    sortkeys: [quota_quarter]
    distkey: quota_quarter
    sql: |
            SELECT 
              quota_quarter 
              ,     sum(
                    case
                    when datediff(day, quota_quarter, current_date) < 93
                    then 93 / datediff(day, quota_quarter, current_date) * quota
                    else quota
                    end)
                    as sales_team_quota
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
    value_format_name: usd_0
  
  - measure: quota_sum
    type: sum
    sql: ${sales_team_quota}
  
  - measure: tracking_to_quota
    type: number
    sql: 1.0* ${opportunity.total_acv_won} / NULLIF(${quota_sum},0)
    value_format_name: percent_2
    
  sets:
    detail:
      - quota_quarter_time
      - sales_team_quota

