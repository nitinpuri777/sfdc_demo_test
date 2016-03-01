- view: company
  derived_table:
    sql: |
      WITH temp_company AS ( SELECT DISTINCT MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(name), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
                              , TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(name), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', '')) AS name
                              , CASE
                                  WHEN type = 'Customer' AND current_customer_c
                                  THEN 'Customer'
                                  ELSE 'Prospect'
                                END AS type
                            FROM public.account
                            UNION
                            SELECT DISTINCT MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(company), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
                              , TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(company), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', '')) AS name
                              , 'Prospect' AS type
                            FROM public.lead)
      , temp_account AS ( SELECT MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(name), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
                            , MIN(id) AS id
                          FROM public.account
                          GROUP BY 1)
      SELECT ROW_NUMBER() OVER(ORDER BY 1) AS auto_id
        , temp_company.company_id
        , temp_company.type
        , temp_account.id AS account_id
        , temp_company.name
      FROM temp_company
      LEFT JOIN temp_account
      ON temp_company.company_id = temp_account.company_id
    sql_trigger_value: SELECT COUNT(*) FROM public.lead
    indexes: [company_id, account_id]
  fields:

# DIMENSIONS #

  - dimension: auto_id
    primary_key: true
    hidden: true
    type: number
    sql: ${TABLE}.auto_id
    
  - dimension: company_id
    hidden: true
    sql: ${TABLE}.company_id
    
  - dimension: account_id
    hidden: true
    sql: ${TABLE}.account_id
    
  - dimension: name
    sql: ${TABLE}.name

  - dimension: type
    sql: ${TABLE}.type

# MEASURES #

  - measure: count
    type: count
    drill_fields: company_set*

  - measure: count_prospect
    type: count
    filters:
      type: 'Prospect'
    drill_fields: company_set*
    
  - measure: count_customer
    type: count
    filters:
      type: 'Customer'
    drill_fields: [company.name, salesrep.name, usage.approximate_usage_in_minutes_total, opportunity.total_acv]
    
# SETS #  
    
  sets:
    company_set:
      - company_id
      - name
      - type