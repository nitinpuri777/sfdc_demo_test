
- view: opportunity_dates
  derived_table:
    sql: |
      SELECT accountid AS account_id
        , MIN(name) AS name
        , MIN(closedate) AS first_opp_date
        , MIN(CASE
                WHEN stagename = 'Closed Won'
                THEN closedate
                ELSE NULL
              END) AS first_opp_won_date
        , MIN(CASE
                WHEN type = 'Renewal'
                  AND stagename = 'Active Lead'
                THEN closedate
                ELSE NULL
              END) AS next_renewal_date
      FROM opportunity
      GROUP BY 1
    sortkeys: [first_opp_date]
    distkey: account_id
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))
  fields:

# DIMENSIONS #

  - dimension: account_id
    hidden: true
    sql: ${TABLE}.account_id
    
  - dimension: name
    sql: ${TABLE}.name

  - dimension_group: first_opp
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.first_opp_date

  - dimension_group: first_opp_won
    type: time
    timeframes: [date, week, month]  
    sql: ${TABLE}.first_opp_won_date
    
  - dimension_group: next_renewal
    type: time
    timeframes: [date, week, month]  
    sql: ${TABLE}.next_renewal_date