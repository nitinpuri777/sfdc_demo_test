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
## As of11/2/2016, SFDC etl to redshift moved to 8pm PST (8PM Santa Cruz, 11PM Eastern, 4AM London)
## consequently, moving all ETLs to 9:30pm PST (9:30PM PST, 12:30am Eastern, 5:30AM London)
## note that London time shift by an hour in the week between US and Europe start dates for daylight savings
    sql_trigger_value: SELECT DATE(DATEADD('minute', 150, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', getdate()))) ;;

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
