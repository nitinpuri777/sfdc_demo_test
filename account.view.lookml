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

  - dimension: account_tier
    type: string
    sql: |
      CASE
        WHEN ${current_customer} = 'Yes' AND ${salesrep.business_segment} = 'Enterprise' THEN 'Gold'
        WHEN ${salesrep.business_segment} = 'Enterprise' THEN 'Silver'
        WHEN ${salesrep.business_segment} = 'Mid-Market' THEN 'Silver'
        ELSE 'Bronze'
      END
    html: |
      {% if rendered_value == 'Bronze' %}
        <div style="color: #f6f8fa; text-align:center; border:1px solid #e6e6e6; background-color: #cd7f32; font-size:200%;">{{ rendered_value }}</div>
      {% elsif rendered_value == 'Silver' %}
        <div style="color: #f6f8fa; text-align:center; border:1px solid #e6e6e6; background-color: silver; font-size:200%;">{{ rendered_value }}</div>
      {% elsif rendered_value == 'Gold' %}
        <div style="color: #f6f8fa; text-align:center; border:1px solid #e6e6e6; background-color: gold; font-size:200%;">{{ rendered_value }}</div>
      {% else %}
        {{ rendered_value }}
      {% endif %}
  
  - dimension: campaign
    hidden: true
    sql: ${TABLE}.campaign2_c

  - dimension: city
    sql: ${TABLE}.city

  - dimension: country
    drill_fields: [city, state]
    map_layer: countries
    sql: ${TABLE}.country

  - dimension_group: created
    type: time
    timeframes: [time, date, week, month, year]
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
    timeframes: [time, date, week, month, year]
    convert_tz: false
    sql: ${TABLE}.customer_start_date_c
    

  - dimension: engagement_stage
    sql_case:
      'Customer': ${current_customer} = 'Yes'
      'Engaged': ${current_customer} = 'No' AND ${TABLE}.engagement_stage_c IS NOT NULL
      else: 'Prospecting'

  - dimension: name
    sql: ${TABLE}.name
    links:
      - label: Customer Lookup Dashboard
        url: http://demonew.looker.com/dashboards/279?Account%20Name={{ value  }}
        icon_url: http://www.looker.com/favicon.ico
      - label: Salesforce Account
        url: https://blog.internetcreations.com/wp-content/uploads/2012/09/Business-Account_-Internet-Creations-salesforce.com-Enterprise-Edition-1.jpg
        icon_url: http://www.salesforce.com/favicon.ico
        
  - dimension: number_of_employees
    type: number
    sql: ${TABLE}.number_of_employees

  - dimension: owner_id
    hidden: true
    sql: ${TABLE}.owner_id

  - dimension: state
    drill_fields: [city]
    map_layer: us_states
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
    type: string
    sql: (COALESCE(${TABLE}.vertical_c, ${TABLE}.market_segment_c))
    
  - dimension: vertical_segment
    type: string
    sql: |
         CASE 
         WHEN ${vertical} = 'Retail, eCommerce & Marketplaces' THEN 'Retail'
         WHEN ${vertical} = 'Technology' THEN 'Technology'
         WHEN ${vertical} = 'Software & SaaS' THEN 'Software'
         WHEN ${vertical} = 'Ad Tech & Online Media' THEN 'Digital Advertising'
         ELSE ${vertical}
         END
    
#         Retail: ${vertical} = 'Retail, eCommerce & Marketplaces'
#         Technology: 'Technology'
#         Software:  'Software & SaaS'
#         Digital Advertising: 'Ad Tech & Online Media'
#         Finance & Payments: 'Finance & Payments'
#         Non-profit & Education: 'Non-profit & Education'
#         Mobile & Gaming: 'Mobile & Gaming'
#         Health: 'Health'
#         Enterprise: 'Enterprise'
#         Agency: 'Agency'

  - dimension: zendesk_organization
    hidden: true
    sql: ${TABLE}.zendesk_organization
    
  - dimension: number_of_employees_tier
    type: tier
    tiers: [0,10,50,100,500,1000,10000]
    sql: ${number_of_employees}
    
# MEASURES #

  - measure: count
    type: count
    drill_fields: detail*
    
  - measure: percent_of_accounts
    type: percent_of_total
    sql: ${count}
    drill_fields: detail*
    
  - measure: total_number_of_employees
    type: sum
    sql: ${number_of_employees}
    drill_fields: detail*
    
  - measure: average_number_of_employees
    type: avg
    sql: ${number_of_employees}
    drill_fields: detail*
    
# SETS #

  sets:
    detail:
      - id
      - name
      - account_status
      - accoutn_tier
      - city
      - state
      - number_of_employees_tier
      
    export_set:
      - id
      - company_id
      - account_status
      - account_tier
      - city
      - created_time
      - created_date
      - created_week
      - created_month
      - current_customer
      - customer_start_time
      - customer_start_date
      - customer_start_week
      - customer_start_month
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
