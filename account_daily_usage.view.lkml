view: max_user_usage {
  derived_table: {
    persist_for: "6 hours"
    distribution: "salesforce_account_id"
    sortkeys: ["salesforce_account_id"]
    sql: SELECT
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
       ;;
  }
}

view: daily_event_rollup {
  derived_table: {
    sql: SELECT
        DATE(event_at) AS event_date
        , license_slug AS license_slug
        , instance_slug AS instance_slug
        , user_id AS user_id
        , license_slug || '-' || instance_slug || '-' || user_id AS instance_user_id
        , event_type AS event_type
        , ROW_NUMBER() OVER () AS unique_key
        , COUNT(*) AS count_of_events
        , SUM(CASE WHEN event_type = 'run_query' THEN 1 ELSE 0 END) AS count_of_query_runs
        , SUM(CASE WHEN event_type = 'create_project' THEN 1 ELSE 0 END) AS count_of_project_creation
        , SUM(CASE WHEN event_type = 'git_commit' THEN 1 ELSE 0 END) AS count_of_git_commits
        , SUM(CASE WHEN event_type = 'open_dashboard_pdf' THEN 1 ELSE 0 END) AS count_of_dashboard_downloads
        , SUM(CASE WHEN event_type = 'api_call' THEN 1 ELSE 0 END) AS count_of_api_calls
        , SUM(CASE WHEN event_type = 'download_query_results' THEN 1 ELSE 0 END) AS count_of_query_result_downloads
        , SUM(CASE WHEN event_type = 'login' THEN 1 ELSE 0 END) AS count_of_logins
        , SUM(CASE WHEN event_type = 'run_dashboard' THEN 1 ELSE 0 END) AS count_of_dashboard_queries
        , SUM(CASE WHEN event_type = 'close_zopim_chat' THEN 1 ELSE 0 END) AS count_of_support_chats
      FROM events
      WHERE event_type IN ('run_query', 'create_project', 'git_commit', 'open_dashboard_pdf', 'api_call', 'download_query_results', 'login', 'run_dashboard', 'close_zopim_chat')
      GROUP BY 1, 2, 3, 4, 5, 6
       ;;
    sql_trigger_value: SELECT DATE(DATE_ADD('hour', 3, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))) ;;
    distribution: "license_slug"
    sortkeys: ["license_slug", "instance_slug", "user_id", "event_type"]
  }

  dimension: id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.unique_key ;;
  }

  dimension: instance_user_id {
    type: string
    sql: RIGHT(${TABLE}.instance_user_id, 8) ;;
  }

  dimension_group: event {
    type: time
    timeframes: [raw, date, week, month]
    sql: ${TABLE}.event_date ;;
  }

  dimension: event_weeks_ago {
    type: number
    sql: DATE_DIFF('week', ${event_raw}, DATE_TRUNC('week', CURRENT_DATE)) ;;
  }

  dimension: event_months_ago {
    type: number
    sql: DATE_DIFF('month', ${event_raw}, DATE_TRUNC('month', CURRENT_DATE)) ;;
  }

  dimension: event_type {
    type: string
    sql: ${TABLE}.event_type ;;
  }

  dimension: instance_slug {
    type: string
    hidden: yes
    sql: ${TABLE}.instance_slug ;;
  }

  dimension: license_slug {
    type: string
    hidden: yes
    sql: ${TABLE}.license_slug ;;
  }

  dimension: user_id {
    type: string
    hidden: yes
    sql: ${TABLE}.user_id ;;
  }

  dimension: number_of_events {
    type: number
    sql: ${TABLE}.count_of_events ;;
  }

  dimension: number_of_query_runs {
    type: number
    sql: ${TABLE}.count_of_query_runs ;;
  }

  dimension: number_of_project_creation {
    type: number
    hidden: yes
    sql: ${TABLE}.count_of_project_creation ;;
  }

  dimension: number_of_git_commits {
    type: number
    hidden: yes
    sql: ${TABLE}.count_of_git_commits ;;
  }

  dimension: number_of_api_calls {
    type: number
    hidden: yes
    sql: ${TABLE}.count_of_api_calls ;;
  }

  dimension: number_of_query_result_downloads {
    type: number
    hidden: yes
    sql: ${TABLE}.count_of_query_result_downloads ;;
  }

  dimension: number_of_logins {
    type: number
    hidden: yes
    sql: ${TABLE}.count_of_logins ;;
  }

  dimension: number_of_dashboard_queries {
    type: number
    hidden: yes
    sql: ${TABLE}.count_of_dashboard_queries ;;
  }

  dimension: number_of_dashboard_downloads {
    type: number
    hidden: yes
    sql: ${TABLE}.count_of_dashboard_downloads ;;
  }

  dimension: number_of_support_chats {
    type: number
    hidden: yes
    sql: ${TABLE}.count_of_support_chats ;;
  }

  ### MEASURES ###

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  measure: user_count {
    type: count_distinct
    sql: ${instance_user_id} ;;
    description: "A count of unique users per instance calculated based on instance_user_id."
    drill_fields: [detail*]
  }

  measure: count_of_licenses {
    type: count_distinct
    sql: ${license_slug} ;;
    drill_fields: [detail*]
  }

  measure: count_of_instances {
    type: count_distinct
    sql: ${instance_slug} ;;
    drill_fields: [detail*]
  }

  measure: users_per_instance {
    type: number
    sql: ${user_count} / ${count_of_instances} ;;
    value_format_name: decimal_2
    drill_fields: [detail*]
  }

  measure: total_query_runs {
    type: sum
    sql: ${number_of_query_runs} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_project_creation {
    type: sum
    sql: ${number_of_project_creation} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_git_commits {
    type: sum
    sql: ${number_of_git_commits} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_api_calls {
    type: sum
    sql: ${number_of_api_calls} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_query_result_downloads {
    type: sum
    sql: ${number_of_query_result_downloads} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_logins {
    type: sum
    sql: ${number_of_logins} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_dashboard_queries {
    type: sum
    sql: ${number_of_dashboard_queries} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_dashboard_downloads {
    type: sum
    sql: ${number_of_dashboard_downloads} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_support_chats {
    type: sum
    sql: ${number_of_support_chats} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  ### DATE FILTERED MEASURES ###

  measure: count_of_query_runs_last_week {
    type: sum
    sql: ${number_of_query_runs} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_project_creation_last_week {
    type: sum
    sql: ${number_of_project_creation} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_git_commits_last_week {
    type: sum
    sql: ${number_of_git_commits} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_api_calls_last_week {
    type: sum
    sql: ${number_of_api_calls} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_query_result_downloads_last_week {
    type: sum
    sql: ${number_of_query_result_downloads} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_logins_last_week {
    type: sum
    sql: ${number_of_logins} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_dashboard_queries_last_week {
    type: sum
    sql: ${number_of_dashboard_queries} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_dashboard_downloads_last_week {
    type: sum
    sql: ${number_of_dashboard_downloads} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_support_chats_last_week {
    type: sum
    sql: ${number_of_support_chats} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: user_count_last_week {
    type: count_distinct
    sql: ${instance_user_id} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }
  }

  measure: user_count_two_weeks_ago {
    type: count_distinct
    sql: ${instance_user_id} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }
  }

  measure: count_of_query_runs_two_weeks_ago {
    type: sum
    sql: ${number_of_query_runs} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_project_creation_two_weeks_ago {
    type: sum
    sql: ${number_of_project_creation} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_git_commits_two_weeks_ago {
    type: sum
    sql: ${number_of_git_commits} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_api_calls_two_weeks_ago {
    type: sum
    sql: ${number_of_api_calls} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_query_result_downloads_two_weeks_ago {
    type: sum
    sql: ${number_of_query_result_downloads} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_logins_two_weeks_ago {
    type: sum
    sql: ${number_of_logins} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_dashboard_queries_two_weeks_ago {
    type: sum
    sql: ${number_of_dashboard_queries} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_dashboard_downloads_two_weeks_ago {
    type: sum
    sql: ${number_of_dashboard_downloads} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: count_of_support_chats_two_weeks_ago {
    type: sum
    sql: ${number_of_support_chats} ;;
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }

    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  ### COMPOSITE MEASURES ###

  measure: usage_minutes {
    type: number
    value_format_name: decimal_2
    drill_fields: [detail*]
    sql: 1.0 * (${total_dashboard_queries} * 10
      + ${total_dashboard_downloads} * 5
      + ${total_support_chats} * 10
      + ${total_query_runs} * 3
      + ${total_project_creation} * 5
      + ${total_git_commits} * 5
      + ${total_api_calls} * 3
      + ${total_query_result_downloads} * 5
      + ${total_logins} * 3) / 3600
       ;;
  }

  measure: usage_minutes_last_week {
    type: number
    value_format_name: decimal_2
    drill_fields: [detail*]
    sql: 1.0 * (${count_of_dashboard_queries_last_week} * 10
      + ${count_of_dashboard_downloads_last_week} * 5
      + ${count_of_support_chats_last_week} * 10
      + ${count_of_query_runs_last_week} * 3
      + ${count_of_project_creation_last_week} * 5
      + ${count_of_git_commits_last_week} * 5
      + ${count_of_api_calls_last_week} * 3
      + ${count_of_query_result_downloads_last_week} * 5
      + ${count_of_logins_last_week} * 3) / 3600
       ;;
  }

  measure: usage_minutes_two_weeks_ago {
    type: number
    value_format_name: decimal_2
    drill_fields: [detail*]
    sql: 1.0 * (${count_of_dashboard_queries_two_weeks_ago} * 10
      + ${count_of_dashboard_downloads_two_weeks_ago} * 5
      + ${count_of_support_chats_two_weeks_ago} * 10
      + ${count_of_query_runs_two_weeks_ago} * 3
      + ${count_of_project_creation_two_weeks_ago} * 5
      + ${count_of_git_commits_two_weeks_ago} * 5
      + ${count_of_api_calls_two_weeks_ago} * 3
      + ${count_of_query_result_downloads_two_weeks_ago} * 5
      + ${count_of_logins_two_weeks_ago} * 3) / 3600
       ;;
  }

  set: detail {
    fields: [instance_user_id, event_weeks_ago, event_type, instance_slug, license_slug, total_logins , total_query_runs, total_git_commits, total_dashboard_queries]
  }
}

view: weekly_event_rollup {
  derived_table: {
    sql_trigger_value: SELECT DATE(DATE_ADD('hour', 1, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))) ;;
    distribution: "license_slug"
    sortkeys: ["event_week", "account_id", "license_slug"]
    sql: SELECT
        license.salesforce_account_id AS account_id
        , DATE_TRUNC('week', daily_event_rollup.event_date) AS event_week
        , daily_event_rollup.license_slug AS license_slug
        , SUM(count_of_dashboard_downloads) AS total_dashboard_downloads
        , SUM(count_of_dashboard_queries) AS total_dashboard_queries
        , SUM(count_of_git_commits) AS total_git_commits
        , SUM(count_of_logins) AS total_logins
        , SUM(count_of_project_creation) AS total_project_creation
        , SUM(count_of_query_result_downloads) AS total_query_result_downloads
        , SUM(count_of_query_runs) AS total_query_runs
        , SUM(count_of_support_chats) AS total_support_chats
        , SUM(count_of_api_calls) AS total_api_calls
        , COUNT(DISTINCT instance_user_id) AS total_weekly_users
        , LAG(COUNT(DISTINCT user_id || instance_slug), 1) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('week', daily_event_rollup.event_date)) AS last_week_users
        , FLOOR(((DATE_PART(EPOCH, DATE_TRUNC('week', daily_event_rollup.event_date))::BIGINT)/(60*5)) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0)) AS approximate_usage_minutes
        , LAG((FLOOR((DATE_PART(EPOCH, DATE_TRUNC('week', daily_event_rollup.event_date))::BIGINT)/(60*5))) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0), 1) OVER (PARTITION BY account_id ORDER BY event_week) AS last_week_usage_minutes
        , LAG(COUNT(DISTINCT user_id || instance_slug), 1) OVER (PARTITION BY daily_event_rollup.license_slug ORDER BY DATE_TRUNC('week', daily_event_rollup.event_date)) AS last_week_events
        , SUM(FLOOR(((DATE_PART(EPOCH, DATE_TRUNC('week', daily_event_rollup.event_date))::BIGINT)/(60*5)) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0))) OVER (PARTITION BY account_id ORDER BY event_week ROWS UNBOUNDED PRECEDING) as lifetime_usage_minutes
        , 1.00 * AVG(max_user_usage.max_user_usage) / NULLIF((FLOOR((DATE_PART(EPOCH, DATE_TRUNC('week', daily_event_rollup.event_date))::BIGINT)/(60*5))) / NULLIF((7 * COUNT(DISTINCT user_id || instance_slug)),0), 0) AS concentration
      FROM ${daily_event_rollup.SQL_TABLE_NAME} AS daily_event_rollup
      INNER JOIN license ON daily_event_rollup.license_slug = license.license_slug
      LEFT JOIN ${max_user_usage.SQL_TABLE_NAME} AS max_user_usage ON max_user_usage.salesforce_account_id = license.salesforce_account_id
      GROUP BY 1,2,3
       ;;
  }

  ### DIMENSIONS ###
  dimension: unique_key {
    hidden: yes
    primary_key: yes
    sql: ${license_slug} || '-' || ${event_raw} ;;
  }

  dimension: license_slug {
    type: string
    hidden: yes
    sql: ${TABLE}.license_slug ;;
  }

  dimension: account_id {
    type: string
    hidden: yes
    sql: ${TABLE}.account_id ;;
  }

  dimension: last_week_events {
    type: number
    sql: ${TABLE}.last_week_events ;;
  }

  dimension: lifetime_usage_minutes {
    type: number
    sql: ${TABLE}.lifetime_usage_minutes ;;
  }

  dimension: concentration {
    type: number
    sql: ${TABLE}.concentration ;;
  }

  dimension_group: event {
    type: time
    timeframes: [raw, week, month]
    sql: ${TABLE}.event_week ;;
  }

  dimension: event_weeks_ago {
    type: number
    sql: DATE_DIFF('week', ${event_raw}, DATE_TRUNC('week', CURRENT_DATE)) ;;
  }

  dimension: event_months_ago {
    type: number
    sql: DATE_DIFF('month', ${event_raw}, DATE_TRUNC('month', CURRENT_DATE)) ;;
  }

  dimension: weeks_since_signup {
    type: number
    sql: DATEDIFF('week',${opportunity.closed_raw}, ${event_raw}) ;;
  }

  dimension: current_weekly_users {
    type: number
    sql: ${TABLE}.total_weekly_users ;;
  }

  dimension: last_week_users {
    type: number
    sql: ${TABLE}.last_week_users ;;
  }

  dimension: weekly_event_count {
    sql: ${TABLE}.weekly_event_count ;;
  }

  dimension: approximate_usage_minutes {
    type: number
    sql: ${TABLE}.approximate_usage_minutes ;;
  }

  dimension: last_week_usage_minutes {
    type: number
    sql: ${TABLE}.last_week_usage_minutes ;;
  }

  dimension: weekly_query_runs {
    type: number
    sql: ${TABLE}.total_query_runs ;;
  }

  dimension: weekly_project_creation {
    type: number
    sql: ${TABLE}.total_project_creation ;;
  }

  dimension: weekly_git_commits {
    type: number
    sql: ${TABLE}.total_git_commits ;;
  }

  dimension: weekly_api_calls {
    type: number
    sql: ${TABLE}.total_api_calls ;;
  }

  dimension: weekly_query_result_downloads {
    type: number
    sql: ${TABLE}.total_query_result_downloads ;;
  }

  dimension: weekly_logins {
    type: number
    sql: ${TABLE}.total_logins ;;
  }

  dimension: weekly_dashboard_queries {
    type: number
    sql: ${TABLE}.total_dashboard_queries ;;
  }

  dimension: weekly_dashboard_downloads {
    type: number
    sql: ${TABLE}.total_dashboard_downloads ;;
  }

  dimension: weekly_support_chats {
    type: number
    sql: ${TABLE}.total_support_chats ;;
  }

  ### DERIVED DIMENSIONS ###
  dimension: usage_change_percent {
    type: number
    sql: COALESCE(1.0 * (${approximate_usage_minutes} - ${last_week_usage_minutes}) / NULLIF(${last_week_usage_minutes},0),0) ;;
    value_format_name: percent_2
  }

  dimension: user_count_change {
    type: number
    sql: 1.0* (${current_weekly_users} - ${last_week_users}) / NULLIF(${last_week_users},0) ;;
    html: {% if value <= 0.2 and value >= -0.2 %}
        <div style="color: black; background-color: goldenrod; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value < -0.2 %}
        <div style="color: white; background-color: darkred; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  dimension: usage_change_percent_score {
    type: number
    sql: CASE
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
       ;;
  }

  dimension: lifetime_usage_minutes_score {
    type: number
    sql: CASE
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
       ;;
  }

  dimension: concentration_score {
    type: number
    sql: CASE
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
       ;;
  }

  dimension: current_weekly_users_score {
    type: number
    sql: CASE
        WHEN ${current_weekly_users} IN (0, NULL) THEN 0
        WHEN ${current_weekly_users} <= 50 THEN 1
        WHEN ${current_weekly_users} <= 100  THEN 3
        WHEN ${current_weekly_users} > 100  THEN 5
        ELSE 3
      END
       ;;
  }

  dimension: account_health_score {
    type: number
    sql: 100.0 * (${usage_change_percent_score} + ${lifetime_usage_minutes_score} + ${concentration_score} + ${current_weekly_users_score}) / 35 ;;
    value_format_name: decimal_2
  }

  dimension: account_health {
    type: string
    sql: CASE
        WHEN ${account_health_score} < 50 THEN '1. At Risk'
        WHEN ${account_health_score} < 70 THEN '2. Standard'
        WHEN ${account_health_score} >= 70 THEN '3. Safe'
        ELSE 'NA'
      END
       ;;
    html: {% if value == '1. At Risk' %}
        <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% elsif value == '2. Standard' %}
        <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% else %}
        <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% endif %}
      ;;
  }

  ### MEASURES ###
  measure: count_of_accounts {
    type: count_distinct
    sql: ${account_id} ;;
    drill_fields: [account_detail*]
  }

  measure: average_event_count {
    type: average
    sql: ${weekly_event_count} ;;
    value_format_name: decimal_2
    drill_fields: [detail*]
  }

  measure: average_current_weekly_users {
    type: average
    sql: ${current_weekly_users} ;;
    value_format_name: decimal_2
    drill_fields: [detail*]
  }

  measure: average_usage_change_percent {
    description: "usage change by week"
    type: average
    sql: ${usage_change_percent} ;;
    value_format_name: percent_2
    drill_fields: [detail*]
  }

  measure: average_user_count_change_percent {
    type: average
    sql: ${user_count_change} ;;
    value_format_name: percent_2
    drill_fields: [detail*]
  }

  measure: average_lifetime_usage_minutes {
    type: average
    sql: ${lifetime_usage_minutes} ;;
    drill_fields: [detail*]
  }

  measure: total_usage {
    type: sum
    sql: ${approximate_usage_minutes} ;;
    drill_fields: [detail*]
    html: {% if value <= 2000 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 6000 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: average_account_health {
    type: average
    sql: ${account_health_score} ;;
    value_format_name: decimal_2
    drill_fields: [detail*]
    html: {% if value < 50 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value < 70 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: average_account_health_this_week {
    type: average
    sql: ${account_health_score} ;;
    value_format_name: decimal_2
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "1"
    }

    html: {% if value < 50 %}
        <div style="color: black; background-color: #dc7350; font-size: 100%; text-align:center">{{ value }}</div>
      {% elsif value < 70 %}
        <div style="color: black; background-color: #e9b404; font-size: 100%; text-align:center">{{ value }}</div>
      {% else %}
        <div style="color: black; background-color: #49cec1; font-size: 100%; text-align:center">{{ value }}</div>
      {% endif %}
      ;;
  }

  measure: average_account_health_one_week_ago {
    type: average
    sql: COALESCE(${account_health_score},0) ;;
    value_format_name: decimal_2
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "2"
    }

    html: {% if value < 50 %}
        <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% elsif value < 70 %}
        <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% else %}
        <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% endif %}
      ;;
  }

  measure: average_account_health_two_weeks_ago {
    type: average
    sql: COALESCE(${account_health_score},0) ;;
    value_format_name: decimal_2
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "3"
    }

    html: {% if value < 50 %}
        <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% elsif value < 70 %}
        <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% else %}
        <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% endif %}
      ;;
  }

  measure: average_account_health_change {
    type: number
    sql: ${average_account_health_this_week} - COALESCE(${average_account_health_one_week_ago},${average_account_health_two_weeks_ago}) ;;
    drill_fields: [account.name, average_account_health_this_week, average_account_health_one_week_ago, average_account_health_two_weeks_ago]
  }

  measure: average_account_health_this_month {
    type: average
    sql: ${account_health_score} ;;
    value_format_name: decimal_2
    drill_fields: [detail*]

    filters: {
      field: event_months_ago
      value: "1"
    }

    html: {% if value < 50 %}
        <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% elsif value < 70 %}
        <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% else %}
        <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% endif %}
      ;;
  }

  measure: average_account_health_one_month_ago {
    type: average
    sql: COALESCE(${account_health_score},0) ;;
    value_format_name: decimal_2
    drill_fields: [detail*]

    filters: {
      field: event_months_ago
      value: "2"
    }

    html: {% if value < 50 %}
        <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% elsif value < 70 %}
        <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% else %}
        <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% endif %}
      ;;
  }

  measure: average_account_health_two_months_ago {
    type: average
    sql: COALESCE(${account_health_score},0) ;;
    value_format_name: decimal_2
    drill_fields: [detail*]

    filters: {
      field: event_months_ago
      value: "3"
    }

    html: {% if value < 50 %}
        <div style="color: black; background-color: #dc7350; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% elsif value < 70 %}
        <div style="color: black; background-color: #e9b404; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% else %}
        <div style="color: black; background-color: #49cec1; margin: 0; border-radius: 5px; text-align:center">{{ value }}</div>
      {% endif %}
      ;;
  }

  measure: average_concentration_score {
    type: average
    sql: ${concentration_score} ;;
    description: "A score from 1-10 rating the distribution of usage amongst all users (higher is better)"
    drill_fields: [detail*]
    value_format: "0.0"
    html: {% if value <= 3 %}
        <div style="color: white; background-color: darkred; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 6 %}
        <div style="color: black; background-color: goldenrod; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; margin: 0; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: average_account_health_change_MoM {
    type: number
    sql: ${average_account_health_this_month} - COALESCE(${average_account_health_one_month_ago},${average_account_health_two_months_ago}) ;;
    drill_fields: [detail*]
  }

  measure: count_of_red_accounts {
    type: count_distinct
    sql: ${account_id} ;;
    drill_fields: [account_detail*]

    filters: {
      field: account_health
      value: "1. At Risk"
    }
  }

  measure: percent_red_accounts {
    type: number
    sql: 1.0 * ${count_of_red_accounts} / NULLIF(${count_of_accounts},0) ;;
    value_format_name: percent_1
    drill_fields: [account_detail*, account_health]
  }

  ### COUNT BY WEEK
  measure: total_count_of_query_runs {
    type: sum
    sql: ${weekly_query_runs} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_count_of_git_commits {
    type: sum
    sql: ${weekly_git_commits} ;;
    drill_fields: [detail*]
    html: {% if value <= 5 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 10 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_count_of_api_calls {
    type: sum
    sql: ${weekly_api_calls} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_count_of_query_result_downloads {
    type: sum
    sql: ${weekly_query_result_downloads} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_count_of_logins {
    type: sum
    sql: ${weekly_logins} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_count_of_dashboard_queries {
    type: sum
    sql: ${weekly_dashboard_queries} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_count_of_dashboard_downloads {
    type: sum
    sql: ${weekly_dashboard_downloads} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 15 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: total_count_of_support_chats {
    type: sum
    sql: ${weekly_support_chats} ;;
    drill_fields: [detail*]
    html: {% if value >= 20 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value >= 10 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  measure: cumulative_weekly_users {
    type: sum
    sql: ${current_weekly_users} ;;
    drill_fields: [detail*]
    html: {% if value <= 10 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value <= 20 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  ### PERCENT CHANGES ###
  measure: latest_usage_change_percent {
    type: average
    sql: ${usage_change_percent} ;;
    value_format_name: percent_2
    drill_fields: [detail*]

    filters: {
      field: event_weeks_ago
      value: "0"
    }

    html: {% if value <= 0.2 and value >= -0.2 %}
        <div style="color: black; background-color: goldenrod; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif value < -0.2 %}
        <div style="color: white; background-color: darkred; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        <div style="color: white; background-color: darkgreen; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% endif %}
      ;;
  }

  set: account_detail {
    fields: [account_id, account.name, account.vertical, account.state, cumulative_weekly_users, account.account_tier]
  }

  set: detail {
    fields: [account.name, account_id, license_slug, account_id, last_week_events, lifetime_usage_minutes, event_weeks_ago, weeks_since_signup, current_weekly_users, last_week_users, approximate_usage_minutes, last_week_usage_minutes, weekly_query_runs, weekly_project_creation, weekly_git_commits, weekly_api_calls, weekly_query_result_downloads, weekly_logins, weekly_dashboard_queries, weekly_dashboard_downloads, weekly_support_chats]
  }
}
