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

  fields:

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
    sql: ${TABLE}.created_at

  sets:
    detail:
      - lead_id
      - campaign_id
      - attributed_date
      
