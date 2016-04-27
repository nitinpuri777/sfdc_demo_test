- view: daily_event_rollup
  derived_table:
    sql: |
      SELECT
          DATE(event_at) AS event_date
        , license_slug AS license_slug
        , instance_slug AS instance_slug
        , user_id AS user_id
        , event_type AS event_type
        , COUNT(*) AS count_of_events
      FROM events
      WHERE event_type IN ('run_query', 'create_project', 'git_commit', 'open_dashboard_pdf', 'api_call', 'download_query_results', 'login', 'run_dashboard', 'open_dashboard_pdf', 'close_zopim_chat')
      GROUP BY 1, 2, 3, 4, 5
    sql_trigger_value: SELECT DATE(DATE_ADD('hour', 1, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())))
    distkey: license_slug
    sortkeys: [license_slug, instance_slug, user_id, event_type]

  fields:
      
  - dimension: id
    primary_key: true
    type: string
    sql: ${event_date} || '-' || ${event_type} || '-' || ${license_slug} || '-' || ${instance_slug} || '-' || ${user_id}

  - dimension_group: event
    type: time
    timeframes: [raw, date, week, month]
    sql: ${TABLE}.event_date

  - dimension: event_weeks_ago
    type: number
    sql: DATE_DIFF('week', ${event_raw}, CURRENT_DATE)

  - dimension: event_months_ago
    type: number
    sql: DATE_DIFF('month', ${event_raw}, CURRENT_DATE)
  
  - dimension: event_type
    type: string
    sql: ${TABLE}.event_type

  - dimension: instance_slug
    type: string
    sql: ${TABLE}.instance_slug

  - dimension: license_slug
    type: string
    sql: ${TABLE}.license_slug

  - dimension: user_id
    type: string
    sql: ${TABLE}.user_id
  
  - dimension: count_of_events
    type: number
    sql: ${TABLE}.count_of_events

# MEASURES #

  - measure: count
    type: count
    drill_fields: [id]

  - measure: user_count
    type: count_distinct
    sql: ${user_id}

  - measure: count_of_query_runs
    type: sum
    sql: ${count_of_events}
    filters:
     event_type: 'run_query'
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}    
  
  - measure: count_of_project_creation
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'create_project'
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_git_commits
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'git_commit'
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_api_calls
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'api_call'
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_query_result_downloads
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'download_query_results'
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_logins
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'login'
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_dashboard_queries
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'run_dashboard'
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_dashboard_downloads
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'open_dashboard_pdf'
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
    
  - measure: count_of_support_chats
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'close_zopim_chat'
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

### DATE FILTERED MEASURES ###
  - measure: user_count_last_week
    type: count_distinct
    sql: ${user_id}
    filters:
      event_weeks_ago: 1

  - measure: count_of_query_runs_last_week
    type: sum
    sql: ${count_of_events}
    filters:
     event_type: 'run_query'
     event_weeks_ago: 1
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}    
  
  - measure: count_of_project_creation_last_week
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'create_project'
      event_weeks_ago: 1
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_git_commits_last_week
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'git_commit'
      event_weeks_ago: 1
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_api_calls_last_week
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'api_call'
      event_weeks_ago: 1
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_query_result_downloads_last_week
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'download_query_results'
      event_weeks_ago: 1
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_logins_last_week
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'login'
      event_weeks_ago: 1
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_dashboard_queries_last_week
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'run_dashboard'
      event_weeks_ago: 1
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_dashboard_downloads_last_week
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'open_dashboard_pdf'
      event_weeks_ago: 1
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
    
  - measure: count_of_support_chats_last_week
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'close_zopim_chat'
      event_weeks_ago: 1
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}


  - measure: user_count_two_weeks_ago
    type: count_distinct
    sql: ${user_id}
    filters:
      event_weeks_ago: 2
      
  - measure: count_of_query_runs_two_weeks_ago
    type: sum
    sql: ${count_of_events}
    filters:
     event_type: 'run_query'
     event_weeks_ago: 2
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}    
  
  - measure: count_of_project_creation_two_weeks_ago
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'create_project'
      event_weeks_ago: 2
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_git_commits_two_weeks_ago
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'git_commit'
      event_weeks_ago: 2
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_api_calls_two_weeks_ago
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'api_call'
      event_weeks_ago: 2
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_query_result_downloads_two_weeks_ago
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'download_query_results'
      event_weeks_ago: 2
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_logins_two_weeks_ago
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'login'
      event_weeks_ago: 2
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_dashboard_queries_two_weeks_ago
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'run_dashboard'
      event_weeks_ago: 2
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

  - measure: count_of_dashboard_downloads_two_weeks_ago
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'open_dashboard_pdf'
      event_weeks_ago: 2
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
    
  - measure: count_of_support_chats_two_weeks_ago
    type: sum
    sql: ${count_of_events}
    filters:
      event_type: 'close_zopim_chat'
      event_weeks_ago: 2
    html: |
      {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}

