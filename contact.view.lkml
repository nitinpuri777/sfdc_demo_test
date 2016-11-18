view: contact {
  sql_table_name: public.contact ;;
  # DIMENSIONS #

  dimension: id {
    primary_key: yes
    hidden: yes
    sql: ${TABLE}.id ;;
  }

  dimension: account_id {
    hidden: yes
    sql: ${TABLE}.account_id ;;
  }

  # sparsely populated
  #   - dimension: contact_type
  #     sql: ${TABLE}.contact_type_c

  dimension_group: created {
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.created_at ;;
  }

  #  not consistent with account.is_customer
  #   - dimension: current_customer
  #     type: yesno
  #     sql: ${TABLE}.current_customer_c

  # Extremely sparse
  #   - dimension: department
  #     sql: ${TABLE}.department

  dimension: department_picklist {
    sql: ${TABLE}.department_picklist_c ;;
  }

  dimension: email {
    sql: ${TABLE}.email ;;
  }

  dimension: grouping {
    sql: ${TABLE}.grouping_c ;;
  }

  dimension: inbound_form_fillout {
    type: yesno
    sql: ${TABLE}.inbound_form_fillout_c ;;
  }

  dimension: intro_meeting {
    type: yesno
    sql: ${TABLE}.intro_meeting_c ;;
  }

  dimension: job_function {
    sql: ${TABLE}.job_function_c ;;
  }

  dimension: lead_source {
    sql: ${TABLE}.lead_source ;;
  }

  dimension: name {
    sql: ${TABLE}.name ;;
  }

  dimension: primary_contact {
    type: yesno
    sql: ${TABLE}.primary_contact_c ;;
  }

  dimension: qual_form_fillout {
    type: yesno
    sql: ${TABLE}.qual_form_fillout_c ;;
  }

  dimension: territory {
    sql: ${TABLE}.territory_c ;;
  }

  dimension: title {
    sql: ${TABLE}.title ;;
  }

  #  Numeric field, doesn't seem useful
  #   - dimension: zendesk_organization
  #     sql: ${TABLE}.zendesk_organization

  # MEASURES #

  measure: count {
    type: count
    drill_fields: [id, name, account.name, account.id]
  }

  # SETS #

  set: export_set {
    fields: [id, account_id, created_date, email, inbound_form_fillout, intro_meeting, job_function, lead_source, name, primary_contact, qual_form_fillout, title, count]
  }
}
