- view: lead_facts
  derived_table:
    sql: |
      SELECT DISTINCT company AS company_name
        , FIRST_VALUE(name) OVER(PARTITION BY company ORDER BY created_at ROWS UNBOUNDED PRECEDING) AS first_lead_name
        , FIRST_VALUE(title) OVER(PARTITION BY company ORDER BY created_at ROWS UNBOUNDED PRECEDING) AS first_lead_title
        , FIRST_VALUE(email) OVER(PARTITION BY company ORDER BY created_at ROWS UNBOUNDED PRECEDING) AS first_lead_email
        , FIRST_VALUE(created_at) OVER(PARTITION BY company ORDER BY created_at ROWS UNBOUNDED PRECEDING) AS first_lead_created_date
        , LAST_VALUE(name) OVER(PARTITION BY company ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_lead_name
        , LAST_VALUE(title) OVER(PARTITION BY company ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_lead_title
        , LAST_VALUE(email) OVER(PARTITION BY company ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_lead_email
        , LAST_VALUE(created_at) OVER(PARTITION BY company ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_lead_created_date
      FROM lead
    sql_trigger_value: SELECT CURRENT_DATE
    sortkeys: [company_name]
    distkey: company_name
  fields:

# DIMENSIONS #

  - dimension: company_id
    hidden: true
    primary_key: true
    sql: MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(${company_name}), '([[:SPACE:]]|\\,)+(inc|INC|Inc|inc.|Inc.|llc|LLC|llc.|LLC.)$', '')))    
    
  - dimension: company_name
    hidden: true
    sql: ${TABLE}.company_name
    
  - dimension: first_lead_name
    sql: ${TABLE}.first_lead_name

  - dimension: first_lead_title
    sql: ${TABLE}.first_lead_title

  - dimension: first_lead_email
    sql: ${TABLE}.first_lead_email
    
  - dimension_group: first_lead_created
    type: time
    timeframes: [date, week, month, year]
    sql: ${TABLE}.first_lead_created_date

  - dimension: last_lead_name
    sql: ${TABLE}.last_lead_name

  - dimension: last_lead_title
    sql: ${TABLE}.last_lead_title
    
  - dimension: last_lead_email
    sql: ${TABLE}.last_lead_email
    
  - dimension_group: last_lead_created
    type: time
    timeframes: [date, week, month, year]
    sql: ${TABLE}.last_lead_created_date
