- view: opportunity
  fields:

# DIMENSIONS #

  - dimension: id
    primary_key: true
    sql: ${TABLE}.id
    html: |
      {{ value }}
      <a href="https://blog.internetcreations.com/wp-content/uploads/2012/09/Business-Account_-Internet-Creations-salesforce.com-Enterprise-Edition-1.jpg" target="_new">
      <img src="http://www.salesforce.com/favicon.ico" height=16></a>

  - dimension: account_id
    hidden: true
    sql: ${TABLE}.account_id
    
  - dimension: company_id
    hidden: true
    sql: company_id

  - dimension: acv
    type: number
    sql: ${TABLE}.acv

  - dimension: amount
    type: number
    sql: ${TABLE}.amount
    value_format: '$#,##0.00'
    
  - dimension: campaign_id
    hidden: true
    sql: ${TABLE}.campaign_id

  - dimension: churn_status
    sql: ${TABLE}.churn_status_c

  - dimension_group: closed
    type: time
    timeframes: [date, week, month, year, time]
    sql: ${TABLE}.closed_date
    
  - dimension: closed_quarter
    sql: EXTRACT(YEAR FROM ${TABLE}.closed_date) || ' - Q' || EXTRACT(QUARTER FROM ${TABLE}.closed_date)
    
  - dimension: is_current_quarter
    type: yesno
    sql: EXTRACT(QUARTER FROM ${TABLE}.closed_date) || EXTRACT(YEAR FROM ${TABLE}.closed_date) = EXTRACT(QUARTER FROM CURRENT_DATE) || EXTRACT(YEAR FROM CURRENT_DATE)    

  - dimension: contract_length
    type: number
    sql: ${TABLE}.contract_length_c
  
  - dimension_group: created
    type: time
    timeframes: [date, week, month, year]
    sql: ${TABLE}.created_at

  - dimension: days_open
    type: number
    sql: DATEDIFF(DAYS, ${TABLE}.created_at, COALESCE(${TABLE}.closed_date, current_date) )
    
      
      
  - dimension:  opp_to_closed_60d 
    hidden: true
    type: yesno
    sql: ${days_open} <=60 AND ${is_closed} = 'yes' AND ${is_won} = 'yes'

#  Always No
#   - dimension: is_cancelled
#     type: yesno
#     sql: ${TABLE}.is_cancelled_c

  - dimension: is_closed
    type: yesno
    sql: ${TABLE}.is_closed

  - dimension: is_won
    type: yesno
    sql: ${TABLE}.is_won

  - dimension: lead_source
    sql: ${TABLE}.lead_source

  - dimension: lost_reason
    sql: ${TABLE}.lost_reason_c

  - dimension: mrr
    type: number
    sql: ${TABLE}.mrr
    value_format: '$#,##0.00'

  - dimension: next_step
    sql: ${TABLE}.next_step

  - dimension: nrr
    type: number
    sql: ${TABLE}.nrr
    value_format: '$#,##0.00'

  - dimension: probability
    type: number
    sql: ${TABLE}.probability/100.0
    value_format: "#%"

  - dimension: probablity_tier
    type: tier
    tiers: [0,.01,.20,.40,.60,.80,1]
#     style: integer
    sql: ${probability}
    
  - dimension: probability_group
    sql_case:
      'Won': ${probability} = 1
      'Above 80%': ${probability} > .8
      '60 - 80%': ${probability} > .6
      '40 - 60%': ${probability} > .4
      '20 - 40%': ${probability} > .2
      'Under 20%': ${probability} > 0
      'Lost': ${probability} = 0


# Always null
#   - dimension: renewal_number
#     type: int
#     sql: ${TABLE}.renewal_number_c

  - dimension: renewal_opportunity_id
    sql: ${TABLE}.renewal_opportunity_id

  - dimension: stage_name
    sql: ${TABLE}.stage_name
  
  - dimension: stage_name_funnel
    sql_case: 
      Lead: ${stage_name} IN ('Active Lead')
      Prospect: ${stage_name} like '%Prospect%'
      Trial: ${stage_name} like '%Trial%'
      Winning:  ${stage_name} IN ('Proposal','Commit- Not Won','Negotiation')
      Won:  ${stage_name} IN ('Closed Won')
      Lost: ${stage_name} like '%Closed%' 
      Unknown: true
      
  - dimension: contract_value
    type: number
    sql: ${TABLE}.total_contract_value_c
    value_format: '$#,##0.00'

  - dimension: type
    sql: ${TABLE}.type
    
  - dimension: probable_contract_value
    type: number
    sql: (${probability} / 100.00) * ${contract_value}
    decimals: 2
    drill_fields: [detail*]    
    
  - dimension: raw_created_date
    hidden: true
    sql: ${TABLE}.created_at  