### COMPOSITE MEASURES ###
  
  - measure: usage_minutes
    type: number
    value_format_name: decimal_2
    sql: |
      1.0 * (${count_of_dashboard_queries} * 10
      + ${count_of_dashboard_downloads} * 5
      + ${count_of_support_chats} * 10
      + ${count_of_query_runs} * 3
      + ${count_of_project_creation} * 5
      + ${count_of_git_commits} * 5
      + ${count_of_api_calls} * 3
      + ${count_of_query_result_downloads} * 5
      + ${count_of_logins} * 3) / 60

  - measure: usage_minutes_last_week
    type: number
    value_format_name: decimal_2
    sql: |
      1.0 * (${count_of_dashboard_queries_last_week} * 10
      + ${count_of_dashboard_downloads_last_week} * 5
      + ${count_of_support_chats_last_week} * 10
      + ${count_of_query_runs_last_week} * 3
      + ${count_of_project_creation_last_week} * 5
      + ${count_of_git_commits_last_week} * 5
      + ${count_of_api_calls_last_week} * 3
      + ${count_of_query_result_downloads_last_week} * 5
      + ${count_of_logins_last_week} * 3) / 60

  - measure: usage_minutes_two_weeks_ago
    type: number
    value_format_name: decimal_2
    sql: |
      1.0 * (${count_of_dashboard_queries_two_weeks_ago} * 10
      + ${count_of_dashboard_downloads_two_weeks_ago} * 5
      + ${count_of_support_chats_two_weeks_ago} * 10
      + ${count_of_query_runs_two_weeks_ago} * 3
      + ${count_of_project_creation_two_weeks_ago} * 5
      + ${count_of_git_commits_two_weeks_ago} * 5
      + ${count_of_api_calls_two_weeks_ago} * 3
      + ${count_of_query_result_downloads_two_weeks_ago} * 5
      + ${count_of_logins_two_weeks_ago} * 3) / 60

