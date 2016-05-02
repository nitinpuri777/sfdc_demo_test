- view: rolling_30_day_activity_facts
  derived_table:
    sql: | 
      WITH daily_use AS (
        SELECT 
          user_id
          , license_slug
          , instance_slug
          , event_date as event_date
        FROM ${daily_event_rollup.SQL_TABLE_NAME}
      )
      SELECT
          ROW_NUMBER() OVER () AS unique_key
          , daily_use.user_id || '-' || daily_use.license_slug AS license_user_id
          , daily_use.user_id AS user_id
          , daily_use.license_slug as license_slug
          , wd.date as date
          , COUNT(DISTINCT instance_slug) AS count_of_instances
          , MIN(wd.date::date - daily_use.event_date::date) as days_since_last_action
      FROM daily_use, ${dates.SQL_TABLE_NAME} AS wd 
      WHERE
          wd.date >= daily_use.event_date
          AND wd.date < daily_use.event_date + interval '30 day'
          AND (((wd.date) >= (CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', DATEADD(day,-364, DATE_TRUNC('day',CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())) ))) AND (wd.date) < (CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', DATEADD(day,365, DATEADD(day,-364, DATE_TRUNC('day',CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())) ) )))))
      GROUP BY 1,2,3,4
    sql_trigger_value: SELECT DATE(DATE_ADD('hour', 3, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())))
    distkey: user_id
    sortkeys: [date]
    
  fields:
    - dimension: id
      type: string
      primary_key: true
      hidden: true
      sql: ${TABLE}.unique_key
      
    - dimension_group: date
      type: time
      timeframes: [raw, date, week, day_of_week]
      sql: ${TABLE}.date
      
    - dimension: license_user_id
      type: string
      hidden: true
      sql: ${TABLE}.license_user_id
  
    - dimension: user_id
      type: string
      sql: ${TABLE}.user_id

    - dimension: license_slug
      type: string
      hidden: true
      sql: ${TABLE}.license_slug
    
    - dimension: count_of_instances
      type: number
      sql: ${TABLE}.count_of_instances
      
    - dimension: days_since_last_action
      type: number
      sql: ${TABLE}.days_since_last_action
      value_format_name: decimal_0
      
    - dimension: active_this_day
      type: yesno
      sql: ${days_since_last_action} <  1   
      
    - dimension: active_last_7_days
      type: yesno
      sql: ${days_since_last_action} < 7      
      
    - measure: user_count_active_30_days
      label: 'Monthly Active Users'
      type: count_distinct
      sql: ${user_id}
#       drill_fields: [users.id, users.name]
      
    - measure: user_count_active_this_day
      label: 'Daily Active Users'
      type: count_distinct
      sql: ${user_id}
#       drill_fields: [users.id, users.name]
      filters:
        active_this_day: yes
       
    - measure: user_count_active_7_days
      label: 'Weekly Active Users'
      type: count_distinct
      sql: ${user_id}
#       drill_fields: [users.id, users.name]
      filters:
        active_last_7_days: yes