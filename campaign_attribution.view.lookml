# Simple example of First Touch Attribution associating campaigns with leads
# Core logic used in Marketing Apps
- view: campaign_attribution
  derived_table:
    sql: |
      select
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
    sql_trigger_value: CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', select current_date)
    distkey: lead_id
    sortkeys: [created_at]

  fields:
  
  - filter: metric
    type: string
    suggestions: [Leads,Opportunities,ACV,Days to Close]

  - dimension: lead_id
    type: string
    hidden: true
    primary_key: true
    sql: ${TABLE}.lead_id

  - dimension: campaign_id
    type: string
    hidden: true
    sql: ${TABLE}.campaign_id

  - dimension_group: first_campaign
    type: time
    timeframes: [date,week,month,quarter,year]
    convert_tz: false
    sql: ${TABLE}.created_at
    
  - dimension: marketing_channel
    type: string
    sql: |
      case
        when ${campaign.grouping} not in ('Outbound','Online: Paid','Online: Organic','Offline: Events')
        then 'Other'
        else ${campaign.grouping}
      end
  
  - dimension: marketing_channel_split
    type: string
    sql: concat(${marketing_channel},${first_campaign_week})
      
  # Adjusts metric by using a templated filter indirectly
  # Requires filter only field 'Metric'   
  - measure: metric_amount
    type: number
    sql: |
      coalesce(
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

  sets:
    detail:
      - lead_id
      - campaign_id
      - attributed_date
      