- explore: weekly_event_rollup
- view: weekly_event_rollup
  derived_table:
    sql_trigger_value: SELECT DATE(DATE_ADD('hour', 1, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())))
    distkey: license_slug
    sortkeys: [event_week, license_slug]
    sql: |
      SELECT 
        license.salesforce_account_id AS account_id
        , DATE_TRUNC('week', daily_event_rollup.event_date) AS event_week
        , daily_event_rollup.license_slug AS license_slug
        , SUM(CASE WHEN (daily_event_rollup.event_type = 'open_dashboard_pdf') THEN daily_event_rollup.count_of_events ELSE 0 END) AS count_of_dashboard_downloads
        , SUM(CASE WHEN (daily_event_rollup.event_type = 'run_dashboard') THEN daily_event_rollup.count_of_events ELSE 0 END) AS count_of_dashboard_queries
        , SUM(CASE WHEN (daily_event_rollup.event_type = 'git_commit') THEN daily_event_rollup.count_of_events ELSE 0 END) AS count_of_git_commits
        , SUM(CASE WHEN (daily_event_rollup.event_type = 'login') THEN daily_event_rollup.count_of_events ELSE 0 END) AS count_of_logins
        , SUM(CASE WHEN (daily_event_rollup.event_type = 'create_project') THEN daily_event_rollup.count_of_events ELSE 0 END) AS count_of_project_creation
        , SUM(CASE WHEN (daily_event_rollup.event_type = 'download_query_results') THEN daily_event_rollup.count_of_events ELSE 0 END) AS count_of_query_result_downloads
        , SUM(CASE WHEN (daily_event_rollup.event_type = 'run_query') THEN daily_event_rollup.count_of_events ELSE 0 END) AS count_of_query_runs
        , SUM(CASE WHEN (daily_event_rollup.event_type = 'close_zopim_chat') THEN daily_event_rollup.count_of_events ELSE 0 END) AS count_of_support_chats
        , SUM(CASE WHEN (daily_event_rollup.event_type = 'api_call') THEN daily_event_rollup.count_of_events ELSE 0 END) AS count_of_api_calls
        , COUNT(DISTINCT daily_event_rollup.user_id) AS user_count
        , COUNT(DISTINCT user_id || instance_slug) AS total_weekly_users
        , LAG(COUNT(DISTINCT user_id || instance_slug), 1) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('week', daily_event_rollup.event_date)) AS last_week_users
        , FLOOR(((DATE_PART(EPOCH, DATE_TRUNC('week', daily_event_rollup.event_date))::BIGINT)/(60*5)) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0)) AS approximate_usage_minutes
        , LAG((FLOOR((DATE_PART(EPOCH, DATE_TRUNC('week', daily_event_rollup.event_date))::BIGINT)/(60*5))) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0), 1) OVER (PARTITION BY account_id ORDER BY event_week) AS last_week_usage_minutes
        , LAG(COUNT(DISTINCT user_id), 1) OVER (PARTITION BY daily_event_rollup.license_slug ORDER BY DATE_TRUNC('week', daily_event_rollup.event_date)) AS last_week_events
        , SUM(FLOOR(((DATE_PART(EPOCH, DATE_TRUNC('week', daily_event_rollup.event_date))::BIGINT)/(60*5)) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0))) OVER (PARTITION BY account_id ORDER BY event_week ROWS UNBOUNDED PRECEDING) as lifetime_usage_minutes
      FROM ${daily_event_rollup.SQL_TABLE_NAME} AS daily_event_rollup
      INNER JOIN license ON daily_event_rollup.license_slug = license.license_slug
      LEFT JOIN ${max_user_usage.SQL_TABLE_NAME} AS max_user_usage ON max_user_usage.salesforce_account_id = license.salesforce_account_id
      GROUP BY 1,2,3
      ORDER BY 1 DESC

  fields:
    ### DIMENSIONS ###
    - dimension: unique_key
      hidden: true
      primary_key: true
      sql: ${license_slug} || '-' || ${event_week}
    
    - dimension: license_slug
      type: string
      sql: ${TABLE}.license_slug
    
    - dimension: account_id
      type: string
      sql: ${TABLE}.account_id

    - dimension: last_week_events
      type: number
      sql: ${TABLE}.last_week_events
    
    - dimension: lifetime_usage_minutes
      type: number
      sql: ${TABLE}.lifetime_usage_minutes

    - dimension_group: event
      type: time
      timeframes: [raw, week, month]
      sql: ${TABLE}.event_week
    
    - dimension: event_weeks_ago
      type: number
      sql: DATE_DIFF('week', ${event_raw}, DATE_TRUNC('week', CURRENT_DATE))

    - dimension: event_months_ago
      type: number
      sql: DATE_DIFF('month', ${event_raw}, DATE_TRUNC('month', CURRENT_DATE))

    - dimension: current_weekly_users
      type: number
      sql: ${TABLE}.total_weekly_users

    - dimension: last_week_users
      type: number
      sql: ${TABLE}.last_week_users
    
    - dimension: weekly_event_count
      sql: ${TABLE}.weekly_event_count
    
    - dimension: approximate_usage_minutes
      type: number
      sql: ${TABLE}.approximate_usage_minutes

    - dimension: last_week_usage_minutes
      type: number
      sql: ${TABLE}.last_week_usage_minutes
    
    - dimension: count_of_query_runs
      type: number
      sql: ${TABLE}.count_of_query_runs
  
    - dimension: count_of_project_creation
      type: number
      sql: ${TABLE}.count_of_project_creation
  
    - dimension: count_of_git_commits
      type: number
      sql: ${TABLE}.count_of_git_commits
  
    - dimension: count_of_api_calls
      type: number
      sql: ${TABLE}.count_of_api_calls
  
    - dimension: count_of_query_result_downloads
      type: number
      sql: ${TABLE}.count_of_query_result_downloads
  
    - dimension: count_of_logins
      type: number
      sql: ${TABLE}.count_of_logins

    - dimension: count_of_dashboard_queries
      type: number
      sql: ${TABLE}.count_of_dashboard_queries

    - dimension: count_of_dashboard_downloads
      type: number
      sql: ${TABLE}.count_of_dashboard_downloads
      
    - dimension: count_of_support_chats
      type: number
      sql: ${TABLE}.count_of_support_chats
      
      
    ### DERIVED DIMENSIONS ###