# MEASURES #

  - measure: count
    type: count
    drill_fields: opportunity_set*
#     filters:
#       account.type: Customer
#       opportunity.type: New Business
    
  - measure: avg_days_open
    type: avg
    sql: ${days_open}  

    
  - measure: cumulative_total
    type: running_total
    sql: ${count}
    
  - measure: count_closed
    type: count
    filters: 
      is_closed: Yes
    drill_fields: opportunity_set*
      
  - measure: count_open
    type: count
    filters:
      is_closed: No
    drill_fields: opportunity_set*
    
  - measure: count_lost
    type: count
    filters:
      is_closed: Yes
      is_won: No
    drill_fields: [opportunity.id, account.name, salesrep.name, type, total_acv] 
    
  - measure: count_won
    type: count
    filters:
      is_won: Yes
    drill_fields: [opportunity.id, account.name, salesrep.name, type, total_acv]
    
  - measure: total_mrr
    label: 'Total MRR (Closed/Won)'
    type: sum
    sql: ${mrr}
    filters:
      is_won: Yes    
    drill_fields: opportunity_set*
    value_format: '[>=1000000]0.00,,"M";[>=1000]0.00,"K";$0.00'
    
  - measure: total_pipeline_mrr
    type: sum
    sql: ${mrr}
    filters:
      is_closed: No
    drill_fields: opportunity_set*  
    value_format: '[>=1000000]0.00,,"M";[>=1000]0.00,"K";$0.00'
      
    
  - measure: average_mrr
    label: 'Average MRR (Closed/Won)'
    type: average
    sql: ${mrr}
    filters:
      is_won: Yes    
    drill_fields: opportunity_set*
    value_format: '$#,##0'

#   - measure: total_contract_value
#     label: 'Total Contract Value (Won)'
#     type: sum
#     sql: ${contract_value}
#     filters:
#       is_won: Yes    
#     drill_fields: opportunity_set*
#     value_format: '$#,##0'
    
  - measure: average_contract_value
    label: 'Average Contract Value (Won)'
    type: average
    sql: ${contract_value}
    filters:
      is_won: Yes
    drill_fields: opportunity_set*
    value_format: '$#,##0'
      
  - measure: win_percentage
    type: number
    sql: 100.00 * ${count_won} / NULLIF(${count}, 0)
    value_format: '#0.00\%'
    
  - measure: open_percentage
    type: number
    sql: 100.00 * ${count_open} / NULLIF(${count}, 0)
    value_format: '#0.00\%'
    
  - measure: total_acv
    type: sum
    sql: ${acv}
    value_format: '[>=1000000]0.00,,"M";[>=1000]0.00,"K";$0.00'
    drill_fields: opportunity_set*
    
  - filter: rep_name
    suggest_dimension: salesrep.name
    
  - filter: sales_segment
    suggest_dimension: salesrep.business_segment

  - measure: total_acv_won
    type: sum
    sql: ${acv}   
    filters:
      is_won: Yes
    value_format: '[>=1000000]0.00,,"M";[>=1000]0.00,"K";$0.00' 
    drill_fields: [account.name, type, closed_date, total_acv]

  - measure: total_acv_lost
    type: sum
    sql: ${acv}   
    filters:
      is_won: No
    value_format: '[>=1000000]0.00,,"M";[>=1000]0.00,"K";$0.00'
    drill_fields: opportunity_set*
    
  - measure: total_pipeline_acv
    type: sum
    sql: ${acv}   
    filters:
      is_closed: No
    value_format: '$#,##0' 
    drill_fields: opportunity_set*
  
  - measure: total_pipeline_acv_m
    type: sum
    decimals: 1
    sql: ${acv}/1000000.0
    filters:
      is_closed: No
    drill_fields: opportunity_set*
    html: |
      {{ rendered_value }}M
        
  - measure: total_acv_running_sum 
    type: running_total
    sql: ${total_acv}     
    drill_fields: opportunity_set*
    
  - measure: meetings_converted_to_close_within_60d
    type: count_distinct
    sql: ${meeting.id}
    hidden: true
    filters:
      meeting.status: 'Completed'
      opp_to_closed_60d: 'Yes' 
      is_won: 'Yes'
      
      
  - measure: meeting_to_close_conversion_rate_60d
    label: 'Meeting to Close/Won Conversion within 60 days'
    view_label: 'Meeting'
    description: 'What percent of meetings converted to closed within 60 days of the meeting?'
    type: number
    value_format: '#.#\%'
    sql: 100.0 * ${meetings_converted_to_close_within_60d} / nullif(${meeting.meetings_completed},0)
    drill_fields: [name, meeting.meeting_date, account_representative_meeting.name, opportunity.created_date, opportunity.name, opportunity.stage_name]      

