view: event {
  sql_table_name: public.events ;;
  # DIMENSIONS #

  dimension: id {
    primary_key: yes
    sql: ${TABLE}.id ;;
  }

  dimension_group: event {
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.event_at ;;
  }

  dimension: event_type {
    type: string
    sql: ${TABLE}.event_type ;;
  }

  dimension: instance_slug {
    sql: ${TABLE}.instance_slug ;;
  }

  dimension: license_slug {
    sql: ${TABLE}.license_slug ;;
  }

  dimension: user_id {
    type: number
    hidden: yes
    sql: ${TABLE}.user_id ;;
  }

  # MEASURES #

  measure: count {
    type: count
    drill_fields: [id]
  }

  measure: user_count {
    type: count_distinct
    sql: ${user_id} ;;
  }
}
