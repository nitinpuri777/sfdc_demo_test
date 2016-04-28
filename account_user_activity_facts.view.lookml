- view: rolling_30_day_activity_facts
  derived_table:
    sql: | 
      WITH daily_use AS (
        -- ## 2 ) Create a table of days and activity by user_id
        SELECT 
          user_id
          , license_slug
          , event_date as event_date
        FROM ${daily_event_rollup.SQL_TABLE_NAME}
      )
      --  ## 3) Cross join activity and dates to build a row for each user/date combo with
      -- days since last activity
      SELECT
            daily_use.user_id || '-' || daily_use.license_slug AS license_user_id
          , daily_use.user_id AS user_id
          , daily_use.license_slug as license_slug
          , wd.date as date
          , MIN(wd.date::date - daily_use.event_date::date) as days_since_last_action
      FROM daily_use, ${dates.SQL_TABLE_NAME} AS wd 
      WHERE
          wd.date >= daily_use.event_date
          AND wd.date < daily_use.event_date + interval '30 day'
          AND (((wd.date) >= (CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', DATEADD(day,-364, DATE_TRUNC('day',CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())) ))) AND (wd.date) < (CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', DATEADD(day,365, DATEADD(day,-364, DATE_TRUNC('day',CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())) ) )))))
      GROUP BY 1,2,3,4 
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/New_York', GETDATE()))
    distkey: user_id
    sortkeys: [date]
    
  fields:
    - dimension_group: date
      type: time
      timeframes: [raw, date, week, day_of_week]
      sql: ${TABLE}.date
      
    - dimension: license_user_id
      type: string
      sql: ${TABLE}.license_user_id
  
    - dimension: user_id
      type: string
      sql: ${TABLE}.user_id

    - dimension: license_slug
      type: string
      sql: ${TABLE}.license_slug
      
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
      sql: ${license_user_id}
#       drill_fields: [users.id, users.name]
      
    - measure: user_count_active_this_day
      label: 'Daily Active Users'
      type: count_distinct
      sql: ${license_user_id}
#       drill_fields: [users.id, users.name]
      filters:
        active_this_day: yes
       
    - measure: user_count_active_7_days
      label: 'Weekly Active Users'
      type: count_distinct
      sql: ${license_user_id}
#       drill_fields: [users.id, users.name]
      filters:
        active_last_7_days: yes