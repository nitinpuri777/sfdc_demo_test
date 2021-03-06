# Creates a table generating goals for ACV, Leads and Opportunities by Marketing Channel
# Initial Purpose for Marketing App which displays channels, metrics and quarters
view: campaign_attribution_stage {
  derived_table: {
    sql: select
        TO_CHAR(DATE_TRUNC('quarter', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', campaign_attribution.created_at)), 'YYYY-MM') AS quarter,
        CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', campaign_attribution.created_at) AS created_date,
        case
          when campaign.grouping_c not in ('Outbound','Online: Paid','Online: Organic','Offline: Events')
          then 'Other'
          else campaign.grouping_c
        end as marketing_channel,
        count(distinct campaign_attribution.lead_id) as lead_count,
        count(distinct lead.converted_opportunity_id) as opportunity_count,
        sum(case
          when opportunity.is_won
          then
            case
              when DATEDIFF(DAYS, opportunity.created_at, COALESCE(opportunity.closed_date, current_date)) < 0
              then 0
              else DATEDIFF(DAYS, opportunity.created_at, COALESCE(opportunity.closed_date, current_date))
            end
          else null
        end) as total_days_to_close_won,
        count(distinct
          case
            when opportunity.is_won
            then opportunity.id
            else null
          end) as closed_won_count,
        sum(opportunity.acv) as acv
      from
        ${campaign_attribution.SQL_TABLE_NAME} AS campaign_attribution
      left join
        public.campaign AS campaign
          on campaign_attribution.campaign_id = campaign.id
      left join
        ${lead.SQL_TABLE_NAME} AS lead
          on campaign_attribution.lead_id = lead.id
      left join
        ${opportunity.SQL_TABLE_NAME} AS opportunity
          on lead.converted_opportunity_id = opportunity.id
      where
        CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', campaign_attribution.created_at)::date >= '2015-01-01'
      group by 1,2,3
       ;;

## As of11/2/2016, SFDC etl to redshift moved to 8pm PST (8PM Santa Cruz, 11PM Eastern, 4AM London)
## consequently, moving all ETLs to 9:30pm PST (9:30PM PST, 12:30am Eastern, 5:30AM London)
## note that London time shift by an hour in the week between US and Europe start dates for daylight savings
    sql_trigger_value: SELECT DATE(DATEADD('minute', 150, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', getdate()))) ;;

    distribution: "quarter"
    sortkeys: ["marketing_channel", "created_date"]
  }
}

#: Final DT includes templated filter
#  Uses a Hash to create goals
view: campaign_attribution_goals {
  derived_table: {
    sql: select
        goals.quarter_start_date,
        goals.quarter_end_date,
        goals.quarter,
        goals.marketing_channel,
        goals.metric,
        goals.prev_metric_amount * (1+(3*(CAST(STRTOL(LEFT(MD5(CONVERT(VARCHAR,concat(quarter,marketing_channel))),6),16) AS DECIMAL(9,0)) % 10)/100)) as goal
      from
      (
        select
          campaign_attribution_goals.quarter_start_date,
          campaign_attribution_goals.quarter_end_date,
          campaign_attribution_goals.quarter,
          campaign_attribution_goals.marketing_channel,
          campaign_attribution_goals.metric,
          coalesce(lag(campaign_attribution_goals.metric_amount)
            over (partition by campaign_attribution_goals.marketing_channel,campaign_attribution_goals.metric order by campaign_attribution_goals.quarter),campaign_attribution_goals.metric_amount) as prev_metric_amount
        from
        (
          select
            quarter_dates.quarter_start_date,
            quarter_dates.quarter_end_date,
            stage_1.quarter,
            stage_1.marketing_channel,
            metrics.metric,
            sum(case
              when metrics.metric = 'Leads'
              then stage_1.lead_count
              when metrics.metric = 'Opportunities'
              then stage_1.opportunity_count
              when metrics.metric = 'ACV'
              then stage_1.acv
              else 0
            end) as metric_amount
          from
            ${campaign_attribution_stage.SQL_TABLE_NAME} as stage_1
          inner join
          (
            select
              quarter,
              min(created_date)::date as quarter_start_date,
              max(created_date)::date as quarter_end_date
            from
              ${campaign_attribution_stage.SQL_TABLE_NAME}
            group by 1
          ) as quarter_dates
            on stage_1.quarter = quarter_dates.quarter
          cross join
          (
            select 'Leads' as metric
            union all
            select 'Opportunities' as metric
            union all
            select 'ACV' as metric
            union all
            select 'Days to Close' as metric
          ) as metrics
            group by 1,2,3,4,5
        ) as campaign_attribution_goals
      ) as goals
      where
        {% condition ${campaign_attribution.metric} %} goals.metric {% endcondition %}
      group by 1,2,3,4,5,6
       ;;
  }

  dimension: id {
    type: string
    primary_key: yes
    hidden: yes
    sql: concat(concat(${TABLE}.quarter,${TABLE}.marketing_channel),${TABLE}.metric) ;;
  }

  dimension_group: quarter_start {
    type: time
    timeframes: [date, week, month, quarter, year]
    convert_tz: no
    hidden: yes
    sql: ${TABLE}.quarter_start_date ;;
  }

  dimension_group: quarter_end {
    type: time
    timeframes: [date, week, month, quarter, year]
    convert_tz: no
    hidden: yes
    sql: ${TABLE}.quarter_end_date ;;
  }

  dimension: quarter {
    type: string
    hidden: yes
    sql: ${TABLE}.quarter ;;
  }

  dimension: marketing_channel {
    type: string
    hidden: yes
    sql: ${TABLE}.marketing_channel ;;
  }

  dimension: metric {
    type: string
    hidden: yes
    sql: ${TABLE}.metric ;;
  }

  measure: goal {
    type: sum
    sql: ${TABLE}.goal ;;
  }
}
