- view: max_user_usage
  derived_table:
    persist_for: 6 hours
    distkey: salesforce_account_id
    sortkeys: [salesforce_account_id]
    sql: |
      SELECT
          salesforce_account_id
        , MAX(user_usage) AS max_user_usage
        FROM (
          SELECT license.salesforce_account_id
            , user_id
            , instance_slug
            , COUNT(DISTINCT user_id || instance_slug || (FLOOR((DATE_PART(EPOCH, event_at)::BIGINT)/(60*5))))*5 user_usage
          FROM events
          INNER JOIN license
          ON events.license_slug = license.license_slug
          GROUP BY 1,2,3
          )
      GROUP BY 1

- view: account_weekly_usage
  derived_table:
    # Rebuilds at 11PM on Sundays
    sql_trigger_value: SELECT DATE_TRUNC('week', DATE_ADD('hour', 1, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())))
    distkey: account_id
    sortkeys: [account_id, event_week]
    sql: |
      SELECT
          license.salesforce_account_id AS account_id
        , DATE_TRUNC('week', event_at) AS event_week
        , COUNT(DISTINCT user_id || instance_slug) AS total_weekly_users
        , LAG(COUNT(DISTINCT user_id || instance_slug), 1) OVER (PARTITION BY account_id ORDER BY event_week) AS last_week_users
        , COUNT(DISTINCT events.id) AS weekly_event_count
        , LAG(COUNT(DISTINCT events.id), 1) OVER (PARTITION BY account_id ORDER BY event_week) AS last_week_events
        , FLOOR(((DATE_PART(EPOCH, DATE_TRUNC('week', event_at))::BIGINT)/(60*5)) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0)) AS approximate_usage_minutes
        , SUM(FLOOR(((DATE_PART(EPOCH, DATE_TRUNC('week', event_at))::BIGINT)/(60*5)) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0))) OVER (PARTITION BY account_id ORDER BY event_week ROWS UNBOUNDED PRECEDING) as lifetime_usage_minutes
        , LAG((FLOOR((DATE_PART(EPOCH, DATE_TRUNC('week', event_at))::BIGINT)/(60*5))) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0), 1) OVER (PARTITION BY account_id ORDER BY event_week) AS last_week_usage_minutes
        , 1.00 * AVG(max_user_usage.max_user_usage) / NULLIF((FLOOR((DATE_PART(EPOCH, DATE_TRUNC('week', event_at))::BIGINT)/(60*5))) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0), 0) AS concentration
        , SUM(CASE WHEN events.event_type = 'run_query' THEN 1 ELSE 0 END) AS count_of_query_runs
        , SUM(CASE WHEN events.event_type = 'create_project' THEN 1 ELSE 0 END) AS count_of_project_creation
        , SUM(CASE WHEN events.event_type = 'git_commit' THEN 1 ELSE 0 END) AS count_of_git_commits
        , SUM(CASE WHEN events.event_type = 'api_call' THEN 1 ELSE 0 END) AS count_of_api_calls
        , SUM(CASE WHEN events.event_type = 'download_query_results' THEN 1 ELSE 0 END) AS count_of_query_result_downloads
        , SUM(CASE WHEN events.event_type = 'login' THEN 1 ELSE 0 END) AS count_of_logins
        , SUM(CASE WHEN events.event_type = 'run_dashboard' THEN 1 ELSE 0 END) AS count_of_dashboard_queries
        , SUM(CASE WHEN events.event_type = 'open_dashboard_pdf' THEN 1 ELSE 0 END) AS count_of_dashboard_downloads
        , SUM(CASE WHEN events.event_type = 'close_zopim_chat' THEN 1 ELSE 0 END) AS count_of_support_chats
      FROM events
      INNER JOIN license ON events.license_slug = license.license_slug
      LEFT JOIN ${max_user_usage.SQL_TABLE_NAME} AS max_user_usage ON max_user_usage.salesforce_account_id = license.salesforce_account_id
      GROUP BY 1, 2, 3, 4
      
  fields:
  
  ### DIMENSIONS ###
    - dimension: unique_key
      hidden: true
      primary_key: true
      sql: ${account_id} || '-' || ${event_week} || '-' || ${event_weeks_ago} || '-' || ${event_months_ago}
    
    - dimension: account_id
      sql: ${TABLE}.account_id
    
    - dimension: concentration
      type: number
      sql: ${TABLE}.concentration

    - dimension: last_week_events
      type: number
      sql: ${TABLE}.last_week_events

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
    
    - dimension: lifetime_usage_minutes
      type: number
      sql: ${TABLE}.lifetime_usage_minutes
    
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
    - dimension: weeks_since_signup
      type: number
      sql: DATEDIFF('week',${opportunity.closed_raw}, ${event_raw})
    
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

    - dimension: concentration_score
      type: number
      sql: |
        CASE
          WHEN ${concentration} IN (0, NULL) THEN 0.0
          WHEN ${concentration} <= 0.1 THEN 10.0
          WHEN ${concentration} <= 0.3 THEN 8.5
          WHEN ${concentration} <= 0.5  THEN 7.0
          WHEN ${concentration} <= 0.7  THEN 5.5
          WHEN ${concentration} <= 0.9  THEN 4.0
          WHEN ${concentration} <= 1.1 THEN 2.5
          WHEN ${concentration} > 1.1 THEN 1.0
          ELSE 4
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
      sql: 100.0 * (${usage_change_percent_score} + ${lifetime_usage_minutes_score} + ${concentration_score} + ${current_weekly_users_score}) / 35
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
      sql: ${account_id}
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
    
    - measure: average_concentration
      type: average
      sql: ${concentration}
      value_format_name: percent_2
      drill_fields: detail*
      html: |
        {% if value <= 0.2 and value >= -0.2 %}
          <div style="color: black; background-color: goldenrod; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% elsif value > 0.2 %}
          <div style="color: white; background-color: darkred; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% else %}
          <div style="color: white; background-color: darkgreen; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
        {% endif %}
    
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

  sets:
    detail:
      - account_id
      - account.name
      - average_account_health
      - average_account_health_change
      - total_usage
    
    export_set:
      - account_id
#       - weeks_ago
      - event_weeks_ago
      - event_months_ago
      - weeks_since_signup
#       - months_ago
      - event_week
      - event_month
      - account_health_score
      - account_health
      - total_usage
      - usage_change_percent
      - user_count_change
      - average_user_count_change_percent
      - average_usage_change_percent
      - count_of_query_runs
      - count_of_git_commits
      - count_of_api_calls
      - count_of_query_result_downloads
      - count_of_logins
      - count_of_dashboard_queries
      - count_of_dashboard_downloads
      - count_of_support_chats
      - total_count_of_query_runs
      - total_count_of_git_commits
      - total_count_of_api_calls
      - total_count_of_query_result_downloads
      - total_count_of_logins
      - total_count_of_dashboard_queries
      - total_count_of_dashboard_downloads
      - total_count_of_support_chats
      - count_of_accounts
      - average_account_health
      - average_account_health_this_week
      - average_account_health_one_week_ago
      - average_account_health_two_weeks_ago
      - average_account_health_change
      - count_of_red_accounts
      - percent_red_accounts
      - average_account_health_change_MoM



