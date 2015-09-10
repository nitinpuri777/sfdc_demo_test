- view: salesrep
  derived_table:
    sql: |
      SELECT id
        , first_name
        , last_name
        , CASE
            WHEN  PERCENT_RANK() OVER(ORDER BY auto_id) BETWEEN 0 AND 0.25
            THEN 'Enterprise'
            WHEN  PERCENT_RANK() OVER(ORDER BY auto_id) BETWEEN 0.25 AND 0.50
            THEN 'Mid-Market'
            ELSE 'Small Business'
          END AS business_segment
      FROM (SELECT *
              , ROW_NUMBER() OVER(ORDER BY 1) AS auto_id
            FROM person)
      WHERE id IN (SELECT DISTINCT owner_id FROM public.account)
    sql_trigger_value: SELECT COUNT(*) FROM person
    sortkeys:  [id]
  fields:

# DIMENSIONS #

  - dimension: id
    primary_key: true
    sql: ${TABLE}.id

  - dimension: first_name
    hidden: true
    sql: ${TABLE}.first_name

  - dimension: last_name
    hidden: true
    sql: ${TABLE}.last_name

  - dimension: name
    sql: ${first_name} || ' ' || ${last_name}
    html: |
      {{ linked_value }}
      <a href="/dashboards/5?Sales%20Rep={{ value | encode_uri }}&Sales%20Segment={{ salesrep.business_segment._value }}" target="_blank">
      <img src="/images/qr-graph-line@2x.png" height=20 width=20></a>
  
  - dimension: business_segment
    sql: COALESCE(${TABLE}.business_segment, 'Top of Funnel/Not Assigned')
    html: |
      {{ linked_value }}
      <a href="/dashboards/4?Business%20Segment={{ value | encode_uri }}" target="_blank">
      <img src="/images/qr-graph-line@2x.png" height=20 width=20></a>
      
  - filter: rep_select
    suggest_dimension: name
      
  - dimension: rep_comparitor
    description: Use in conjunction with rep select filter to compare to other sales reps
    sql: |
          CASE WHEN {% condition rep_select %} ${name} {% endcondition %}
          THEN ${name}
          ELSE 'Sales Team Avg'
          END
    
# MEASURES #
      
  - measure: count
    type: count
    drill_fields: [id, name, business_segment]

  - measure: avg_acv_won_comparitor
    type: number
    sql: ${opportunity.total_acv_won}/NULLIF(${count},0)
    value_format: '[>=1000000]$0.00,,"M";[>=1000]$0.00,"K";$0.00'
    drill_fields: [account.name, opportunity.type, opportunity.closed_date, opportunity.total_acv]
  
  - measure: avg_acv_lost_comparitor
    type: number
    sql: ${opportunity.total_acv_lost}/NULLIF(${count},0)  
    value_format: '[>=1000000]$0.00,,"M";[>=1000]$0.00,"K";$0.00'
    drill_fields: [account.name, opportunity.type, opportunity.closed_date, opportunity.total_acv]

  - measure: avg_acv_pipeline
    type: number
    sql: ${opportunity.total_pipeline_acv}/NULLIF(${count},0)  
    value_format: '[>=1000000]$0.00,,"M";[>=1000]$0.00,"K";$0.00'
    drill_fields: [account.name, opportunity.type, opportunity.closed_date, opportunity.total_acv]

