view: license {
  sql_table_name: public.license ;;

  dimension: license_slug {
    sql: ${TABLE}.license_slug ;;
  }

  dimension: salesforce_account_id {
    sql: ${TABLE}.salesforce_account_id ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }
}
