- view: usage
  derived_table:
    sql: |
      WITH first_pass AS (SELECT license.salesforce_account_id
                            , COUNT(*) AS lifetime_events
                            , COUNT(DISTINCT user_id || instance_slug || (FLOOR((DATE_PART(EPOCH, event_at)::BIGINT)/(60*5))))*5 AS approximate_usage_in_minutes_lifetime
                            , COUNT(DISTINCT 
                                    CASE
                                      WHEN event_at BETWEEN CURRENT_DATE - INTERVAL '60 day' AND CURRENT_DATE - INTERVAL '30 day'
                                      THEN user_id || instance_slug || (FLOOR((DATE_PART(EPOCH, event_at)::BIGINT)/(60*5)))
                                      ELSE NULL
                                    END
                                    )*5 AS approximate_usage_in_minutes_sixty_to_thirty_days
                            , COUNT(DISTINCT 
                                    CASE
                                      WHEN event_at >= CURRENT_DATE - INTERVAL '30 day'
                                      THEN user_id || instance_slug || (FLOOR((DATE_PART(EPOCH, event_at)::BIGINT)/(60*5)))
                                      ELSE NULL
                                    END
                                    )*5 AS approximate_usage_in_minutes_thirty_days
                            , COUNT(DISTINCT 
                                    CASE
                                      WHEN event_at >= CURRENT_DATE - INTERVAL '7 day'
                                      THEN user_id || instance_slug || (FLOOR((DATE_PART(EPOCH, event_at)::BIGINT)/(60*5)))
                                      ELSE NULL
                                    END
                                    )*5 AS approximate_usage_in_minutes_seven_days
                            , COUNT(DISTINCT 
                                    CASE
                                      WHEN event_at BETWEEN CURRENT_DATE - INTERVAL '1 day' AND CURRENT_DATE
                                      THEN user_id || instance_slug || (FLOOR((DATE_PART(EPOCH, event_at)::BIGINT)/(60*5)))
                                      ELSE NULL
                                    END
                                    )*5 AS approximate_usage_in_minutes_yesterday
                            , SUM(CASE
                                      WHEN event_at >= CURRENT_DATE - INTERVAL '30 day'
                                      THEN 1
                                      ELSE 0
                                    END) AS events_past_thirty_days
                            , COUNT(CASE
                                      WHEN event_at >= CURRENT_DATE - INTERVAL '7 day'
                                      THEN 1
                                      ELSE NULL
                                    END) AS events_past_seven_days
                            , COUNT(CASE
                                      WHEN event_at BETWEEN CURRENT_DATE - INTERVAL '1 day' AND CURRENT_DATE
                                      THEN 1
                                      ELSE NULL
                                    END) AS events_yesterday
                            , COUNT(DISTINCT user_id || instance_slug) AS total_current_users
                            , COUNT(DISTINCT 
                                      CASE
                                        WHEN event_at < CURRENT_DATE - INTERVAL '30 day'
                                        THEN user_id || instance_slug
                                        ELSE NULL
                                      END) AS total_users_thirty_days_ago
                            , COUNT(DISTINCT TO_CHAR(event_at, 'YYYY-MM')) AS unique_months_with_events
                          FROM events
                          LEFT JOIN license
                          ON events.license_slug = license.license_slug
                          GROUP BY 1)
      , max_user_usage AS ( SELECT salesforce_account_id
                              , MAX(user_usage) AS max_user_usage
                            FROM (SELECT license.salesforce_account_id
                                    , user_id
                                    , instance_slug
                                    , COUNT(DISTINCT user_id || instance_slug || (FLOOR((DATE_PART(EPOCH, event_at)::BIGINT)/(60*5))))*5 user_usage
                                  FROM events
                                  LEFT JOIN license
                                  ON events.license_slug = license.license_slug
                                  GROUP BY 1,2,3) AS a
                            GROUP BY 1)
      SELECT first_pass.salesforce_account_id
        , lifetime_events
        , approximate_usage_in_minutes_lifetime
        , approximate_usage_in_minutes_thirty_days
        , approximate_usage_in_minutes_seven_days
        , approximate_usage_in_minutes_yesterday
        ,  100.00 * (approximate_usage_in_minutes_thirty_days - approximate_usage_in_minutes_sixty_to_thirty_days) / NULLIF(approximate_usage_in_minutes_sixty_to_thirty_days, 0) AS percent_change_usage
        , PERCENT_RANK() 
          OVER(ORDER BY 100.00 * (approximate_usage_in_minutes_thirty_days - approximate_usage_in_minutes_sixty_to_thirty_days) / NULLIF(approximate_usage_in_minutes_sixty_to_thirty_days, 0)) AS usage_change_percentile
        , events_past_thirty_days
        , events_past_seven_days
        , events_yesterday
        , total_current_users
        , 100.00 * (total_current_users - total_users_thirty_days_ago) / NULLIF(total_users_thirty_days_ago, 0) AS percent_change_users
        , PERCENT_RANK()
          OVER(ORDER BY 100.00 * (total_current_users - total_users_thirty_days_ago) / NULLIF(total_users_thirty_days_ago, 0)) AS user_change_percentile
        , unique_months_with_events
        , 1.00 * max_user_usage.max_user_usage / NULLIF(approximate_usage_in_minutes_lifetime, 0) AS concentration
      FROM first_pass
      LEFT JOIN max_user_usage
      ON max_user_usage.salesforce_account_id = first_pass.salesforce_account_id
    sql_trigger_value: SELECT COUNT(*) FROM events
    distkey: salesforce_account_id
    sortkeys: [salesforce_account_id]
  fields:

