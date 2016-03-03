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
    links: 
      - label: Sales Rep Performance Dashboard
        url: http://demonew.looker.com/dashboards/5?Sales%20Rep={{ value | encode_uri }}&Sales%20Segment={{ salesrep.business_segment._value }}
        icon_url: http://www.looker.com/favicon.ico
  
  - dimension: business_segment
    sql: COALESCE(${TABLE}.business_segment, 'Top of Funnel/Not Assigned')
    links: 
      - label: Sales Team Summary Dashboard
        url: http://demonew.looker.com/dashboards/4?Business%20Segment={{ value | encode_uri }}
        icon_url: http://www.looker.com/favicon.ico
    suggestions: ['Enterprise','Mid-Market','Small Business','Top of Funnel/Not Assigned']
      
  - filter: rep_select
    view_label: 'Salesrep comparisons'
    suggest_dimension: name
      
  - filter: segment_select
    view_label: 'Salesrep comparisons'
    suggest_dimension: business_segment    
      
  - dimension: rep_comparitor
    view_label: 'Salesrep comparisons'
    description: Use in conjunction with rep select filter to compare to other sales reps
    sql: |
          CASE 
            WHEN {% condition rep_select %} ${name} {% endcondition %}
              THEN '1 - ' || ${name}
            WHEN {% condition segment_select %} ${business_segment} {% endcondition %}          
              THEN '2 - Rest of ' || ${business_segment}
          ELSE '3 - Rest of Sales Team'
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
    
  - measure: avg_mrr_pipeline
    type: number
    sql: ${opportunity.total_pipeline_mrr}/ NULLIF(${count},0)
    value_format: '[>=1000000]$0.00,,"M";[>=1000]$0.00,"K";$0.00'
    drill_fields: [account.name, opportunity.type, opportunity.closed_date, opportunity.total_acv]

