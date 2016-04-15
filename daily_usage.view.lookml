- view: events_in_past_180_days
  derived_table:
    sql: |
      select * from events
        WHERE ((events.event_at) >= (DATEADD(day,-179, DATE_TRUNC('day',GETDATE()) )) 
            AND (events.event_at) < (DATEADD(day,180, DATEADD(day,-187, DATE_TRUNC('day',GETDATE()) ) )))
        AND event_type IN ('run_query', 'create_project', 'git_commit', 'field_select', 'filter_add', 'view_sql', 'api_call', 'download_query_results', ' view_results', 'login', 'create_user')
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))
    sortkeys: [event_at]
    
  fields:
      
  - dimension: id
    primary_key: true
    sql: ${TABLE}.id

  - dimension_group: event
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.event_at
  
  - dimension: event_type
    type: string
    sql: ${TABLE}.event_type

  - dimension: instance_slug
    sql: ${TABLE}.instance_slug

  - dimension: license_slug
    sql: ${TABLE}.license_slug

  - dimension: user_id
    type: number
    hidden: true
    sql: ${TABLE}.user_id

# MEASURES #

  - measure: count
    type: count
    drill_fields: [id]

  - measure: user_count
    type: count_distinct
    sql: ${user_id}

  - measure: count_of_query_runs
    type: count
    filters:
     event_type: 'run_query'
  
  - measure: count_of_project_creation
    type: count
    filters:
      event_type: 'create_project'

  - measure: count_of_git_commits
    type: count
    filters:
      event_type: 'git_commit'

  - measure: count_of_api_calls
    type: count
    filters:
      event_type: 'api_call'

  - measure: count_of_query_result_downloads
    type: count
    filters:
      event_type: 'download_query_results'

  - measure: count_of_logins
    type: count
    filters:
      event_type: 'login'

  - measure: count_of_dashboard_queries
    type: count
    filters:
      event_type: 'run_dashboard'

  - measure: count_of_dashboard_downloads
    type: count
    filters:
      event_type: 'open_dashboard_pdf'
    
  - measure: count_of_support_chats
    type: count
    filters:
      event_type: 'close_zopim_chat'

- view: find_idle_time
  derived_table:
    persist_for: 6 hours
    sortkeys: [user_id, created_at]
    sql: |
      SELECT
          events.event_at AS created_at
        , license.salesforce_account_id
        , license.license_slug AS license_id
        , events.user_id AS user_id
        , DATEDIFF(
            minute, 
            LAG(events.event_at) OVER ( PARTITION BY license.license_slug, events.user_id ORDER BY events.event_at)
          , events.event_at) AS idle_time
      FROM ${events_in_past_180_days.SQL_TABLE_NAME} AS events
      LEFT JOIN license ON events.license_slug = license.license_slug


- view: sessions
  derived_table:
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))
    distkey: license_id
    sortkeys: [session_start]
    sql: |
        SELECT
          find_idle_time.created_at AS session_start
          , find_idle_time.salesforce_account_id AS account_id
          , find_idle_time.license_id AS license_id
          , find_idle_time.user_id AS user_id
          , find_idle_time.idle_time AS idle_time
          , ROW_NUMBER () OVER (ORDER BY find_idle_time.created_at) AS unique_session_id
          , ROW_NUMBER () OVER (PARTITION BY license_id, user_id ORDER BY find_idle_time.created_at) AS session_sequence
          , COALESCE(
                LEAD(find_idle_time.created_at) OVER (PARTITION BY license_id, user_id ORDER BY find_idle_time.created_at)
              , '3000-01-01') AS next_session_start
        FROM ${find_idle_time.SQL_TABLE_NAME} AS find_idle_time
        -- set session thresholds (currently set at 30 minutes) 
        WHERE (find_idle_time.idle_time > 30 OR find_idle_time.idle_time IS NULL)
    
  fields:
    - dimension: session_start
      type: time
      timeframes: [time, date, week, month, year]
      sql: ${TABLE}.session_start

    - dimension: account_id
      type: string
      sql: ${TABLE}.account_id
    
    - dimension: idle_time
      type: number
      sql: ${TABLE}.idle_time
    
    - dimension: license_user_id
      type: string
      sql: CONCAT(${license_id}, CONCAT('-', ${user_id}))
    
    - dimension: license_id
      type: string
      sql: ${TABLE}.license_id
      
    - dimension: user_id
      type: string
      sql: ${TABLE}.user_id
    
    - dimension: unique_session_id
      primary_key: true
      type: string
      sql: ${TABLE}.unique_session_id
    
    - dimension: session_sequence
      type: number
      sql: ${TABLE}.session_sequence
    
    - dimension: next_session_start
      type: time
      timeframes: [time, date, week, month, year]
      sql: ${TABLE}.next_session_start
    
    - measure: count
      type: count
    
    - measure: user_count
      type: count_distinct
      sql: ${user_id}

