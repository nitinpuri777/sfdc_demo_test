view: rolling_30_day_activity_facts {
  derived_table: {
    sql: WITH daily_use AS (
        SELECT
          user_id
          , license_slug
          , instance_slug
          , event_date as event_date
        FROM ${daily_event_rollup.SQL_TABLE_NAME}
      )
      SELECT
          daily_use.user_id || '-' || daily_use.license_slug AS license_user_id
          , daily_use.user_id AS user_id
          , daily_use.license_slug as license_slug
          , wd.date as date
          , ROW_NUMBER() OVER () AS unique_key
          , COUNT(DISTINCT instance_slug) AS count_of_instances
          , MIN(wd.date::date - daily_use.event_date::date) as days_since_last_action
      FROM daily_use, ${dates.SQL_TABLE_NAME} AS wd
      WHERE
          wd.date >= daily_use.event_date
          AND wd.date < daily_use.event_date + interval '30 day'
          AND (((wd.date) >= (CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', DATEADD(day,-364, DATE_TRUNC('day',CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())) ))) AND (wd.date) < (CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', DATEADD(day,365, DATEADD(day,-364, DATE_TRUNC('day',CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())) ) )))))
      GROUP BY 1,2,3,4
       ;;
## As of11/2/2016, SFDC etl to redshift moved to 8pm PST (8PM Santa Cruz, 11PM Eastern, 4AM London)
## consequently, moving all ETLs to 9:30pm PST (9:30PM PST, 12:30am Eastern, 5:30AM London)
## note that London time shift by an hour in the week between US and Europe start dates for daylight savings
    sql_trigger_value: SELECT DATE(DATEADD('minute', 150, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', getdate()))) ;;
    distribution: "user_id"
    sortkeys: ["date"]
  }

  dimension: id {
    type: string
    primary_key: yes
    hidden: yes
    sql: ${TABLE}.unique_key ;;
  }

  dimension_group: date {
    type: time
    timeframes: [raw, date, week, day_of_week]
    sql: ${TABLE}.date ;;
  }

  dimension: license_user_id {
    type: string
    hidden: yes
    sql: ${TABLE}.license_user_id ;;
  }

  dimension: user_id {
    type: string
    sql: ${TABLE}.user_id ;;
  }

  dimension: license_slug {
    type: string
    hidden: yes
    sql: ${TABLE}.license_slug ;;
  }

  dimension: count_of_instances {
    type: number
    sql: ${TABLE}.count_of_instances ;;
  }

  dimension: days_since_last_action {
    type: number
    sql: ${TABLE}.days_since_last_action ;;
    value_format_name: decimal_0
  }

  dimension: active_this_day {
    type: yesno
    sql: ${days_since_last_action} <  1 ;;
  }

  dimension: active_last_7_days {
    type: yesno
    sql: ${days_since_last_action} < 7 ;;
  }

  measure: user_count_active_30_days {
    label: "Monthly Active Users"
    type: count_distinct
    sql: ${user_id} ;;
  }

  #       drill_fields: [users.id, users.name]

  measure: user_count_active_this_day {
    label: "Daily Active Users"
    type: count_distinct
    sql: ${user_id} ;;
    #       drill_fields: [users.id, users.name]
    filters: {
      field: active_this_day
      value: "yes"
    }
  }

  measure: user_count_active_7_days {
    label: "Weekly Active Users"
    type: count_distinct
    sql: ${user_id} ;;
    #       drill_fields: [users.id, users.name]
    filters: {
      field: active_last_7_days
      value: "yes"
    }
  }
}