#     - dimension: weeks_since_signup
#       type: number
#       sql: DATEDIFF('week',${opportunity.closed_raw}, ${event_raw})
    
#     - dimension: weeks_ago
#       type: number
#       sql: DATEDIFF(week, ${event_raw}, DATE_TRUNC('week',CURRENT_DATE))
#     
#     - dimension: months_ago
#       type: number
#       sql: DATEDIFF(month, ${event_raw}, DATE_TRUNC('month',CURRENT_DATE))
      
    - dimension: usage_change_percent
      type: number
      sql: COALESCE(1.0 * (${approximate_usage_minutes} - ${last_week_usage_minutes}) / NULLIF(${last_week_usage_minutes},0),0)
      value_format_name: percent_2

    - dimension: user_count_change
      type: number
      sql: 1.0* (${current_weekly_users} - ${last_week_users}) / NULLIF(${last_week_users},0)
      html: |
        {% if value <= 0.2 and value >= -0.2 %}
          <div style="color: black; background-color: goldenrod; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value < -0.2 %}
          <div style="color: white; background-color: darkred; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}
    
    - dimension: usage_change_percent_score
      type: number
      sql: |
        CASE
          WHEN ${usage_change_percent} <= -0.35 THEN 1.0
          WHEN ${usage_change_percent} <= -0.3 THEN 1.6
          WHEN ${usage_change_percent} <= -0.25 THEN 2.2
          WHEN ${usage_change_percent} <= -0.2 THEN 2.8
          WHEN ${usage_change_percent} <= -0.15 THEN 3.4
          WHEN ${usage_change_percent} <= -0.1 THEN 4.0
          WHEN ${usage_change_percent} <= -0.05 THEN 4.6
          WHEN ${usage_change_percent} <= 0.05 THEN 5.2
          WHEN ${usage_change_percent} <= 0.1 THEN 5.8
          WHEN ${usage_change_percent} <= 0.15 THEN 6.4
          WHEN ${usage_change_percent} <= 0.2 THEN 7.0
          WHEN ${usage_change_percent} <= 0.25 THEN 7.7
          WHEN ${usage_change_percent} <= 0.3 THEN 8.4
          WHEN ${usage_change_percent} <= 0.35 THEN 9.1
          WHEN ${usage_change_percent} > 0.35  THEN 10
          ELSE 3
        END

    - dimension: lifetime_usage_minutes_score
      type: number
      sql: |
        CASE
          WHEN ${lifetime_usage_minutes} IN (0, NULL) THEN 0.0
          WHEN ${lifetime_usage_minutes} <= 100000 THEN 1
          WHEN ${lifetime_usage_minutes} <= 300000 THEN 1.7
          WHEN ${lifetime_usage_minutes} <= 500000 THEN 2.4
          WHEN ${lifetime_usage_minutes} <= 700000 THEN 3.1
          WHEN ${lifetime_usage_minutes} <= 900000 THEN 3.8
          WHEN ${lifetime_usage_minutes} <= 1100000  THEN 4.5
          WHEN ${lifetime_usage_minutes} <= 1300000  THEN 5.2
          WHEN ${lifetime_usage_minutes} <= 1500000  THEN 5.9
          WHEN ${lifetime_usage_minutes} <= 1700000  THEN 6.6
          WHEN ${lifetime_usage_minutes} <= 1900000  THEN 7.3
          WHEN ${lifetime_usage_minutes} <= 2100000  THEN 8.0
          WHEN ${lifetime_usage_minutes} <= 2300000  THEN 8.7
          WHEN ${lifetime_usage_minutes} <= 2500000  THEN 9.4
          WHEN ${lifetime_usage_minutes} > 2500000  THEN 10
          ELSE 3
        END
  
    - dimension: current_weekly_users_score
      type: number
      sql: |
        CASE
          WHEN ${current_weekly_users} IN (0, NULL) THEN 0
          WHEN ${current_weekly_users} <= 50 THEN 1
          WHEN ${current_weekly_users} <= 100  THEN 3
          WHEN ${current_weekly_users} > 100  THEN 5
          ELSE 3
        END
    
    - dimension: account_health_score
      type: number
      sql: 100.0 * (${usage_change_percent_score} + ${lifetime_usage_minutes_score} + ${current_weekly_users_score}) / 25
      value_format_name: decimal_2
    
    - dimension: account_health
      type: string
      sql: |
        CASE
          WHEN ${account_health_score} < 40 THEN '1. At Risk'
          WHEN ${account_health_score} < 70 THEN '2. Standard'
          WHEN ${account_health_score} >= 70 THEN '3. Safe'
          ELSE 'NA'
        END
      html: |
        {% if value == '1. At Risk' %}
          <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% elsif value == '2. Standard' %}
          <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% else %}
          <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% endif %}

  ### MEASURES ###
    - measure: count_of_accounts
      type: count_distinct
      sql: ${license_slug}
      drill_fields: detail*

    - measure: average_event_count
      type: average
      sql: ${weekly_event_count}
      value_format_name: decimal_2
      drill_fields: detail*
    
    - measure: average_current_weekly_users
      type: average
      sql: ${current_weekly_users}
      value_format_name: decimal_2
      drill_fields: detail*
    
    - measure: average_usage_change_percent
      description: usage change by week
      type: average
      sql: ${usage_change_percent}
      value_format_name: percent_2
      drill_fields: detail*
    
    - measure: average_user_count_change_percent
      type: average
      sql: ${user_count_change}
      value_format_name: percent_2
      drill_fields: detail*
    
    - measure: average_lifetime_usage_minutes
      type: average
      sql: ${lifetime_usage_minutes}
      drill_fields: detail*
    
    - measure: total_usage
      type: sum
      sql: ${approximate_usage_minutes}
      drill_fields: detail*
      html: |
        {% if value <= 2000 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value <= 6000 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}

    - measure: average_account_health
      type: average
      sql: ${account_health_score}
      value_format_name: decimal_2
      drill_fields: detail*
      html: |
        {% if value < 40 %}
          <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% elsif value < 70 %}
          <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% else %}
          <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% endif %}

    - measure: average_account_health_this_week
      type: average
      sql: ${account_health_score}
      value_format_name: decimal_2
      drill_fields: detail*
      filters:
        event_weeks_ago: 1
      html: |
        {% if value < 40 %}
          <div style="color: black; background-color: #dc7350; font-size: 100%; text-align:center">{{ value }}</div>
        {% elsif value < 70 %}
          <div style="color: black; background-color: #e9b404; font-size: 100%; text-align:center">{{ value }}</div>
        {% else %}
          <div style="color: black; background-color: #49cec1; font-size: 100%; text-align:center">{{ value }}</div>
        {% endif %}

    - measure: average_account_health_one_week_ago
      type: average
      sql: COALESCE(${account_health_score},0)
      value_format_name: decimal_2
      drill_fields: detail*
      filters:
        event_weeks_ago: 2
      html: |
        {% if value < 40 %}
          <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% elsif value < 70 %}
          <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% else %}
          <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% endif %}

    - measure: average_account_health_two_weeks_ago
      type: average
      sql: COALESCE(${account_health_score},0)
      value_format_name: decimal_2
      drill_fields: detail*
      filters:
        event_weeks_ago: 3
      html: |
        {% if value < 40 %}
          <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% elsif value < 70 %}
          <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% else %}
          <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% endif %}
  
    - measure: average_account_health_change
      type: number
      sql: ${average_account_health_this_week} - COALESCE(${average_account_health_one_week_ago},${average_account_health_two_weeks_ago})
      drill_fields: detail*

    - measure: average_account_health_this_month
      type: average
      sql: ${account_health_score}
      value_format_name: decimal_2
      drill_fields: detail*
      filters:
        event_months_ago: 1
      html: |
        {% if value < 40 %}
          <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% elsif value < 70 %}
          <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% else %}
          <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% endif %}

    - measure: average_account_health_one_month_ago
      type: average
      sql: COALESCE(${account_health_score},0)
      value_format_name: decimal_2
      drill_fields: detail*
      filters:
        event_months_ago: 2
      html: |
        {% if value < 40 %}
          <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% elsif value < 70 %}
          <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% else %}
          <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% endif %}

    - measure: average_account_health_two_months_ago
      type: average
      sql: COALESCE(${account_health_score},0)
      value_format_name: decimal_2
      drill_fields: detail*
      filters:
        event_months_ago: 3
      html: |
        {% if value < 40 %}
          <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% elsif value < 70 %}
          <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% else %}
          <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
        {% endif %}
  
    - measure: average_account_health_change_MoM
      type: number
      sql: ${average_account_health_this_month} - COALESCE(${average_account_health_one_month_ago},${average_account_health_two_months_ago})
      drill_fields: detail*

    - measure: count_of_red_accounts
      type: count_distinct
      sql: ${account_id}
      sql_distinct_key: ${account_id}
      drill_fields: detail*
      filters:
        account_health_score: '< 40'
    
    - measure: percent_red_accounts
      type: number
      sql: 1.0 * ${count_of_red_accounts} / NULLIF(${count_of_accounts},0)
      value_format_name: percent_2
      drill_fields: detail*

