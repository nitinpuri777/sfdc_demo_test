view: historical_snapshot {
  derived_table: {
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE())) ;;
    sortkeys: ["observation_date"]
    distribution: "opportunity_id"
    sql: WITH snapshot_window
      AS
      (SELECT opportunity_history.*
      ,COALESCE(LEAD(created_at,1) OVER (PARTITION BY opportunity_id ORDER BY created_at),getdate()) AS stage_end
      FROM opportunity_history
      )

      SELECT     dates.date AS observation_date
                ,snapshot_window.*

      FROM       snapshot_window
      LEFT JOIN ${dates.SQL_TABLE_NAME} as dates
                ON dates.date >= snapshot_window.created_at
                AND dates.date <= snapshot_window.stage_end

      WHERE dates.date <= getdate()
      AND   snapshot_window.opportunity_id not in ('006E000000PpVkjIAF-1', '006E000000LGyvPIAT-2', '006E000000LGyvPIAT-1')
       ;;
  }

  dimension_group: snapshot {
    type: time
    description: "What snapshot date are you interetsed in?"
    timeframes: [time, date, week, month]
    sql: ${TABLE}.observation_date ;;
  }

  dimension: id {
    type: string
    primary_key: yes
    sql: ${TABLE}.id ;;
  }

  dimension: opportunity_id {
    type: string
    sql: ${TABLE}.opportunity_id ;;
  }

  dimension: expected_revenue {
    type: number
    sql: ${TABLE}.expected_revenue ;;
  }

  dimension: amount {
    type: number
    sql: ${TABLE}.amount ;;
  }

  measure: total_amount {
    type: sum
    description: "At the time of snapshot, what was the total projected ACV?"
    sql: ${amount} ;;
    value_format: "$#,##0"
    drill_fields: [account.name, snapshot_date, close_date, amount, probability, stage_name_funnel]
  }

  dimension: stage_name {
    type: string
    hidden: yes
    sql: ${TABLE}.stage_name ;;
  }

  dimension: stage_name_funnel {
    description: "At the time of snapshot, what funnel stage was the prospect in?"

    case: {
      when: {
        sql: ${stage_name} IN ('Active Lead') ;;
        label: "Lead"
      }

      when: {
        sql: ${stage_name} like '%Prospect%' ;;
        label: "Prospect"
      }

      when: {
        sql: ${stage_name} like '%Trial%' ;;
        label: "Trial"
      }

      when: {
        sql: ${stage_name} IN ('Proposal','Commit- Not Won','Negotiation') ;;
        label: "Winning"
      }

      when: {
        sql: ${stage_name} IN ('Closed Won') ;;
        label: "Won"
      }

      when: {
        sql: ${stage_name} like '%Closed%' ;;
        label: "Lost"
      }

      when: {
        sql: true ;;
        label: "Unknown"
      }
    }
  }

  dimension: probability {
    type: number
    sql: ${TABLE}.probability ;;
  }

  dimension: probability_tier {
    case: {
      when: {
        sql: ${probability} = 100 ;;
        label: "Won"
      }

      when: {
        sql: ${probability} >= 80 ;;
        label: "80 - 99%"
      }

      when: {
        sql: ${probability} >= 60 ;;
        label: "60 - 79%"
      }

      when: {
        sql: ${probability} >= 40 ;;
        label: "40 - 59%"
      }

      when: {
        sql: ${probability} >= 20 ;;
        label: "20 - 39%"
      }

      when: {
        sql: ${probability} > 0 ;;
        label: "1 - 19%"
      }

      when: {
        sql: ${probability} = 0 ;;
        label: "Lost"
      }
    }
  }

  dimension_group: created_at {
    type: time
    hidden: yes
    timeframes: [time, date, week, month]
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: close {
    type: time
    description: "At the time of snapshot, what was the projected close date?"
    timeframes: [date, week, month, quarter]
    sql: to_date (${TABLE}.close_date, 'YYYY-MM-DD') ;;
  }

  #     sql: ${TABLE}.close_date

  dimension_group: stage_end {
    type: time
    hidden: yes
    timeframes: [time, date, week, month]
    sql: ${TABLE}.stage_end ;;
  }

  measure: count_opportunities {
    type: count_distinct
    sql: ${opportunity_id} ;;
  }

  set: detail {
    fields: [snapshot_time, id, opportunity_id, expected_revenue, amount, stage_name, created_at_time, close_date, stage_end_time]
  }
}