#REP VS TEAM METRICS. Could use extends functionality for this.
    
#   - dimension: is_rep
#     sql: |
#       CASE 
#       WHEN {% condition rep_name %} ${salesrep.name} {% endcondition %}
#         THEN 'Yes'
#       ELSE 'No'
#       END
#     
#   - dimension: is_sales_team
#     sql: |
#       CASE 
#       WHEN {% condition sales_segment %} ${salesrep.business_segment} {% endcondition %}
#         THEN 'Yes'
#       ELSE 'No'
#       END
#     
#   - dimension: number_reps_in_segment
#     sql: |
#       CASE 
#       WHEN {% parameter sales_segment %} = 'Enterprise'
#         THEN 7
#       WHEN {% parameter sales_segment %} = 'Small Business'
#         THEN 14
#       ELSE 6
#       END    
#   
#   - measure: rep_total_acv_won  
#     type: sum
#     sql: ${acv}   
#     filters:
#       is_won: Yes
#       is_rep: Yes
#     value_format: '$#,##0' 
#     drill_fields: [account.name, type, closed_date, total_acv]
#   
#   - measure: team_acv_won
#     hidden: true
#     type: sum
#     sql: ${acv}   
#     filters:
#       is_won: Yes
#       is_rep: No
#       is_sales_team: Yes
#     value_format: '$#,##0' 
#     drill_fields: opportunity_set*
#     
#   - measure: avg_team_total_acv_won
#     type: number
#     sql: ${team_acv_won} / ${number_reps_in_segment}
#     value_format: '$#,##0'
#     
#   - measure: rep_acv_lost
#     type: sum
#     sql: ${acv}   
#     filters:
#       is_won: No
#       is_rep: Yes
#     value_format: '$#,##0' 
#     drill_fields: opportunity_set*
#     
#   - measure: team_acv_lost
#     hidden: true
#     type: sum
#     sql: ${acv}   
#     filters:
#       is_won: No
#       is_rep: No
#       is_sales_team: Yes    
#     value_format: '$#,##0' 
#     drill_fields: opportunity_set*
#     
#   - measure: avg_team_acv_lost
#     type: number
#     sql: ${team_acv_lost} / ${number_reps_in_segment}
#     value_format: '$#,##0' 
#     
#   - measure: rep_pipeline_acv
#     type: sum
#     sql: ${acv}   
#     filters:
#       is_closed: No
#       is_rep: Yes
#     value_format: '$#,##0' 
#     drill_fields: opportunity_set*
#     
#   - measure: team_pipeline_acv
#     hidden: true
#     type: sum
#     sql: ${acv}   
#     filters:
#       is_closed: No
#       is_rep: No
#       is_sales_team: Yes
#     value_format: '$#,##0' 
#     drill_fields: opportunity_set*    
#     
#   - measure: avg_team_pipeline_acv
#     type: number
#     sql: ${team_pipeline_acv} / ${number_reps_in_segment}
#     value_format: '$#,##0'   
    
# SETS #


  sets:
    opportunity_set:
      - account.name
      - stage_name_funnel
      - type
    
    export_set:
      - id
      - account_id
      - acv
      - amount
      - campaign_id
      - churn_status
      - created_date
      - created_week
      - created_month
      - closed_date
      - closed_week
      - closed_month      
      - closed_quarter
      - contract_length
      - is_closed
      - is_current_quarter
      - is_won
      - lead_source
      - lost_reason
      - mrr
      - next_step
      - nrr
      - probability
      - stage_name
      - stage_name_funnel
      - contract_value
      - type
      - probable_contract_value
      - count
      - total_mrr
      - average_mrr
#       - total_contract_value
      - average_contract_value
      - count_closed
      - count_won
      - count_open
      - win_percentage
      - open_percentage
      - cumulative_total
      - total_acv
      - total_acv_running_sum
      - count_lost
      
  derived_table:
    sql: |
      SELECT opportunity.*
        , MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(account.name), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
      FROM public.opportunity AS opportunity
      LEFT JOIN public.account AS account
      ON account.id = opportunity.account_id    
    sql_trigger_value: SELECT CURRENT_DATE
    sortkeys: [account_id]
    distkey: account_id  
    
    
