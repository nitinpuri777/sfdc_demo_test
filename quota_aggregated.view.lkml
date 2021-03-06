# Similar to the quota table, we created this to get team-level quotas.
# For most customers, this data would be stored in a different format,
# and a single quota table would likely suffice to give both individual and team-level aggregates.

view: quota_aggregated {
  derived_table: {
    sql_trigger_value: SELECT COUNT(1) FROM ${opportunity.SQL_TABLE_NAME} ;;
    sortkeys: ["quota_quarter"]
    distribution: "quota_quarter"
    sql: SELECT
        quota_quarter
        ,     sum(quota) as sales_team_quota
      FROM public.quota as quota
      GROUP BY quota_quarter
      ORDER BY quota_quarter asc
       ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension_group: quota {
    type: time
    timeframes: [quarter]
    convert_tz: no
    sql: ${TABLE}.quota_quarter ;;
  }

  dimension: quota_quarter_string {
    primary_key: yes
    hidden: yes
    sql: EXTRACT(YEAR FROM ${TABLE}.quota_quarter ) || ' - Q' || EXTRACT(QUARTER FROM ${TABLE}.quota_quarter) ;;
  }

  dimension: sales_team_quota {
    type: number
    sql: ${TABLE}.sales_team_quota ;;
    value_format_name: usd_0
  }

  measure: quota_sum {
    type: sum
    sql: ${sales_team_quota} ;;
  }

  measure: tracking_to_quota {
    type: number
    sql: 1.0* ${opportunity.total_acv_won} / NULLIF(${quota_sum},0) ;;
    value_format_name: percent_2
  }

  set: detail {
    fields: [quota_quarter, sales_team_quota]
  }
}
