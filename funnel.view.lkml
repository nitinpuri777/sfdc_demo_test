view: funnel {
  derived_table: {
    sql: SELECT DISTINCT company_id
      FROM ${lead.SQL_TABLE_NAME}
      WHERE {% condition lead.created_date %} created_at {% endcondition %}
       ;;
  }

  # DIMENSIONS #

  dimension: company_id {
    sql: ${TABLE}.company_id ;;
  }

  # MEASURES #

  measure: lead_to_intro_meeting {
    label: "Conversion Lead to Intro Meeting Percentage"
    type: number
    sql: 100.0 * ${meeting.count}/NULLIF(${lead.count},0) ;;
    value_format: "#.00\%"
  }

  measure: meeting_to_opportunity {
    label: "Conversion Meeting to Opportunity Percentage"
    type: number
    sql: 100.0 * ${opportunity.count}/NULLIF(${meeting.count},0) ;;
    value_format: "#.00\%"
  }

  measure: opportunity_to_win {
    label: "Conversion Opportunity to Win Percentage"
    type: number
    sql: 100.0 * ${opportunity.count_won}/NULLIF(${opportunity.count},0) ;;
    value_format: "#.00\%"
  }
}