### COUNT BY WEEK
    - measure: total_count_of_query_runs
      type: sum
      sql: ${count_of_query_runs}
      drill_fields: detail*
      html: |
        {% if value <= 10 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value <= 20 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}

    - measure: total_count_of_git_commits
      type: sum
      sql: ${count_of_git_commits}
      drill_fields: detail*
      html: |
        {% if value <= 10 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value <= 20 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}

    - measure: total_count_of_api_calls
      type: sum
      sql: ${count_of_api_calls}
      drill_fields: detail*
      html: |
        {% if value <= 10 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value <= 20 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}
  
    - measure: total_count_of_query_result_downloads
      type: sum
      sql: ${count_of_query_result_downloads}
      drill_fields: detail*
      html: |
        {% if value <= 10 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value <= 20 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}

    - measure: total_count_of_logins
      type: sum
      sql: ${count_of_logins}
      drill_fields: detail*
      html: |
        {% if value <= 10 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value <= 20 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}

    - measure: total_count_of_dashboard_queries
      type: sum
      sql: ${count_of_dashboard_queries}
      drill_fields: detail*
      html: |
        {% if value <= 10 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value <= 20 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}

    - measure: total_count_of_dashboard_downloads
      type: sum
      sql: ${count_of_dashboard_downloads}
      drill_fields: detail*
      html: |
        {% if value <= 10 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value <= 20 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}

    - measure: total_count_of_support_chats
      type: sum
      sql: ${count_of_support_chats}
      drill_fields: detail*
      html: |
        {% if value <= 10 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value <= 20 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}

    - measure: cumulative_weekly_users
      type: sum
      sql: ${current_weekly_users}
      html: |
        {% if value <= 10 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value <= 20 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}
  
  
  ### PERCENT CHANGES ###
    - measure: latest_usage_change_percent
      type: average
      sql: ${usage_change_percent}
      value_format_name: percent_2
      drill_fields: detail*
      filters:
        event_weeks_ago: 0
      html: |
        {% if value <= 0.2 and value >= -0.2 %}
          <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value < -0.2 %}
          <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}


