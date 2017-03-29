view: opportunity_dates {
  derived_table: {
    sql: SELECT account_id AS account_id
        , MIN(closed_date) AS first_opp_date
        , MIN(CASE
                WHEN stage_name = 'Closed Won'
                THEN closed_date
                ELSE NULL
              END) AS first_opp_won_date
        , MIN(CASE
                WHEN type = 'Renewal'
                  AND stage_name = 'Active Lead'
                THEN closed_date
                ELSE NULL
              END) AS next_renewal_date
      FROM opportunity
      GROUP BY 1
       ;;
    sortkeys: ["first_opp_date"]
    distribution: "account_id"
## As of11/2/2016, SFDC etl to redshift moved to 8pm PST (8PM Santa Cruz, 11PM Eastern, 4AM London)
## consequently, moving all ETLs to 9:30pm PST (9:30PM PST, 12:30am Eastern, 5:30AM London)
## note that London time shift by an hour in the week between US and Europe start dates for daylight savings
    sql_trigger_value: SELECT DATE(DATEADD('minute', 150, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', getdate()))) ;;

  }

  # DIMENSIONS #

  dimension: account_id {
    hidden: yes
    sql: ${TABLE}.account_id ;;
  }


  dimension_group: first_opp {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.first_opp_date ;;
  }

  dimension_group: first_opp_won {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.first_opp_won_date ;;
  }

  dimension_group: next_renewal {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.next_renewal_date ;;
  }
}
