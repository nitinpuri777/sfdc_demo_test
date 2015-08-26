- view: event
  sql_table_name: public.events
  fields:

# DIMENSIONS #

  - dimension: id
    primary_key: true
    sql: ${TABLE}.id

  - dimension_group: event
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.event_at

  - dimension: instance_slug
    sql: ${TABLE}.instance_slug

  - dimension: license_slug
    sql: ${TABLE}.license_slug

  - dimension: user_id
    type: int
    hidden: true
    sql: ${TABLE}.user_id

# MEASURES #

  - measure: count
    type: count
    drill_fields: [id]