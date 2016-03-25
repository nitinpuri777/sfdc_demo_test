- view: max_user_usage
  derived_table:
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
    sql_trigger_value: SELECT CURRENT_DATE()
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
        , FLOOR(((DATE_PART(EPOCH, DATE_TRUNC('week', event_at))::BIGINT)/(60*5)) / (7 * COUNT(DISTINCT user_id || instance_slug))) AS approximate_usage_minutes
        , SUM(FLOOR(((DATE_PART(EPOCH, DATE_TRUNC('week', event_at))::BIGINT)/(60*5)) / (7 * COUNT(DISTINCT user_id || instance_slug)))) OVER (PARTITION BY account_id ORDER BY event_week ROWS UNBOUNDED PRECEDING) as lifetime_usage_minutes
        , LAG((FLOOR((DATE_PART(EPOCH, DATE_TRUNC('week', event_at))::BIGINT)/(60*5))) / (7 * COUNT(DISTINCT user_id || instance_slug)), 1) OVER (PARTITION BY account_id ORDER BY event_week) AS last_week_usage_minutes
        , 1.00 * AVG(max_user_usage.max_user_usage) / NULLIF((FLOOR((DATE_PART(EPOCH, DATE_TRUNC('week', event_at))::BIGINT)/(60*5))) / (7 * COUNT(DISTINCT user_id || instance_slug)), 0) AS concentration
      FROM events
      INNER JOIN license ON events.license_slug = license.license_slug
      LEFT JOIN ${max_user_usage.SQL_TABLE_NAME} AS max_user_usage ON max_user_usage.salesforce_account_id = license.salesforce_account_id
      GROUP BY 1, 2
      
  fields:
  
  ### DIMENSIONS ###
    - dimension: unique_key
      hidden: true
      primary_key: true
      sql: ${account_id} || '-' || ${event_week}
    
    - dimension: account_id
      sql: ${TABLE}.account_id
    
    - dimension: concentration
      type: number
      sql: ${TABLE}.concentration

    - dimension: last_week_events
      type: number
      sql: ${TABLE}.last_week_events

    - dimension: event
      type: time
      timeframes: [raw, week, month]
      sql: ${TABLE}.event_week

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
    
  ### DERIVED DIMENSIONS ###
    - dimension: weeks_since_signup
      type: number
      sql: DATEDIFF('week',${opportunity.closed_raw}, ${event_raw})
    
    - dimension: weeks_ago
      type: number
      sql: DATEDIFF(week, ${event_raw}, DATE_TRUNC('week',CURRENT_DATE))-1
      
    - dimension: usage_change_percent
      type: number
      sql: 1.0 * (${approximate_usage_minutes} - ${last_week_usage_minutes}) / NULLIF(${last_week_usage_minutes},0)
      value_format_name: percent_2

    - dimension: user_count_change
      type: number
      sql: 1.0* (${current_weekly_users} - ${last_week_users}) / NULLIF(${last_week_users},0)
    
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
          WHEN ${account_health_score} < 50 THEN 'At Risk'
          WHEN ${account_health_score} < 70 THEN 'Safe'
          WHEN ${account_health_score} >= 70 THEN 'Solid'
          ELSE 'NA'
        END
      html: |
        {% if value == 'At Risk' %}
          <b><p style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</p></b>
        {% elsif value == 'Safe' %}
          <b><p style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</p></b>
        {% else %}
          <b><p style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</p></b>
        {% endif %}
  
  ### MEASURES ###
    - measure: count_of_accounts
      type: count_distinct
      sql: ${account_id}

    - measure: average_event_count
      type: average
      sql: ${weekly_event_count}
      value_format_name: decimal_2
    
    - measure: average_current_weekly_users
      type: average
      sql: ${current_weekly_users}
      value_format_name: decimal_2
    
    - measure: average_concentration
      type: average
      sql: ${concentration}
      value_format_name: percent_2
    
    - measure: average_usage_change_percent
      description: usage change by week
      type: average
      sql: ${usage_change_percent}
      value_format_name: percent_2
    
    - measure: average_user_count_change_percent
      type: average
      sql: ${user_count_change}
      value_format_name: percent_2
    
    - measure: average_lifetime_usage_minutes
      type: average
      sql: ${lifetime_usage_minutes}
    
    - measure: total_usage
      type: sum
      sql: ${approximate_usage_minutes}

    - measure: average_account_health
      type: average
      sql: ${account_health_score}
      value_format_name: decimal_2
      html: |
        {% if value < 50 %}
          <b><p style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</p></b>
        {% elsif value < 70 %}
          <b><p style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</p></b>
        {% else %}
          <b><p style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</p></b>
        {% endif %}

  sets:
    export_set:
      - account_id
      - weeks_ago
      - weeks_since_signup
      - event_week
      - event_month
      - account_health_score
      - account_health
      - count_of_accounts
      - average_account_health
      - total_usage
      - usage_change_percent
      - user_count_change
      - average_user_count_change_percent
      - average_usage_change_percent