- view: event_mapping
  derived_table:
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))
    distkey: event_id
    sortkeys: [created_at]
    sql: |
      SELECT
          events.id AS event_id
          , events.user_id
          , sessions.license_id AS license_slug
          , sessions.unique_session_id
          , events.event_at AS created_at
          , ROW_NUMBER() OVER (PARTITION BY unique_session_id ORDER BY events.event_at) AS event_sequence_within_session
      FROM ${events_in_past_180_days.SQL_TABLE_NAME} AS events
      INNER JOIN ${sessions.SQL_TABLE_NAME} AS sessions
        ON events.user_id = sessions.user_id
        AND events.event_at >= sessions.session_start
        AND events.event_at < sessions.next_session_start
        AND events.license_slug = sessions.license_id
      WHERE 
        ((events.event_at) >= (DATEADD(day,-179, DATE_TRUNC('day',GETDATE()) ))  AND (events.event_at) < (DATEADD(day,180, DATEADD(day,-179, DATE_TRUNC('day',GETDATE()) ) )))
      
      
  fields:
  
  - measure: count
    type: count
    drill_fields: detail*
  
  - dimension: license_slug
    type: string
    sql: ${TABLE}.license_slug
  
  - dimension: user_id
    type: string
    sql: ${TABLE}.user_id

  - dimension: event_id
    primary_key: true
    type: number
    sql: ${TABLE}.event_id
    
  - dimension: unique_session_id
    type: number
    sql: ${TABLE}.unique_session_id
    
  - dimension: event_sequence_within_session
    type: number
    sql: ${TABLE}.event_sequence_within_session

- view: session_facts
  derived_table:
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))
    distkey: unique_session_id
    sortkeys: [session_start]
    sql: |
        SELECT
              unique_session_id
            , user_id
            , MIN(created_at) AS session_start
            , MAX(created_at) AS session_end
            , ROW_NUMBER() OVER (PARTITION BY COALESCE(user_id) ORDER BY MIN(created_at)) AS session_sequence_for_user
        FROM ${event_mapping.SQL_TABLE_NAME} AS events_with_session_info
        GROUP BY 1,2
          
  fields:

  - dimension: unique_session_id
    hidden: true
    primary_key: true
    type: number
    sql: ${TABLE}.unique_session_id

  - dimension_group: session_start_at
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.session_start

  - dimension_group: session_end_at
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.session_end

  - dimension: session_sequence_for_user
    type: number
    sql: ${TABLE}.session_sequence_for_user

  - dimension: number_of_events_in_session
    type: number
    sql: ${TABLE}.number_of_events_in_session

  - dimension: session_length_minutes
    type: number
    sql: DATEDIFF('minute', ${TABLE}.session_start, ${TABLE}.session_end)

  - measure: total_session_length_minutes
    type: sum
    sql: ${session_length_minutes}
  
  - measure: total_session_length_minutes_1_week_ago
    type: sum
    hidden: true
    sql: ${session_length_minutes}
    filters:
      session_start_at_date: '3 weeks ago for 1 week'

  - measure: total_session_length_minutes_2_weeks_ago
    type: sum
    hidden: true
    sql: ${session_length_minutes}
    filters:
      session_start_at_date: '2 weeks ago for 1 week'
  
  - measure: percent_change_in_total_usage
    type: number
    sql: 1.0 * (${total_session_length_minutes_2_weeks_ago} - ${total_session_length_minutes_1_week_ago}) / NULLIF(${total_session_length_minutes_1_week_ago},0)
    value_format_name: percent_2
    
  - measure: average_session_length_minutes
    type: avg
    sql: ${session_length_minutes}
  
  - measure: count
    type: count
    
    
    