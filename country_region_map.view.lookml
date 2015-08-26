- view: country_region_map
  sql_table_name: public.country_region_map
  fields:

  - dimension: continent
    sql: ${TABLE}.continent

  - dimension: continent_name
    sql: ${TABLE}.continent_name

  - dimension: country_name
    sql: ${TABLE}.country_name

  - dimension: three_char_code
    sql: ${TABLE}.three_char_code

  - dimension: two_char_code
    sql: ${TABLE}.two_char_code

  - measure: count
    type: count
    drill_fields: [country_name, continent_name]