- view: events_in_past_180_days
  derived_table:
    sql: |
      select * from events
        WHERE ((events.event_at) >= (DATEADD(day,-179, DATE_TRUNC('day',GETDATE()) )) 
            AND (events.event_at) < (DATEADD(day,180, DATEADD(day,-187, DATE_TRUNC('day',GETDATE()) ) )))
        AND event_type IN ('run_query', 'create_project', 'git_commit', 'field_select', 'filter_add', 'view_sql', 'api_call', 'download_query_results', ' view_results', 'login', 'create_user')
    sql_trigger_value: SELECT DATE(DATE_ADD('hour', 1, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())))
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
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))
    sortkeys: [salesforce_account_id, user_id, created_at]
    distkey: salesforce_account_id
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
      
  fields:
    - dimension: salesforce_account_id
      sql: ${TABLE}.salesforce_account_id

    - dimension: created
      type: time
      timeframes: [time, date, week, month, year]
      sql: ${TABLE}.created_at
      
    - dimension: license_id
      sql: ${TABLE}.license_id
      
    - dimension: user_id
      sql: ${TABLE}.user_id
      
    - dimension: idle_time
      type: number
      sql: ${TABLE}.idle_time
      

- view: sessions
  derived_table:
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))
    distkey: license_id
    sortkeys: [unique_session_id, session_start, account_id, user_id, license_id]
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
    sortkeys: [unique_session_id, event_id, created_at]
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
    sortkeys: [unique_session_id, session_start, user_id]
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
    
    
    