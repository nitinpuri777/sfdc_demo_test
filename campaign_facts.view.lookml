- view: account_campaign
  derived_table:
    sql: |
      WITH campaign_summary AS (SELECT DISTINCT account_contact_role.accountid AS account_id
                                  , CASE
                                      WHEN account_contact_role.role = 'Economic Decision Maker'
                                      THEN FIRST_VALUE(campaign_id) OVER(PARTITION BY account_contact_role.accountid ORDER BY campaign_member.created_at ROWS UNBOUNDED PRECEDING)
                                      ELSE NULL
                                    END AS first_economic_contact_campaign_id
                                  , CASE
                                      WHEN account_contact_role.role = 'Economic Decision Maker'
                                      THEN LAST_VALUE(campaign_id) OVER(PARTITION BY account_contact_role.accountid ORDER BY campaign_member.created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                      ELSE NULL
                                    END AS last_economic_contact_campaign_id    
                                  , CASE
                                      WHEN account_contact_role.role = 'Technical Fox'
                                      THEN FIRST_VALUE(campaign_id) OVER(PARTITION BY account_contact_role.accountid ORDER BY campaign_member.created_at ROWS UNBOUNDED PRECEDING)
                                      ELSE NULL
                                    END AS first_technical_campaign_id
                                  , CASE
                                      WHEN account_contact_role.role = 'Technical Fox'
                                      THEN LAST_VALUE(campaign_id) OVER(PARTITION BY account_contact_role.accountid ORDER BY campaign_member.created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                      ELSE NULL
                                    END AS last_technical_campaign_id
                                  , CASE
                                      WHEN account_contact_role.role = 'Reference Contact'
                                      THEN FIRST_VALUE(campaign_id) OVER(PARTITION BY account_contact_role.accountid ORDER BY campaign_member.created_at ROWS UNBOUNDED PRECEDING)
                                      ELSE NULL
                                    END AS first_reference_campaign_id
                                  , CASE
                                      WHEN account_contact_role.role = 'Reference Contact'
                                      THEN LAST_VALUE(campaign_id) OVER(PARTITION BY account_contact_role.accountid ORDER BY campaign_member.created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                      ELSE NULL
                                    END AS last_reference_campaign_id    
                                FROM public.campaign_member AS campaign_member
                                LEFT JOIN public.account_contact_role
                                ON account_contact_role.contact_id = campaign_member.contact_id)
      SELECT account_id
        , MIN(first_economic_contact_campaign_id) AS first_economic_contact_campaign_id
        , MAX(last_economic_contact_campaign_id) AS last_economic_contact_campaign_id
        , MIN(first_technical_campaign_id) AS first_technical_campaign_id
        , MAX(last_technical_campaign_id) AS last_technical_campaign_id
        , MIN(first_reference_campaign_id) AS first_reference_campaign_id
        , MAX(last_reference_campaign_id) AS last_reference_campaign_id
      FROM campaign_summary
      GROUP BY account_id
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))
    sortkeys: [account_id]
    distkey: account_id
  fields:

# DIMENSIONS #

  - dimension: account_id
    primary_key: true
    hidden: true
    sql: ${TABLE}.account_id

  - dimension: first_economic_contact_campaign_id
    sql: ${TABLE}.first_economic_contact_campaign_id

  - dimension: last_economic_contact_campaign_id
    sql: ${TABLE}.last_economic_contact_campaign_id

  - dimension: first_technical_campaign_id
    sql: ${TABLE}.first_technical_campaign_id

  - dimension: last_technical_campaign_id
    sql: ${TABLE}.last_technical_campaign_id

  - dimension: first_reference_campaign_id
    sql: ${TABLE}.first_reference_campaign_id

  - dimension: last_reference_campaign_id
    sql: ${TABLE}.last_reference_campaign_id

# MEASURES #

  - measure: count
    type: count
    drill_fields: detail*
    
# SETS #

  sets:
    detail:
      - account_id
      - first_economic_contact_campaign_id
      - last_economic_contact_campaign_id
      - first_technical_campaign_id
      - last_technical_campaign_id
      - first_reference_campaign_id
      - last_reference_campaign_id

- view: lead_campaign
  derived_table:
    sql: |
      SELECT DISTINCT campaign_member.lead_id AS lead_id
        , FIRST_VALUE(campaign_id) OVER(PARTITION BY campaign_member.lead_id 
                                       ORDER BY campaign_member.created_at ROWS UNBOUNDED PRECEDING) AS first_campaign_id
        , LAST_VALUE(campaign_id) OVER(PARTITION BY campaign_member.lead_id 
                                       ORDER BY campaign_member.created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_campaign_id  
      FROM public.campaign_member AS campaign_member
    sql_trigger_value: SELECT DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', GETDATE()))
    sortkeys: [lead_id]
    distkey: lead_id
  fields:

# DIMENSIONS #

  - dimension: lead_id
    primary_key: true
    hidden: true
    sql: ${TABLE}.lead_id

  - dimension: first_campaign_id
    description: The first campaign the lead had contact with. Most analysis is based off this.
    sql: ${TABLE}.first_campaign_id
    html: |
      {{ linked_value }}

  - dimension: last_campaign_id
    description: The last campaign the lead had contact with.
    sql: ${TABLE}.last_campaign_id

# MEASURES #

  - measure: count
    type: count
    drill_fields: detail*

# SETS #

  sets:
    detail:
      - lead_id
      - first_economic_contact_campaign_id
      - last_economic_contact_campaign_id
      - first_technical_campaign_id
      - last_technical_campaign_id
      - first_reference_campaign_id
      - last_reference_campaign_id