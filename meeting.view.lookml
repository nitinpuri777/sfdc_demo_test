- view: meeting
  derived_table:
    sql: |
      SELECT *
      FROM task
      WHERE type = 'Intro Meeting'
    sql_trigger_value: SELECT COUNT(*) FROM task
    sortkeys: [account_id]
  fields:
  
# FILTER-ONLY FIELDS #

  - filter: meeting_goal
    description: 'Enter an integer greater than zero.'

# DIMENSIONS #

  - dimension: id
    primary_key: true
    sql: ${TABLE}.id

  - dimension: who_id
    hidden: true
    sql: ${TABLE}.who_id

  - dimension: what_id
    hidden: true
    sql: ${TABLE}.what_id

# Custom text field, Nearly always just "Intro Meeting"
#   - dimension: subject
#     sql: ${TABLE}.subject

#  This is nearly always the same or before the meeting date. I'm going to therefore assume that the meeting date is the actual date the meeting ocurred, since it it later
#   - dimension_group: activity
#     type: time
#     timeframes: [date, week, month, year]
#     sql: ${TABLE}.activity_date

  - dimension: status
    sql: ${TABLE}.status

# Always Normal
#   - dimension: priority
#     sql: ${TABLE}.priority

  - dimension: owner_id
    hidden: true
    sql: ${TABLE}.owner_id

# This contains actual Looker notes, so we should hide it
#   - dimension: description
#     sql: ${TABLE}.description

#  Always "Intro Meeting"
#   - dimension: type
#     sql: ${TABLE}.type

  - dimension: account_id
    hidden: true
    sql: ${TABLE}.account_id

  - dimension: lead_id
    hidden: true
    sql: ${TABLE}.lead_id
    
  - dimension: is_closed
    type: yesno
    sql: ${TABLE}.is_closed

  - dimension_group: created
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.created_date

  - dimension: last_modified_by_id
    hidden: true
    sql: ${TABLE}.last_modified_by_id

  - dimension: created_quarter
    sql: EXTRACT(YEAR FROM ${TABLE}.created_date) || ' - Q' || EXTRACT(QUARTER FROM ${TABLE}.created_date)
    
  - dimension: created_current_quarter
    type: yesno
    sql: EXTRACT(QUARTER FROM ${TABLE}.created_date) || EXTRACT(YEAR FROM ${TABLE}.created_date) = EXTRACT(QUARTER FROM CURRENT_DATE) || EXTRACT(YEAR FROM CURRENT_DATE)    

  - dimension: created_by_id
    hidden: true
    sql: ${TABLE}.created_by_id

  - dimension: call_type
    hidden: true
    sql: ${TABLE}.calltype
    
# Nearly all are demo meetings
#   - dimension: meeting_type
#     sql: COALESCE(${TABLE}.meeting__type___c, 'Demo')

# Always null
#   - dimension_group: completed
#     type: time
#     timeframes: [date, week, month, year]
#     sql: ${TABLE}.completed__date___c

  - dimension_group: meeting
    type: time
    timeframes: [date, week, month, year]  
    sql: ${TABLE}.meeting__date__time___c

  - dimension: sdr_meeting_assist
    hidden: true
    sql: ${TABLE}.sdr__meeting__assist___c

#  Always No
#   - dimension: is_high_priority
#     type: yesno
#     sql: ${TABLE}.is_high_priority

#   - dimension: call_duration_in_seconds
#     sql: ${TABLE}.call_duration_in_seconds
# 
#   - dimension: call_disposition
#     sql: ${TABLE}.call_disposition
# 
#   - dimension: call_object
#     sql: ${TABLE}.call_object

# Has data, but I don't know what it is...
#   - dimension_group: reminder
#     type: time
#     timeframes: [time, date, week, month]
#     sql: ${TABLE}.reminder_date_time

# Always no
#   - dimension: is_reminder_set
#     type: yesno
#     sql: ${TABLE}.is_reminder_set


  - dimension: recurrence_activity_id
    hidden: true
    sql: ${TABLE}.recurrence_activity_id

# Always no
#   - dimension: is_recurrence
#     type: yesno
#     sql: ${TABLE}.is_recurrence

  - dimension: number_of_no_shows
    sql: ${TABLE}.number__of__no__shows___c
    
  - dimension: raw_meeting_date
    hidden: true
    sql: CASE WHEN ${status} = 'Completed' THEN ${TABLE}.meeting__date__time___c ELSE NULL END  

# MEASURES #

  - measure: count
    type: count
    drill_fields: meeting_set*
    
  - measure: meetings_completed
    type: count
    filters:
      status: 'Completed'
    drill_fields: meeting_set*  
    
  - measure: percent_to_goal
    type: number
    value_format: '#%'
    sql: 1.00 * ${count} / NULLIF({%parameter meeting_goal %}, '')

  - measure: successful_meetings
    description: 'Meetings that occurred'
    type: count
    filters: 
      is_closed: yes
    drill_fields: meeting_set*

  - measure: unsuccessful_meetings
    description: 'Meetings that did not happen'
    type: count
    filters: 
      is_closed: no
    drill_fields: meeting_set*
    
  - measure: successful_meeting_rate
    description: 'Percent of booked meetings that occurred'
    type: number
    sql: 1.00 * ${successful_meetings} / NULLIF(${count}, 0)
    value_format: '#0.00%'
    
# SETS #

  sets:
    meeting_set:
      - id
      - status
      - account.name
      - is_closed
      - created_date
      
    export_set:
      - id
      - who_id
      - what_id
      - account_id
      - lead_id
      - is_closed
      - created_date
      - completed_date
      - meeting_date_time
      - count
      - percent_to_goal

