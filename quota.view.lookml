# We're using this derived table to create quotas for our fictional company. 
# Most companies have this either built into their SFDC data or as a separate table in their database, 
# and wouldn't build a table out here.


- view: quota
  derived_table:
    persist_for: 24 hours
    distribution_style: ALL
    sortkeys: quota_quarter
    sql: |
            SELECT 
               person_id
              , quota_quarter
              ,     (
                    case
                    when datediff(day, quota_quarter, current_date) < 90
                    then 90 / datediff(day, quota_quarter, current_date) * quota
                    else quota
                    end)
                    as quota
            FROM public.quota quota
  fields:

  - dimension: person_id
    type: string
    # hidden: true
    sql: ${TABLE}.person_id

  - dimension: quota
    type: number
    sql: ${TABLE}.quota

  - dimension_group: quota
    type: time
    timeframes: [time, date, week, month, quarter,raw]
    sql: ${TABLE}.quota_quarter
    convert_tz: false

  - dimension: quota_quarter_person_id
    type: string
    primary_key: true
    hidden: true
    sql: ${person_id} || '_' || ${quota_time}
    
  - measure: count
    type: count
    drill_fields: [person.id, person.first_name, person.last_name]

  - measure: sum_quota
    type: sum
    sql: ${quota}
  
  - measure: sum_quota_current_quarter
    type: sum
    sql: ${quota}
    filters: 
      quota_quarter: this quarter
  
  - measure: sum_quota_last_quarter
    type: sum
    sql: ${quota}
    filters:
      quota_quarter: last quarter
  
  - measure: pace
    type: number
    sql: 1.0* ${opportunity.total_acv_won} / NULLIF(${quota.sum_quota},0)
    value_format_name: percent_2
    
  - measure: pace_current_quarter
    type: number
    sql: 1.0* ${opportunity.total_acv_won_current_quarter} / NULLIF(${quota.sum_quota_current_quarter},0)
    value_format_name: percent_2
     
  - measure: pace_last_quarter
    type: number
    sql: 1.0* ${opportunity.total_acv_won_last_quarter} / NULLIF(${quota.sum_quota_last_quarter},0)
    value_format_name: percent_2
    
  - measure: pace_change
    label: 'Pace Change from Last Quarter'
    type: number
    sql: (${pace_current_quarter} - ${pace_last_quarter})/NULLIF(${pace_last_quarter},0)
    value_format_name: percent_0
    html: |
      {% if value < -0.05 %}
       <p style="color: #353b49; background-color: #ed6168; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
      {% elsif value < 0.05 %}
       <p style="color: #353b49; background-color: #e9b404; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
       {% else %}
       <p style="color: #353b49; background-color: #49cec1; font-size:100%; text-align:center; border-radius: 5px;">{{ rendered_value }}</p>
      {% endif %}
  

    