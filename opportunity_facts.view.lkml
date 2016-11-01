view: opportunity_facts {
  derived_table: {
    sql: SELECT account_id AS account_id
        , SUM(CASE
                WHEN stage_name = 'Closed Won'
                THEN 1
                ELSE 0
              END) AS opportunities_won
        , SUM(CASE
                WHEN stage_name = 'Closed Won'
                THEN acv
                ELSE 0
              END) AS all_time_acv
      FROM opportunity
      GROUP BY 1
       ;;
    sortkeys: ["account_id"]
    distribution: "account_id"
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())) ;;
  }

  # DIMENSIONS #

  dimension: account_id {
    hidden: yes
    primary_key: yes
    sql: ${TABLE}.account_id ;;
  }

  dimension: lifetime_opportunities_won {
    type: number
    sql: ${TABLE}.opportunities_won ;;
  }

  dimension: lifetime_acv {
    label: "Lifetime ACV"
    type: number
    sql: ${TABLE}.all_time_acv ;;
  }
}
