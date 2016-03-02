- view: account
  derived_table:
    sql: |
      SELECT *
        , MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(name), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
      FROM public.account
    sql_trigger_value: SELECT COUNT(*) FROM account
    indexes: [created_at, company_id]     # using indexes for interleaved sort keys
    distkey: company_id      
  fields:

# DIMENSIONS #

  - dimension: id
    primary_key: true
    sql: ${TABLE}.id
    links:
      - label: Salesforce Account
        url: https://blog.internetcreations.com/wp-content/uploads/2012/09/Business-Account_-Internet-Creations-salesforce.com-Enterprise-Edition-1.jpg
        icon_url: http://www.salesforce.com/favicon.ico

  - dimension: company_id
    hidden: true
    sql: ${TABLE}.company_id
    
  - dimension: account_status
    sql: COALESCE(${TABLE}.account_status_c, 'Unknown')

#   - dimension: annual_revenue
#     type: number
#     sql: ${TABLE}.annual_revenue::NUMERIC
  
  - dimension: campaign
    hidden: true
    sql: ${TABLE}.campaign2_c

  - dimension: city
    sql: ${TABLE}.city

  - dimension: country
    sql: ${TABLE}.country

  - dimension_group: created
    type: time
    timeframes: [date, week, month, year]
    sql: ${TABLE}.created_at

  - dimension: current_customer
    type: yesno
    sql: ${TABLE}.current_customer_c

#   - dimension_group: customer_end
#     type: time
#     timeframes: [date, week, month]
#     convert_tz: false
#     sql: ${TABLE}.customer_end_date_c

  - dimension: customer_reference
    type: yesno
    sql: ${TABLE}.customer_reference_c

  - dimension_group: customer_start
    type: time
    timeframes: [date, week, month, year]
    convert_tz: false
    sql: ${TABLE}.customer_start_date_c

  - dimension: engagement_stage
    sql_case:
      'Customer': ${current_customer} = 'Yes'
      'Engaged': ${current_customer} = 'No' AND ${TABLE}.engagement_stage_c IS NOT NULL
      else: 'Prospecting'

# only 3 partners, deleting
#   - dimension: is_partner
#     type: yesno
#     sql: ${TABLE}.is_partner

#  nearly all are tech or "other", we should use Account Vertical or Salesrep Business Segment instead
#   - dimension: market_segment
#     sql: COALESCE(${TABLE}.market_segment_c, 'Other')

  - dimension: name
    sql: ${TABLE}.name

  - dimension: number_of_employees
    type: number
    sql: ${TABLE}.number_of_employees

  - dimension: owner_id
    hidden: true
    sql: ${TABLE}.owner_id

  - dimension: state
    sql: ${TABLE}.state
    
# We should consider removing this, unless we really want to build something around partnerships    
  - dimension: type
    sql: NVL(${TABLE}.type,'Customer')    # default the type to customer

  - dimension: url
    sql: ${TABLE}.url
    links:
      - label: Website
        url: '{{ value }}'
        icon_url: http://www.google.com/s2/favicons?domain_url={{ value | encode_uri }}
             
  - dimension: vertical
    sql: ${TABLE}.vertical_c

  - dimension: zendesk_organization
    hidden: true
    sql: ${TABLE}.zendesk_organization

#   - dimension: annual_revenue_tier
#     type: tier
#     tiers: [0,10000,100000,1000000,10000000,100000000]
#     sql: ${TABLE}.annual_revenue  
    
  - dimension: number_of_employees_tier
    type: tier
    tiers: [0,50,100,500,1000,10000]
    sql: ${number_of_employees}
    
# MEASURES #

  - measure: count
    type: count
    drill_fields: [id, name]
    
  - measure: percent_of_accounts
    type: percent_of_total
    sql: ${count}
#     
#   - measure: average_annual_revenue
#     type: average
#     sql: ${annual_revenue}
#     value_format: '$#,##0'
    
  - measure: total_number_of_employees
    type: sum
    sql: ${number_of_employees}
    
  - measure: average_number_of_employees
    type: avg
    sql: ${number_of_employees}
    
# SETS #

  sets:
    export_set:
      - id
      - company_id
      - account_status
      - city
      - created_date
      - current_customer
      - customer_start_date
      - engagement_stage
      - name
      - number_of_employees
      - state
      - type
      - url
      - vertical
      - zendesk_organization
      - number_of_employees_tier
      - count
      - percent_of_accounts
      - total_number_of_employees
      - average_number_of_employees  
      - owner_id