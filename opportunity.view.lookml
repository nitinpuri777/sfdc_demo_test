
- view: opportunity
  fields:

# DIMENSIONS #

  - dimension: id
    primary_key: true
    sql: ${TABLE}.id
    links: 
      - label: Salesforce Opportunity
        url: https://blog.internetcreations.com/wp-content/uploads/2012/09/Business-Account_-Internet-Creations-salesforce.com-Enterprise-Edition-1.jpg
        icon_url: http://www.salesforce.com/favicon.ico

  - dimension: account_id
    hidden: true
    sql: ${TABLE}.account_id
    
  - dimension: company_id
    hidden: true
    sql: company_id

  - dimension: owner_id
    hidden: true
    sql: ${TABLE}.owner_id
    
  - dimension: acv
    type: number
    sql: ${TABLE}.acv
    value_format_name: usd_large

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
    timeframes: [raw, date, week, month, year, time, quarter]
    convert_tz: false
    sql: ${TABLE}.closed_date
    
  - dimension: closed_quarter_string
    hidden: true
    sql: EXTRACT(YEAR FROM ${TABLE}.closed_date) || ' - Q' || EXTRACT(QUARTER FROM ${TABLE}.closed_date)

  - dimension: current_quarter
    hidden: true
    sql: EXTRACT(YEAR FROM CURRENT_DATE) || ' - Q' || EXTRACT(QUARTER FROM CURRENT_DATE)

  - dimension: is_current_quarter
    type: yesno
    sql: ${closed_quarter_string} = ${current_quarter}

  - dimension: closed_day_of_quarter
    type: number
    sql: |  
      DATEDIFF(
        'day',
        CAST(CONCAT(${closed_quarter}, '-01') as date),
        ${closed_raw})

  - dimension: days_left_in_quarter
    type: number
    sql: |
      91 - (DATEDIFF(
        'day',
        CAST(CONCAT((TO_CHAR(CAST(DATE_TRUNC('quarter', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', CURRENT_DATE)) AS DATE), 'YYYY-MM')), '-01') as date),
        CURRENT_DATE)) - 1
  
  - dimension: day_of_current_quarter
    type: number
    sql: |
       (DATEDIFF(
        'day',
        CAST(CONCAT((TO_CHAR(CAST(DATE_TRUNC('quarter', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', CURRENT_DATE)) AS DATE), 'YYYY-MM')), '-01') as date),
        CURRENT_DATE)) + 1

  - dimension: is_quarter_to_date
    type: yesno
    sql: ${closed_day_of_quarter} <= ${day_of_current_quarter}
      
  - dimension: contract_length
    type: number
    sql: ${TABLE}.contract_length_c
  
  - dimension_group: created
    type: time
    timeframes: [date, week, month, year, quarter]
    sql: ${TABLE}.created_at

  - dimension: days_open
    type: number
    sql: DATEDIFF(DAYS, ${TABLE}.created_at, COALESCE(${TABLE}.closed_date, current_date) )

  - dimension: months_open
    type: number
    sql: DATEDIFF(MONTHS, ${TABLE}.created_at, COALESCE(${TABLE}.closed_date, current_date) )
    
  - dimension:  opp_to_closed_60d 
    hidden: true
    type: yesno
    sql: ${days_open} <=60 AND ${is_closed} = 'yes' AND ${is_won} = 'yes'

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
    value_format_name: usd_large

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
    sql: ${probability}
    value_format: "#%"
    
  - dimension: probability_group
    sql_case:
      'Won': ${probability} = 1
      'Above 80%': ${probability} > .8
      '60 - 80%': ${probability} > .6
      '40 - 60%': ${probability} > .4
      '20 - 40%': ${probability} > .2
      'Under 20%': ${probability} > 0
      'Lost': ${probability} = 0

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
    links: 
      - label: Pipeline Analysis Dashboard
        url: https://demonew.looker.com/dashboards/363
        icon_url: http://www.looker.com/favicon.ico
      
  - dimension: contract_value
    type: number
    sql: ${TABLE}.total_contract_value_c
    value_format: '$#,##0.00'

  - dimension: type
    sql: ${TABLE}.type
    
  - dimension: probable_contract_value
    type: number
    sql: (${probability} / 100.00) * ${contract_value}
    value_format_name: decimal_2
    drill_fields: [detail*]    
    
  - dimension: raw_created_date
    hidden: true
    sql: ${TABLE}.created_at  

 
# MEASURES #

  - measure: count
    type: count
    drill_fields: [id, stage_name_funnel, type, mrr]
#     filters:
#       account.type: Customer
#       opportunity.type: New Business

  - measure: count_current_quarter
    type: count
    filters:
      closed_quarter: this quarter
    drill_fields: opportunity_set*

  - measure: count_last_quarter
    type: count
    filters:
      closed_quarter: last quarter
    drill_fields: opportunity_set*
    
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
    drill_fields: [id, stage_name_funnel, type, mrr]
    
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
  
  - measure: count_won_current_quarter
    type: count
    filters:
      is_won: Yes
      closed_quarter: this quarter
    drill_fields:  [opportunity.id, account.name, salesrep.name, type, total_acv]
  
  - measure: count_won_last_quarter
    type: count
    filters:
      is_won: Yes
      closed_quarter: last quarter
    drill_fields: [opportunity.id, account.name, salesrep.name, type, total_acv]
  
  - measure: count_won_percent_change
    label: 'Count Won (% change from last quarter)'
    type: number
    sql: (${count_won_current_quarter} - ${count_won_last_quarter})/NULLIF(${count_won_last_quarter},0)
    value_format_name: percent_0
    html: |
      {% if value < -0.05 %}
       <p style="color: #353b49; background-color: #ed6168; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
      {% elsif value < 0.05 %}
       <p style="color: #353b49; background-color: #e9b404; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
       {% else %}
       <p style="color: #353b49; background-color: #49cec1; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
      {% endif %}
  
  - measure: total_mrr
    label: 'Total MRR (Closed/Won)'
    type: sum
    sql: ${mrr}
    filters:
      is_won: Yes    
    drill_fields: opportunity_set*
    value_format_name: usd_large
    
  - measure: total_pipeline_mrr
    type: sum
    sql: ${mrr}
    filters:
      is_closed: No
    drill_fields: opportunity_set*  
    value_format_name: usd_large
      
  - measure: average_mrr
    label: 'Average MRR (Closed/Won)'
    type: average
    sql: ${mrr}
    filters:
      is_won: Yes    
    drill_fields: opportunity_set*
    value_format: '$#,##0'

  - measure: total_contract_value
    label: 'Total Contract Value (Won)'
    type: sum
    sql: ${contract_value}
    filters:
     is_won: Yes    
    drill_fields: opportunity_set*
    value_format: '$#,##0'
    
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
  
  - measure: win_percentage_current_quarter
    type: number
    sql: 100.00 * ${count_won_current_quarter} / NULLIF(${count_current_quarter}, 0)
    value_format: '#0.00\%'    
  
  - measure: win_percentage_last_quarter
    type: number
    sql: 100.0 * ${count_won_last_quarter} / NULLIF (${count_last_quarter}, 0)
    value_format: '#0.00\%'
  
  - measure: win_percentage_change
    label: 'Win Percentage Change from Last Quarter'
    type: number
    sql: (${win_percentage_current_quarter} - ${win_percentage_last_quarter})/${win_percentage_last_quarter}
    value_format_name: percent_0
    html: |
      {% if value < -0.05 %}
       <p style="color: #353b49; background-color: #ed6168; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
      {% elsif value < 0.05 %}
       <p style="color: #353b49; background-color: #e9b404; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
       {% else %}
       <p style="color: #353b49; background-color: #49cec1; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
      {% endif %}
    
  - measure: open_percentage
    type: number
    sql: 100.00 * ${count_open} / NULLIF(${count}, 0)
    value_format: '#0.00\%'
    
  - measure: total_acv
    type: sum
    sql: ${acv}
    value_format_name: usd_large
    drill_fields: opportunity_set*

  - measure: total_churn_acv
    type: sum
    sql: ${acv}
    value_format_name: usd_large
    drill_fields: opportunity_set*
    filters:
      lost_reason: 'Non-renewal'
    
  - measure: total_expansion_acv
    type: sum
    sql: ${acv}
    value_format_name: usd_large
    drill_fields: opportunity_set*
    filters:
      type: 'Addon/Upsell'
      
  - measure: net_expansion
    type: number
    sql: ${total_expansion_acv} - ${total_churn_acv}
    value_format_name: usd_large
    drill_fields: opportunity_set*
    
  - measure: churn_acv #for Net Expansion Look
    type: sum
    sql: -1.0*${acv}
    value_format_name: usd_large
    drill_fields: opportunity_set*
    filters:
      lost_reason: 'Non-renewal'
    
  
    
  - filter: rep_name
    suggest_dimension: salesrep.name
    suggest_explore: the_switchboard
    
  - filter: sales_segment
    suggest_dimension: salesrep.business_segment
    suggest_explore: the_switchboard
    
  - measure: total_acv_won
    type: sum
    sql: ${acv}   
    filters:
      is_won: Yes
    value_format_name: usd_large 
    drill_fields: [account.name, type, closed_date, total_acv]

  - measure: total_acv_won_current_quarter
    type: sum
    sql: ${acv}
    filters:
      is_won: Yes
      closed_quarter: this quarter
    value_format_name: usd_large
    drill_fields: [account.name, type, closed_date, total_acv]     
  
  - measure: total_acv_won_last_quarter
    type: sum
    sql: ${acv}
    filters:
      is_won: Yes
      closed_quarter: last quarter
    value_format_name: usd_large
    drill_fields: opportunity_set*   

  - measure: total_acv_won_percent_change
    label: 'Total ACV Won Change from Last Quarter'
    type: number
    sql: (${total_acv_won_current_quarter} - ${total_acv_won_last_quarter})/ NULLIF(${total_acv_won_last_quarter},0)
    value_format_name: percent_0
    html: |
      {% if value < -0.05 %}
       <p style="color: #353b49; background-color: #ed6168; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
      {% elsif value < 0.05 %}
       <p style="color: #353b49; background-color: #e9b404; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
       {% else %}
       <p style="color: #353b49; background-color: #49cec1; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
      {% endif %}
  
  - measure: total_acv_lost
    type: sum
    sql: ${acv}   
    filters:
      is_won: No
    value_format_name: usd_large
    drill_fields: opportunity_set*
    
  - measure: total_pipeline_acv
    type: sum
    sql: ${acv}   
    filters:
      is_closed: No
    value_format_name: usd_large
    drill_fields: opportunity_set*
  
  - measure: total_pipeline_acv_m
    type: sum
    value_format_name: decimal_1
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
    
  - measure: total_acv_won_running_sum
    type: running_total
    sql: ${total_acv_won}
    
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
      - id
      - account.name
      - stage_name_funnel
      - type
      - mrr
    
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
      - created_quarter
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
      - total_acv_won
      - total_acv_won_current_quarter
      - total_acv_won_last_quarter
      
  derived_table:
    sql: |
      SELECT opportunity.*
        , MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(account.name), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
      FROM public.opportunity AS opportunity
      LEFT JOIN public.account AS account
      ON account.id = opportunity.account_id    
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))
    sortkeys: [closed_date]
    distkey: account_id  
    
    
