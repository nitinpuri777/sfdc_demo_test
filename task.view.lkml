view: task {
  derived_table: {
    sql: SELECT *
        , ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY created_date DESC) AS task_sequence
      FROM public.task
      WHERE ((created_date) >= (DATEADD(day,-89, DATE_TRUNC('day',GETDATE()) ))
            AND (created_date) < (DATEADD(day,90, DATEADD(day,-89, DATE_TRUNC('day',GETDATE()) ) )))
      AND account_id IS NOT NULL
       ;;
    distribution: "account_id"
    sortkeys: ["created_date", "account_id"]
## As of11/2/2016, SFDC etl to redshift moved to 8pm PST (8PM Santa Cruz, 11PM Eastern, 4AM London)
## consequently, moving all ETLs to 9:30pm PST (9:30PM PST, 12:30am Eastern, 5:30AM London)
## note that London time shift by an hour in the week between US and Europe start dates for daylight savings

    sql_trigger_value: SELECT DATE(DATEADD('minute', 150, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', getdate()))) ;;


  }

  dimension: id {
    primary_key: yes
    type: string
    sql: ${TABLE}.id ;;
  }

  dimension: task_sequence {
    type: number
    sql: ${TABLE}.task_sequence ;;
  }

  dimension: account_id {
    type: string
    # hidden: true
    sql: ${TABLE}.account_id ;;
  }

  dimension_group: activity {
    type: time
    timeframes: [date, week, month]
    convert_tz: no
    sql: ${TABLE}.activity_date ;;
  }

  dimension: call_disposition {
    type: string
    sql: ${TABLE}.call_disposition ;;
  }

  dimension: call_duration_in_seconds {
    type: number
    hidden:  yes
    sql: ${TABLE}.call_duration_in_seconds ;;
  }

  dimension: call_object {
    type: string
    sql: ${TABLE}.call_object ;;
  }

  dimension: call_type {
    type: string
    sql: ${TABLE}.call_type ;;
  }

  dimension_group: completed__date___c {
    type: time
    timeframes: [date, week, month]
    convert_tz: no
    hidden:  yes
    sql: ${TABLE}.completed__date___c ;;
  }

  dimension: created_by_id {
    type: string
    sql: ${TABLE}.created_by_id ;;
  }

  dimension_group: created {
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.created_date ;;
  }


  dimension: is_archived {
    type: yesno
    sql: ${TABLE}.is_archived ;;
  }

  dimension: is_closed {
    type: yesno
    sql: ${TABLE}.is_closed ;;
  }

  dimension: is_deleted {
    type: string
    sql: ${TABLE}.is_deleted ;;
  }

  dimension: is_high_priority {
    type: yesno
    sql: ${TABLE}.is_high_priority ;;
  }

  dimension: is_recurrence {
    type: yesno
    hidden: yes
    sql: ${TABLE}.is_recurrence ;;
  }

  dimension: is_reminder_set {
    type: yesno
    sql: ${TABLE}.is_reminder_set ;;
  }

  dimension: last_modified_by_id {
    type: string
    sql: ${TABLE}.last_modified_by_id ;;
  }

  dimension_group: last_modified {
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.last_modified_date ;;
  }

  dimension_group: meeting__date__time___c {
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.meeting__date__time___c ;;
  }

  dimension: meeting__type___c {
    type: string
    sql: ${TABLE}.meeting__type___c ;;
  }

  dimension: number__of__no__shows___c {
    type: string
    sql: ${TABLE}.number__of__no__shows___c ;;
  }

  dimension: owner_id {
    type: string
    sql: ${TABLE}.owner_id ;;
  }

  dimension: priority {
    type: string
    sql: ${TABLE}.priority ;;
  }

  dimension: recurrence_activity_id {
    type: string
    hidden: yes
    sql: ${TABLE}.recurrence_activity_id ;;
  }

  dimension: recurrence_day_of_month {
    type: number
    hidden: yes
    sql: ${TABLE}.recurrence_day_of_month ;;
  }

  dimension: recurrence_day_of_week_mask {
    type: number
    hidden: yes
    sql: ${TABLE}.recurrence_day_of_week_mask ;;
  }

  dimension_group: recurrence_end_date_only {
    type: time
    hidden: yes
    timeframes: [date, week, month]
    convert_tz: no
    sql: ${TABLE}.recurrence_end_date_only ;;
  }

  dimension: recurrence_instance {
    type: string
    hidden: yes
    sql: ${TABLE}.recurrence_instance ;;
  }

  dimension: recurrence_interval {
    type: number
    hidden: yes
    sql: ${TABLE}.recurrence_interval ;;
  }

  dimension: recurrence_month_of_year {
    type: string
    hidden: yes
    sql: ${TABLE}.recurrence_month_of_year ;;
  }

  dimension: recurrence_regenerated_type {
    type: string
    hidden: yes
    sql: ${TABLE}.recurrence_regenerated_type ;;
  }

  dimension_group: recurrence_start_date_only {
    type: time
    hidden: yes
    timeframes: [date, week, month]
    convert_tz: no
    sql: ${TABLE}.recurrence_start_date_only ;;
  }

  dimension: recurrence_time_zone_sid_key {
    type: string
    hidden: yes
    sql: ${TABLE}.recurrence_time_zone_sid_key ;;
  }

  dimension: recurrence_type {
    type: string
    hidden: yes
    sql: ${TABLE}.recurrence_type ;;
  }

  dimension_group: reminder_date {
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.reminder_date_time ;;
  }

  dimension: sdr__meeting__assist___c {
    type: string
    sql: ${TABLE}.sdr__meeting__assist___c ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension_group: system_modstamp {
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.system_modstamp ;;
  }

  dimension: type {
    type: string
    sql: ${TABLE}.type ;;
  }

  dimension: what_id {
    type: string
    sql: ${TABLE}.what_id ;;
  }

  dimension: who_id {
    type: string
    sql: ${TABLE}.who_id ;;
  }

  measure: count {
    type: count
    drill_fields: [id, account.id, account.name]
  }
}
