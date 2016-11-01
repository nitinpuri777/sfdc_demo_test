view: campaign {
  sql_table_name: public.campaign ;;
  # DIMENSIONS #

  dimension: id {
    primary_key: yes
    sql: ${TABLE}.id ;;
  }

  dimension: ad_type {
    sql: ${TABLE}.ad_type_c ;;
  }

  dimension: allocation {
    sql: COALESCE(${TABLE}.allocation_c, 'Undetermined') ;;
  }

  dimension: conversion_point {
    sql: COALESCE(${TABLE}.conversion_point_c, 'Other') ;;
  }

  dimension_group: created {
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: end {
    type: time
    timeframes: [date, week, month]
    convert_tz: no
    sql: ${TABLE}.end_date ;;
  }

  dimension: grouping {
    sql: ${TABLE}.grouping_c ;;
  }

  dimension: initiative_type {
    sql: ${TABLE}.initiative_type_c ;;
  }

  dimension: is_active {
    type: yesno
    sql: ${TABLE}.is_active ;;
  }

  #   - dimension: offer_type
  #     sql: ${TABLE}.offer_type_c

  dimension: origin {
    sql: ${TABLE}.origin_c ;;
  }

  #   - dimension: publisher
  #     sql: ${TABLE}.publisher_c

  dimension_group: start {
    type: time
    timeframes: [date, week, month, year]
    convert_tz: no
    sql: ${TABLE}.start_date ;;
  }

  dimension: status {
    sql: ${TABLE}.status ;;
  }

  dimension: type {
    sql: ${TABLE}.type ;;
  }

  # MEASURES #

  measure: count {
    type: count
    drill_fields: [id, ad_type, status]
  }
}
