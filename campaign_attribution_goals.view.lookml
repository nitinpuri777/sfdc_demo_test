- view: campaign_attribution_stage
  derived_table:
    sql: |
      select
        TO_CHAR(DATE_TRUNC('quarter', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', campaign_attribution.created_at)), 'YYYY-MM') AS quarter,
        CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', campaign_attribution.created_at) AS created_date,
        case
          when campaign.grouping_c not in ('Outbound','Online: Paid','Online: Organic','Offline: Events')
          then 'Other'
          else campaign.grouping_c
        end as marketing_channel,
        count(distinct campaign_attribution.lead_id) as lead_count,
        count(distinct lead.converted_opportunity_id) as opportunity_count,
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
      
      
- view: campaign_attribution_goals
  derived_table:
    sql: |
      select
        goals.quarter_start_date,
        goals.quarter_end_date,
        goals.quarter,
        goals.marketing_channel,
        goals.metric,
        case
          when goals.metric = 'Leads'
          then prev_lead_count * (1+(CAST(STRTOL(LEFT(MD5(CONVERT(VARCHAR,concat(quarter,marketing_channel))),6),16) AS DECIMAL(9,0)) % 10)/100)
          when goals.metric = 'Opportunities'
          then prev_opportunity_count * (1+(CAST(STRTOL(LEFT(MD5(CONVERT(VARCHAR,concat(quarter,marketing_channel))),6),16) AS DECIMAL(9,0)) % 10)/100)
          when goals.metric = 'ACV'
          then prev_acv * (1+(CAST(STRTOL(LEFT(MD5(CONVERT(VARCHAR,concat(quarter,marketing_channel))),6),16) AS DECIMAL(9,0)) % 10)/100)
          else 0
        end as goal
      from
      (
        select
          campaign_attribution_goals.quarter_start_date,
          campaign_attribution_goals.quarter_end_date,
          campaign_attribution_goals.quarter,
          campaign_attribution_goals.marketing_channel,
          metrics.metric,
          coalesce(lag(campaign_attribution_goals.lead_count) over (partition by campaign_attribution_goals.marketing_channel order by campaign_attribution_goals.quarter),campaign_attribution_goals.lead_count) as prev_lead_count,
          coalesce(lag(campaign_attribution_goals.opportunity_count) over (partition by campaign_attribution_goals.marketing_channel order by campaign_attribution_goals.quarter),campaign_attribution_goals.opportunity_count) as prev_opportunity_count,
          coalesce(lag(campaign_attribution_goals.acv) over (partition by campaign_attribution_goals.marketing_channel order by campaign_attribution_goals.quarter),campaign_attribution_goals.acv) as prev_acv
        from
        (
          select
            quarter_dates.quarter_start_date,
            quarter_dates.quarter_end_date,
            stage_1.quarter,
            stage_1.marketing_channel,
            sum(stage_1.lead_count) as lead_count,
            sum(stage_1.opportunity_count) as opportunity_count,
            sum(stage_1.acv) as acv
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
          group by 1,2,3,4
        ) as campaign_attribution_goals
        cross join
        (
          select 'Leads' as metric
          union all
          select 'Opportunities' as metric
          union all
          select 'ACV' as metric
        ) as metrics
      ) as goals
      where
        {% condition ${campaign_attribution.metric} %} goals.metric {% endcondition %}
      group by 1,2,3,4,5,6
      
  fields:
  
  - dimension: id
    type: string
    primary_key: true
    hidden: true
    sql: concat(concat(${TABLE}.quarter,${TABLE}.marketing_channel),${TABLE}.metric)
  
  - dimension_group: quarter_start
    type: time
    timeframes: [date,week,month,quarter,year]
    convert_tz: false
    hidden: true
    sql: ${TABLE}.quarter_start_date
    
  - dimension_group: quarter_end
    type: time
    timeframes: [date,week,month,quarter,year]
    convert_tz: false
    hidden: true
    sql: ${TABLE}.quarter_end_date

  - dimension: quarter
    type: string
    hidden: true
    sql: ${TABLE}.quarter
    
  - dimension: marketing_channel
    type: string
    sql: ${TABLE}.marketing_channel
    
  - dimension: metric
    type: string
    hidden: true
    sql: ${TABLE}.metric
    
  - measure: goal
    type: sum
    sql: ${TABLE}.goal
      
      