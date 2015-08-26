- view: person
  sql_table_name: public.person
  fields:

  - dimension: id
    primary_key: true
    sql: ${TABLE}.id

  - dimension: first_name
    sql: ${TABLE}.first_name

  - dimension: last_name
    sql: ${TABLE}.last_name

  - dimension: name
    sql: ${first_name} || ' ' || ${last_name}

  - measure: count
    type: count
    drill_fields: [id, first_name, last_name]

