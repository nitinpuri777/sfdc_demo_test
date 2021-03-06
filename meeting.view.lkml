# For this demo company, Intro Meetings are the most important task, so we want to pull it out for specific analytics.
# Other companies may have other types of tasks that are stronger indicators for their business.
# No matter which piece of information needs to be pulled out, or which table it's coming from,
# this is a useful pattern for extracting an important piece of a table to expose for analytics.

view: meeting {
  derived_table: {
    sql: SELECT *
      FROM task
      WHERE type = 'Intro Meeting'
       ;;
    sql_trigger_value: SELECT COUNT(*) FROM task ;;
    distribution: "account_id"
    sortkeys: ["account_id"]
  }

  # FILTER-ONLY FIELDS #

  filter: meeting_goal {
    # Descriptions surface on the Explore page to facilitate using fields.
    description: "Enter an integer greater than zero."
  }

  # DIMENSIONS #

  dimension: id {
    primary_key: yes
    sql: ${TABLE}.id ;;
  }

  dimension: who_id {
    hidden: yes
    sql: ${TABLE}.who_id ;;
  }

  dimension: what_id {
    hidden: yes
    sql: ${TABLE}.what_id ;;
  }

  # Custom text field, Nearly always just "Intro Meeting"
  #   - dimension: subject
  #     sql: ${TABLE}.subject

  #  This is nearly always the same or before the meeting date. I'm going to therefore assume that the meeting date is the actual date the meeting ocurred, since it it later
  #   - dimension_group: activity
  #     type: time
  #     timeframes: [date, week, month, year]
  #     sql: ${TABLE}.activity_date

  dimension: status {
    sql: ${TABLE}.status ;;
  }

  # Always Normal
  #   - dimension: priority
  #     sql: ${TABLE}.priority

  dimension: owner_id {
    hidden: yes
    sql: ${TABLE}.owner_id ;;
  }

  #   - dimension: description
  #     sql: ${TABLE}.description

  #  Always "Intro Meeting"
  #   - dimension: type
  #     sql: ${TABLE}.type

  dimension: account_id {
    hidden: yes
    sql: ${TABLE}.account_id ;;
  }

  dimension: lead_id {
    hidden: yes
    sql: ${TABLE}.lead_id ;;
  }

  dimension: is_closed {
    type: yesno
    sql: ${TABLE}.is_closed ;;
  }

  dimension_group: created {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.created_date ;;
  }

  dimension: last_modified_by_id {
    hidden: yes
    sql: ${TABLE}.last_modified_by_id ;;
  }

  dimension: created_quarter {
    sql: EXTRACT(YEAR FROM ${TABLE}.created_date) || ' - Q' || EXTRACT(QUARTER FROM ${TABLE}.created_date) ;;
  }

  dimension: created_current_quarter {
    type: yesno
    sql: EXTRACT(QUARTER FROM ${TABLE}.created_date) || EXTRACT(YEAR FROM ${TABLE}.created_date) = EXTRACT(QUARTER FROM CURRENT_DATE) || EXTRACT(YEAR FROM CURRENT_DATE) ;;
  }

  dimension: created_by_id {
    hidden: yes
    sql: ${TABLE}.created_by_id ;;
  }

  dimension: call_type {
    hidden: yes
    sql: ${TABLE}.calltype ;;
  }

  # Nearly all are demo meetings
  #   - dimension: meeting_type
  #     sql: COALESCE(${TABLE}.meeting__type___c, 'Demo')

  # Always null
  #   - dimension_group: completed
  #     type: time
  #     timeframes: [date, week, month, year]
  #     sql: ${TABLE}.completed__date___c

  dimension_group: meeting {
    type: time
    timeframes: [date, week, month, year]
    sql: ${TABLE}.meeting__date__time___c ;;
  }

  dimension: sdr_meeting_assist {
    hidden: yes
    sql: ${TABLE}.sdr__meeting__assist___c ;;
  }

  #  Always No
  #   - dimension: is_high_priority
  #     type: yesno
  #     sql: ${TABLE}.is_high_priority

  #   - dimension: call_duration_in_seconds
  #     sql: ${TABLE}.call_duration_in_seconds
  #
  #   - dimension: call_disposition
  #     sql: ${TABLE}.call_disposition
  #
  #   - dimension: call_object
  #     sql: ${TABLE}.call_object

  # Has data, but I don't know what it is...
  #   - dimension_group: reminder
  #     type: time
  #     timeframes: [time, date, week, month]
  #     sql: ${TABLE}.reminder_date_time

  # Always no
  #   - dimension: is_reminder_set
  #     type: yesno
  #     sql: ${TABLE}.is_reminder_set


  dimension: recurrence_activity_id {
    hidden: yes
    sql: ${TABLE}.recurrence_activity_id ;;
  }

  # Always no
  #   - dimension: is_recurrence
  #     type: yesno
  #     sql: ${TABLE}.is_recurrence

  dimension: number_of_no_shows {
    sql: ${TABLE}.number__of__no__shows___c ;;
  }

  dimension: raw_meeting_date {
    hidden: yes
    sql: CASE WHEN ${status} = 'Completed' THEN ${TABLE}.meeting__date__time___c ELSE NULL END ;;
  }

  # MEASURES #

  measure: count {
    type: count
    drill_fields: [meeting_set*]
  }

  measure: meetings_completed {
    type: count

    filters: {
      field: status
      value: "Completed"
    }

    drill_fields: [meeting_set*]
  }

  measure: percent_to_goal {
    description: "Requires that meeting goal filter is populated"
    type: number
    value_format: "#%"
    sql: 1.00 * ${count} / NULLIF({%parameter meeting_goal %}, '') ;;
  }

  measure: successful_meetings {
    description: "Meetings that occurred"
    type: count

    filters: {
      field: is_closed
      value: "yes"
    }

    drill_fields: [meeting_set*]
  }

  measure: unsuccessful_meetings {
    description: "Meetings that did not happen"
    type: count

    filters: {
      field: is_closed
      value: "no"
    }

    drill_fields: [meeting_set*]
  }

  measure: successful_meeting_rate {
    description: "Percent of booked meetings that occurred"
    type: number
    sql: 1.00 * ${successful_meetings} / NULLIF(${count}, 0) ;;
    value_format: "#0.00%"
  }

  # SETS #

  set: meeting_set {
    fields: [id, status, account.name, is_closed, created_date]
  }

  set: export_set {
    fields: [id, who_id, what_id, account_id, lead_id, is_closed, created_date, meeting_date, count, percent_to_goal]
  }
}