# DIMENSIONS #

  - dimension: salesforce_account_id
    hidden: true
    primary_key: true
    sql: ${TABLE}.salesforce_account_id

  - dimension: unique_months_with_events
    type: number
    sql: ${TABLE}.unique_months_with_events
    
  - dimension: lifetime_events
    type: number
    sql: ${TABLE}.lifetime_events
    
  - dimension: concentration
    type: number
    value_format: '#.0%'
    sql: ROUND(${TABLE}.concentration, 2)
    
  - dimension: percent_change_usage
    type: number
    value_format: '#.0%'
    sql: ${TABLE}.percent_change_usage
    
  - dimension: usage_change_percentile
    type: number
    value_format: '#.0%'
    sql: ${TABLE}.usage_change_percentile    
    
  - dimension: percent_change_users
    type: number
    value_format_name: decimal_2
    sql: ${TABLE}.percent_change_users
    
  - dimension: user_change_percentile
    type: number
    value_format: '#.0%'
    sql: ${TABLE}.user_change_percentile
    
  - dimension: approximate_usage_in_minutes_lifetime
    type: number
    sql: ${TABLE}.approximate_usage_in_minutes_lifetime
    
  - dimension: account_health_slack_code
    sql: |
      CASE
        WHEN ${account_health} = 'At Risk' THEN ':cold_sweat:'
        WHEN ${account_health} = 'Safe' THEN ':smile:'
        WHEN ${account_health} = 'Solid' THEN ':sunglasses:'
        ELSE ':no_mouth:'
      END
      
  - dimension: account_health
    sql: |
      case
              when ${TABLE}.approximate_usage_in_minutes_lifetime <= 0
                      then 'At Risk'
              else (
                      case
                              when ${TABLE}.usage_change_percentile < 0.10
                                      then 'At Risk'
                              when ${TABLE}.usage_change_percentile < 0.50
                                              and ${TABLE}.concentration > 0.80
                                              and ${TABLE}.total_current_users > 10
                                      then 'At Risk'
                              when ${TABLE}.usage_change_percentile < 0.50
                                      then 'Safe'
                              when ${TABLE}.concentration > 0.80
                                              and ${TABLE}.total_current_users > 10
                                      then 'Safe'
                              else 'Solid'
                      end
              )
      end


    html: |
    html: |
        {% if value == 'At Risk' %}
          <b><p style="color: white; background-color: #dc7350; font-size:100%; text-align:center; margin: 0; border-radius: 5px;">{{ rendered_value }}</p></b>
        {% elsif value == 'Safe' %}
          <b><p style="color: black; background-color: #e9b404; font-size:100%; text-align:center; margin: 0; border-radius: 5px;">{{ rendered_value }}</p></b>
        {% else %}
          <b><p style="color: white; background-color: #49cec1; font-size:100%; text-align:center; margin: 0; border-radius: 5px;">{{ rendered_value }}</p></b>
        {% endif %}
                              
    
# MEASURES #

  - measure: count
    type: count
    
  - measure: total_events
    type: sum
    sql: ${lifetime_events}

  - measure: approximate_usage_in_minutes_total
    label: Total Usage Time (Min)
    type: sum
    sql: ${TABLE}.approximate_usage_in_minutes_lifetime
    drill_fields: [opportunity.id, account.name, approximate_usage_in_minutes_total]

  - measure: approximate_usage_in_minutes_thirty_days
    type: sum
    sql: ${TABLE}.approximate_usage_in_minutes_thirty_days

  - measure: approximate_usage_in_minutes_seven_days
    type: sum
    sql: ${TABLE}.approximate_usage_in_minutes_seven_days

  - measure: approximate_usage_in_minutes_yesterday
    type: sum
    sql: ${TABLE}.approximate_usage_in_minutes_yesterday

  - measure: total_events_past_thirty_days
    type: sum
    sql: ${TABLE}.events_past_thirty_days

  - measure: total_events_past_seven_days
    type: sum
    sql: ${TABLE}.events_past_seven_days

  - measure: total_events_yesterday
    type: sum
    sql: ${TABLE}.events_yesterday

  - measure: total_current_users
    type: sum
    sql: ${TABLE}.total_current_users
    
# SETS #

  sets:
    detail:
      - salesforce_account_id
      - lifetime_events
      - approximate_usage_in_minutes_lifetime
      - approximate_usage_in_minutes_thirty_days
      - approximate_usage_in_minutes_seven_days
      - approximate_usage_in_minutes_yesterday
      - events_past_thirty_days
      - events_past_seven_days
      - events_yesterday
      - total_current_users
      - unique_months_with_events