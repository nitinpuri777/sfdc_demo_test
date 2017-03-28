# This derived table divides this fictional company's sales force into teams.
# If a company doesn't have a table that divides its users into teams or hasn't input that data into Salesforce,
# Dividing companies into teams by way of a derived table may still make sense.

view: salesrep {
  derived_table: {
    sql: SELECT id
        , first_name
        , last_name
        , CASE
            WHEN  PERCENT_RANK() OVER(ORDER BY auto_id) BETWEEN 0 AND 0.25
            THEN 'Enterprise'
            WHEN  PERCENT_RANK() OVER(ORDER BY auto_id) BETWEEN 0.25 AND 0.5
            THEN 'Mid-Market'
            ELSE 'Small Business'
          END AS business_segment
      FROM (SELECT *
              , ROW_NUMBER() OVER(ORDER BY 1) AS auto_id
            FROM person)
      WHERE id IN (SELECT DISTINCT owner_id FROM public.account)
       ;;

## As of11/2/2016, SFDC etl to redshift moved to 8pm PST (8PM Santa Cruz, 11PM Eastern, 4AM London)
## consequently, moving all ETLs to 9:30pm PST (9:30PM PST, 12:30am Eastern, 5:30AM London)
## note that London time shift by an hour in the week between US and Europe start dates for daylight savings
## This PDT was previously regenerated using SELECT COUNT(*) FROM person
## We changed this to a calendered rebuild to avoid accidentally querying tables that are empty while ETL is still running

    sql_trigger_value: SELECT DATE(DATEADD('minute', 150, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', getdate()))) ;;

    distribution_style: all
    sortkeys: ["id"]
  }

  # DIMENSIONS #

  dimension: id {
    primary_key: yes
    sql: ${TABLE}.id ;;
  }

  dimension: first_name {
    hidden: yes
    sql: ${TABLE}.first_name ;;
  }

  dimension: last_name {
    hidden: yes
    sql: ${TABLE}.last_name ;;
  }

  # The next two dimensions create links to other dashboards within Looker when clicking on any value from this field on a dashboard

  dimension: name {
    sql: ${first_name} || ' ' || ${last_name} ;;

    link: {
      label: "Sales Representative Performance Dashboard"
      url: "http://demo.looker.com/dashboards/5?Sales%20Rep={{ value | encode_uri }}&Sales%20Segment={{ salesrep.business_segment._value }}"
      icon_url: "http://www.looker.com/favicon.ico"
    }

    link: {
      label: "Rep Success Dashboard"
      url: "http://demo.looker.com/dashboards/331?Sales%20Rep%20Name={{ value | encode_uri }}&Business%20Segment={{ salesrep.business_segment._value }}"
      icon_url: "http://www.looker.com/favicon.ico"
    }
  }

  #
  dimension: business_segment {
    sql: COALESCE(${TABLE}.business_segment, 'Top of Funnel/Not Assigned') ;;

    link: {
      label: "Sales Team Summary Dashboard"
      url: "http://demo.looker.com/dashboards/4?Business%20Segment={{ value | encode_uri }}"
      icon_url: "http://www.looker.com/favicon.ico"
    }

    link: {
      label: "Rep Overview Dashboard"
      url: "http://demo.looker.com/dashboards/323?Business%20Segment={{ value | encode_uri }}"
      icon_url: "http://www.looker.com/favicon.ico"
    }

    suggestions: ["Enterprise", "Mid-Market", "Small Business", "Top of Funnel/Not Assigned"]
  }

  filter: rep_select {
    view_label: "Salesrep comparisons"
    suggest_dimension: name
  }

  filter: segment_select {
    view_label: "Salesrep comparisons"
    suggest_dimension: business_segment
  }

  dimension: rep_comparitor {
    view_label: "Salesrep comparisons"
    description: "Use in conjunction with rep select filter to compare to other sales reps"
    sql: CASE
        WHEN {% condition rep_select %} ${name} {% endcondition %}
          THEN '1 - ' || ${name}
        WHEN {% condition segment_select %} ${business_segment} {% endcondition %}
          THEN '2 - Rest of ' || ${business_segment}
      ELSE '3 - Rest of Sales Team'
      END
       ;;
  }

  # MEASURES #

  measure: count {
    type: count
    drill_fields: [id, name, business_segment]
  }

  measure: avg_acv_won_comparitor {
    type: number
    sql: ${opportunity.total_acv_won}/NULLIF(${count},0) ;;
    value_format: "[>=1000000]$0.00,,\"M\";[>=1000]$0.00,\"K\";$0.00"
    drill_fields: [account.name, opportunity.type, opportunity.closed_date, opportunity.total_acv]
  }

  measure: avg_acv_lost_comparitor {
    type: number
    sql: ${opportunity.total_acv_lost}/NULLIF(${count},0) ;;
    value_format: "[>=1000000]$0.00,,\"M\";[>=1000]$0.00,\"K\";$0.00"
    drill_fields: [account.name, opportunity.type, opportunity.closed_date, opportunity.total_acv]
  }

  measure: avg_acv_pipeline {
    type: number
    sql: ${opportunity.total_pipeline_acv}/NULLIF(${count},0) ;;
    value_format: "[>=1000000]$0.00,,\"M\";[>=1000]$0.00,\"K\";$0.00"
    drill_fields: [account.name, opportunity.type, opportunity.closed_date, opportunity.total_acv]
  }

  measure: avg_mrr_pipeline {
    type: number
    sql: ${opportunity.total_pipeline_mrr}/ NULLIF(${count},0) ;;
    value_format: "[>=1000000]$0.00,,\"M\";[>=1000]$0.00,\"K\";$0.00"
    drill_fields: [account.name, opportunity.type, opportunity.closed_date, opportunity.total_acv]
  }
}
