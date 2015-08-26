- view: unit_of_account
  derived_table:
    sql: |
      SELECT DISTINCT MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(company), '([[:SPACE:]]|\\,)+(inc|INC|Inc|inc.|Inc.|llc|LLC|llc.|LLC.)$', ''))) AS company_id
        , TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(company), '([[:SPACE:]]|\\,)+(inc|INC|Inc|inc.|Inc.|llc|LLC|llc.|LLC.)$', '')) AS name
        , 'lead' AS type
      FROM lead
      UNION
      SELECT DISTINCT MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(name), '([[:SPACE:]]|\\,)+(inc|INC|Inc|inc.|Inc.|llc|LLC|llc.|LLC.)$', ''))) AS company_id
        , TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(name), '([[:SPACE:]]|\\,)+(inc|INC|Inc|inc.|Inc.|llc|LLC|llc.|LLC.)$', '')) AS name
        , CASE
            WHEN type = 'Customer'
            THEN 'customer'
            ELSE 'lead'
          END AS type
      FROM account
    persist_for: 2 hours
    sortkeys: [name]
    distkey: name
  fields:

# DIMENSIONS #
  
  - dimension: company_id
    primary_key: true
    sql: ${TABLE}.company_id

  - dimension: name
    sql: ${TABLE}.name

  - dimension: type
    sql: ${TABLE}.type

# MEASURES #

  - measure: count
    type: count
    drill_fields: detail*
    
# SETS #

  sets:
    detail:
      - name
      - type

