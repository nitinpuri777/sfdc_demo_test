view: campaign_member {
  sql_table_name: public.campaign_member ;;

  dimension: id {
    primary_key: yes
    sql: ${TABLE}.id ;;
  }

  dimension: campaign_id {
    # hidden: true
    sql: ${TABLE}.campaign_id ;;
  }

  dimension: contact_id {
    # hidden: true
    sql: ${TABLE}.contact_id ;;
  }

  dimension_group: created {
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.created_at ;;
  }

  dimension: lead_id {
    # hidden: true
    sql: ${TABLE}.lead_id ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  # ----- Sets of fields for drilling ------
  set: detail {
    fields: [id, contact.assistantname, contact.name, contact.firstname, contact.lastname, contact.id, lead.name, lead.firstname, lead.lastname, lead.id, campaign.name, campaign.id]
  }
}
