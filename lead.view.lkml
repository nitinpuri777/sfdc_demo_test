view: lead {
  derived_table: {
    sql: SELECT *
        , MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(company), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
      FROM public.lead
       ;;
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())) ;;
    sortkeys: ["created_at"]
    distribution: "company_id"
  }

  # DIMENSIONS #

  dimension: id {
    primary_key: yes
    sql: ${TABLE}.id ;;
  }

  dimension: company_id {
    hidden: yes
    sql: ${TABLE}.company_id ;;
  }

  dimension: account_id {
    hidden: yes
    sql: ${TABLE}.account_id ;;
  }

  # Extremely sparsely populated
  #   - dimension: analyst_name
  #     sql: ${TABLE}.analyst_name_c

  # Extremely sparsely populated
  #   - dimension: annual_revenue
  #     type: number
  #     sql: ${TABLE}.annual_revenue

  dimension: city {
    sql: ${TABLE}.city ;;
  }

  dimension: company {
    sql: ${TABLE}.company ;;
  }

  dimension: converted_contact_id {
    hidden: yes
    sql: ${TABLE}.converted_contact_id ;;
  }

  dimension: converted_opportunity_id {
    hidden: yes
    sql: ${TABLE}.converted_opportunity_id ;;
  }

  dimension: country {
    map_layer_name: countries
    sql: ${TABLE}.country ;;
  }

  dimension_group: created {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.created_at ;;
  }

  dimension: created_current_quarter {
    type: yesno
    sql: EXTRACT(QUARTER FROM ${TABLE}.created_at) || EXTRACT(YEAR FROM ${TABLE}.created_at) = EXTRACT(QUARTER FROM CURRENT_DATE) || EXTRACT(YEAR FROM CURRENT_DATE) ;;
  }

  # use dimension from account table instead
  #   - dimension: current_customer
  #     type: yesno
  #     sql: ${TABLE}.current_customer_c


  dimension: department {
    sql: ${TABLE}.department_c ;;
  }

  dimension: email {
    sql: ${TABLE}.email ;;
  }

  dimension: grouping {
    sql: ${TABLE}.grouping_c ;;
  }

  dimension: intro_meeting {
    type: yesno
    sql: ${TABLE}.intro_meeting_c ;;
  }

  dimension: is_converted {
    type: yesno
    sql: ${TABLE}.is_converted ;;
  }

  dimension: job_function {
    sql: ${TABLE}.job_function_c ;;
  }

  dimension: lead_processing_status {
    sql: ${TABLE}.lead_processing_status_c ;;
  }

  dimension: name {
    sql: ${TABLE}.name ;;
  }

  dimension: number_of_employees {
    type: number
    sql: ${TABLE}.number_of_employees ;;
  }

  dimension: state {
    map_layer_name: us_states
    sql: ${TABLE}.state ;;
  }

  dimension: status {
    sql: ${TABLE}.status ;;
  }

  dimension: territory {
    sql: ${TABLE}.territory_c ;;
  }

  dimension: title {
    sql: ${TABLE}.title ;;
  }

  #  extremely sparse, especially for leads that converted
  #   - dimension: year_founded
  #     sql: ${TABLE}.year_founded_c

  dimension: zendesk_organization {
    hidden: yes
    sql: ${TABLE}.zendesk_organization ;;
  }

  # MEASURES #

  measure: count {
    type: count
    drill_fields: [id, name, account.name, account.id]
  }

  # SETS #

  set: export_set {
    fields: [id, company_id, account_id, city, company, country, created_date, account.current_customer, department, email, grouping, intro_meeting, is_converted, job_function, name, number_of_employees, state, status, territory, title, zendesk_organization, count]
  }
}
