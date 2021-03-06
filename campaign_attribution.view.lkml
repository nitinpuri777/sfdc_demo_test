# Simple example of First Touch Attribution associating campaigns with leads
# Core logic used in Marketing Apps
view: campaign_attribution {
  derived_table: {
    sql: select
        a.lead_id,
        a.campaign_id,
        a.created_at
      from (
        select
          cm.lead_id,
          cm.campaign_id,
          cm.created_at,
          row_number() over (partition by cm.lead_id order by cm.created_at asc) as row_num
        from
          public.campaign_member as cm
        where
          cm.lead_id is not null
      ) as a
      where
        a.row_num = 1
       ;;

## As of11/2/2016, SFDC etl to redshift moved to 8pm PST (8PM Santa Cruz, 11PM Eastern, 4AM London)
## consequently, moving all ETLs to 9:30pm PST (9:30PM PST, 12:30am Eastern, 5:30AM London)
## note that London time shift by an hour in the week between US and Europe start dates for daylight savings
    sql_trigger_value: SELECT DATE(DATEADD('minute', 150, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', getdate()))) ;;


    distribution: "lead_id"
    sortkeys: ["created_at"]
  }

  filter: metric {
    type: string
    suggestions: ["Leads", "Opportunities", "ACV", "Days to Close"]
  }

  dimension: lead_id {
    type: string
    hidden: yes
    primary_key: yes
    sql: ${TABLE}.lead_id ;;
  }

  dimension: campaign_id {
    type: string
    hidden: yes
    sql: ${TABLE}.campaign_id ;;
  }

  dimension_group: first_campaign {
    type: time
    timeframes: [date, week, month, quarter, year]
    convert_tz: no
    sql: ${TABLE}.created_at ;;
  }

  dimension: marketing_channel {
    type: string
    sql: case
        when ${campaign.grouping} not in ('Outbound','Online: Paid','Online: Organic','Offline: Events')
        then 'Other'
        else ${campaign.grouping}
      end
       ;;
  }

  dimension: marketing_channel_split {
    type: string
    sql: concat(${marketing_channel},${first_campaign_week}) ;;
  }

  # Adjusts metric by using a templated filter indirectly
  # Requires filter only field 'Metric'
  measure: metric_amount {
    type: number
    sql: coalesce(
        sum(
          case
            when ${campaign_attribution_goals.metric} = 'ACV'
            then ${opportunity.acv}
            else null
          end)
        ,
        sum(
          case
            when ${campaign_attribution_goals.metric} = 'Days to Close'
            then ${opportunity.days_between_opportunity_created_and_closed_won}
            else 0
          end) /
        nullif(count(distinct
          case
            when ${campaign_attribution_goals.metric} = 'Days to Close'
            then
              case
                when ${opportunity.is_won}
                then ${opportunity.id}
                else null
              end
            else null
          end),0)
        ,
        count(distinct
          case
            when ${campaign_attribution_goals.metric} = 'Leads'
            then ${lead.id}
            when ${campaign_attribution_goals.metric} = 'Opportunities'
            then ${opportunity.id}
            else null
          end)
      )
       ;;
  }

  set: detail {
    fields: [lead_id, campaign_id]
  }
}
