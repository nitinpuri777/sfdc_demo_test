
- view: quota
  derived_table:
    persist_for: 24 hours
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

  - dimension_group: quota_quarter
    type: time
    timeframes: [time, date, week, month, quarter,raw]
    sql: ${TABLE}.quota_quarter
    convert_tz: false

  - dimension: quota_quarter_person_id
    type: string
    primary_key: true
    hidden: true
    sql: ${person_id} || '_' || ${quota_quarter_time}
    
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
      quota_quarter_quarter: this quarter
  
  - measure: sum_quota_last_quarter
    type: sum
    sql: ${quota}
    filters:
      quota_quarter_quarter: last quarter
  
  - measure: tracking_to_quota
    type: number
    sql: 1.0* ${opportunity.total_acv_won} / NULLIF(${quota.sum_quota},0)
    value_format_name: percent_2
    
  - measure: tracking_to_quota_current_quarter
    type: number
    sql: 1.0* ${opportunity.total_acv_won_current_quarter} / NULLIF(${quota.sum_quota_current_quarter},0)
    value_format_name: percent_2
     
  - measure: tracking_to_quota_last_quarter
    type: number
    sql: 1.0* ${opportunity.total_acv_won_last_quarter} / NULLIF(${quota.sum_quota_last_quarter},0)
    value_format_name: percent_2
    
  - measure: tracking_to_quota_change
    label: 'Tracking to Quota (change from last quarter)'
    type: number
    sql: ${tracking_to_quota} - ${tracking_to_quota_last_quarter}
    value_format_name: percent_2
    html: |
      {% if value > 0.2 %}
       <p style="color: black; background-color: #41A317; font-size:100%; text-align:center">{{ rendered_value }}</p>
      {% elsif value >-0.2 %}
       <p style="color: black; background-color: yellow; font-size:100%; text-align:center">{{ rendered_value }}</p>
      {% else %}
       <p style="color: black; background-color: #E41B17; font-size:100%; text-align:center">{{ rendered_value }}</p>
      {% endif %}
  


    