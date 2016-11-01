view: zendesk_ticket {
  sql_table_name: public.zendesk_ticket ;;
  # DIMENSIONS #

  dimension: id {
    primary_key: yes
    sql: ${TABLE}.id ;;

    link: {
      label: "Zendesk Ticket"
      url: "https://d16cvnquvjw7pr.cloudfront.net/www/img/p-brand/downloads/Logo/Zendesk_logo_on_green_RGB.png"
      icon_url: "http://www.google.com/s2/favicons?domain=www.zendesk.com"
    }
  }

  dimension_group: created {
    type: time
    timeframes: [time, date, week, month, year]
    sql: ${TABLE}.created_date ;;
  }

  dimension: created_before_opp_closed {
    type: yesno
    sql: ${created_time} < ${opportunity.closed_time} ;;
  }

  dimension: name {
    sql: ${TABLE}.name ;;
  }

  dimension: tone {
    hidden: yes
    sql: ${TABLE}.tone___c ;;
  }

  #   - dimension: assignee_name
  #     sql: ${TABLE}.zendesk___assignee__name___c

  dimension_group: date_time_initially_assigned {
    type: time
    timeframes: [time, date, week, month, year]
    sql: ${TABLE}.zendesk___date__time__initially__assigned___c ;;
  }

  dimension_group: solved {
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.zendesk___date__time__solved___c ;;
  }

  dimension: has_been_solved {
    type: yesno
    sql: ${solved_time} IS NOT NULL ;;
  }

  dimension: time_to_solve {
    label: "Time to Solve (Min)"
    type: number
    sql: DATEDIFF(SECONDS, ${TABLE}.created_date, ${TABLE}.zendesk___date__time__solved___c )/60.0 ;;
    value_format: "#,##0.00"
  }

  dimension: time_to_solve_hours {
    label: "Time to Solve (Hours)"
    sql: DATEDIFF(HOURS, ${TABLE}.created_date, ${TABLE}.zendesk___date__time__solved___c ) ;;
    type: number
    value_format: "#,##0.00"
  }

  dimension: requester {
    sql: ${TABLE}.zendesk___requester___c ;;
  }

  dimension: status {
    hidden: yes
    sql: ${TABLE}.zendesk___status___c ;;
  }

  #MEASURES

  measure: count {
    type: count
    drill_fields: [id, name, status, time_to_solve]
  }

  measure: count_of_open_tickets {
    type: count
    drill_fields: [id, name]

    filters: {
      field: solved_time
      value: "NULL"
    }
  }

  measure: total_requester_wait_time_business {
    type: sum
    sql: ${requester_wait_time_business} ;;
  }

  measure: average_reply_time_calendar {
    type: average
    sql: ${reply_time_calendar} ;;
  }

  measure: average_requester_wait_time_business {
    type: average
    sql: ${requester_wait_time_business} ;;
  }

  measure: maximum_hold_time_business {
    type: max
    sql: ${hold_time_business} ;;
  }

  measure: minimum_hold_time_business {
    type: min
    sql: ${hold_time_business} ;;
  }

  measure: average_time_to_solve {
    type: average
    sql: ${time_to_solve} ;;

    filters: {
      field: status
      value: "Solved"
    }
  }

  measure: average_time_to_solve_hours {
    type: average
    sql: ${time_to_solve_hours} ;;
    value_format_name: decimal_2

    filters: {
      field: status
      value: "Solved"
    }
  }

  measure: sum_support_time {
    label: "Total Support Time (Min)"
    type: sum
    sql: ${time_to_solve} ;;

    filters: {
      field: status
      value: "Solved"
    }
  }

  measure: count_tickets_before_close {
    type: count

    filters: {
      field: created_before_opp_closed
      value: "Yes"
    }

    drill_fields: [created_date, id, time_to_solve]
  }

  measure: average_tickets_per_opp {
    type: number
    sql: 1.0 * ${count} / NULLIF(${opportunity.count}, 0) ;;
    value_format: "#0.00"
  }

  ## HIDDEN DIMENSIONS

  dimension: reply_time_calendar {
    type: number
    hidden: yes
    sql: ${TABLE}.zendesk___reply__time__calendar___c ;;
  }

  dimension: owner_id {
    hidden: yes
    sql: ${TABLE}.owner_id ;;
  }

  dimension: request_type {
    hidden: yes
    sql: ${TABLE}.request_type___c ;;
  }

  #   - dimension: action
  #     hidden: true
  #     sql: ${TABLE}.action___c
  #
  #   - dimension: bug_number
  #     hidden: true
  #     sql: ${TABLE}.bug__number___c
  #
  #   - dimension: category
  #     hidden: true
  #     sql: ${TABLE}.category___c

  dimension: created_by_id {
    hidden: yes
    sql: ${TABLE}.created_by_id ;;
  }

  dimension: is_deleted {
    type: yesno
    hidden: yes
    sql: ${TABLE}.is_deleted ;;
  }

  dimension_group: last_activity_date {
    type: time
    timeframes: [date, week, month, year]
    convert_tz: no
    hidden: yes
    sql: ${TABLE}.last_activity_date ;;
  }

  dimension: last_modified_by_id {
    hidden: yes
    sql: ${TABLE}.last_modified_by_id ;;
  }

  dimension_group: last_modified_date {
    hidden: yes
    type: time
    timeframes: [time, date, week, month, year]
    sql: ${TABLE}.last_modified_date ;;
  }

  dimension_group: last_referenced_date {
    hidden: yes
    type: time
    timeframes: [time, date, week, month, year]
    sql: ${TABLE}.last_referenced_date ;;
  }

  dimension: hold_time_business {
    type: number
    hidden: yes
    sql: ${TABLE}.zendesk___hold__time__business___c ;;
  }

  dimension: resolution_time_calendar {
    type: number
    hidden: yes
    sql: ${TABLE}.zendesk___resolution__time__calendar___c ;;
  }

  dimension_group: last_viewed_date {
    hidden: yes
    type: time
    timeframes: [time, date, week, month, year]
    sql: ${TABLE}.last_viewed_date ;;
  }

  dimension: agent_wait_time_business {
    type: number
    hidden: yes
    sql: ${TABLE}.zendesk___agent__wait__time__business___c ;;
  }

  dimension: agent_wait_time_calendar {
    hidden: yes
    type: number
    sql: ${TABLE}.zendesk___agent__wait__time__calendar___c ;;
  }

  dimension_group: date_time_created {
    type: time
    hidden: yes
    timeframes: [time, date, week, month, year]
    sql: ${TABLE}.zendesk___date__time__created___c ;;
  }

  dimension_group: date_time_updated {
    type: time
    timeframes: [time, date, week, month]
    hidden: yes
    sql: ${TABLE}.zendesk___date__time__updated___c ;;
  }

  #   - dimension: group
  #     hidden: true
  #     sql: ${TABLE}.zendesk___group___c

  dimension: hold_time_calendar {
    hidden: yes
    type: number
    sql: ${TABLE}.zendesk___hold__time__calendar___c ;;
  }

  dimension: opportunity {
    hidden: yes
    sql: ${TABLE}.zendesk___opportunity___c ;;
  }

  dimension: organization {
    hidden: yes
    sql: ${TABLE}.zendesk___organization___c ;;
  }

  dimension: priority {
    hidden: yes
    sql: ${TABLE}.zendesk___priority___c ;;
  }

  dimension: reply_time_business {
    type: number
    hidden: yes
    sql: ${TABLE}.zendesk___reply__time__business___c ;;
  }

  dimension: requester_wait_time_business {
    type: number
    hidden: yes
    sql: ${TABLE}.zendesk___requester__wait__time__business___c ;;
  }

  dimension: requester_wait_time_calendar {
    type: number
    hidden: yes
    sql: ${TABLE}.zendesk___requester__wait__time__calendar___c ;;
  }

  dimension: resolution_time_business {
    type: number
    hidden: yes
    sql: ${TABLE}.zendesk___resolution__time__business___c ;;
  }

  #   - dimension: zendesk_domain
  #     hidden: true
  #     sql: ${TABLE}.zendesk___zendesk_domain___c
  #
  #   - dimension: ticket_form_id
  #     type: number
  #     hidden: true
  #     sql: ${TABLE}.zendesk___ticket__form__id___c
  #
  #   - dimension: ticket_form_name
  #     hidden: true
  #     sql: ${TABLE}.zendesk___ticket__form__name___c

  dimension: ticket_id {
    hidden: yes
    sql: ${TABLE}.zendesk___ticket__id___c ;;
  }

  dimension: type {
    hidden: yes
    sql: ${TABLE}.zendesk___type___c ;;
  }

  #   - dimension: topic
  #     hidden: true
  #     sql: ${TABLE}.topic___c
  #
  #   - dimension: topic_other
  #     hidden: true
  #     sql: ${TABLE}.topic_other___c


  ## HIDDEN MEASURES

  measure: total_reply_time_calendar {
    type: sum
    hidden: yes
    sql: ${reply_time_calendar} ;;
  }

  measure: total_agent_wait_time_business {
    type: sum
    hidden: yes
    sql: ${agent_wait_time_business} ;;
  }

  measure: total_agent_wait_time_calendar {
    type: sum
    hidden: yes
    sql: ${agent_wait_time_calendar} ;;
  }

  measure: total_hold_time_business {
    type: sum
    hidden: yes
    sql: ${hold_time_business} ;;
  }

  measure: total_hold_time_calendar {
    type: sum
    hidden: yes
    sql: ${hold_time_calendar} ;;
  }

  measure: average_hold_time_business {
    type: average
    hidden: yes
    sql: ${hold_time_business} ;;
  }

  measure: average_hold_time_calendar {
    type: average
    hidden: yes
    sql: ${hold_time_calendar} ;;
  }
}
