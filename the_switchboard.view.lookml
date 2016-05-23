# Flattening SFDC data is a very effective way to calculate lead attribution, as it takes companies into account, not individuals. 
# This can also be an effective base Explore for users who aren't familiar with the Salesforce schema and don't know where to start.
# However, it's too complex a solution for basic queries, because of the number of joins required to build this table.
# The complexity makes queries less performant and makes debugging SQL harder because of how they are written.


- view: opportunity_attributable_campaign_temp
  derived_table:
    sql: |
      SELECT DISTINCT ocr.opportunity_id
        , FIRST_VALUE(ocr.contact_id IGNORE NULLS) OVER(PARTITION BY ocr.opportunity_id ORDER BY c.created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS contact_id 
        , FIRST_VALUE(c.grouping_c IGNORE NULLS) OVER(PARTITION BY ocr.opportunity_id ORDER BY c.created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS grouping 
        , FIRST_VALUE(ac.attributable_campaign_id IGNORE NULLS) OVER(PARTITION BY ocr.opportunity_id ORDER BY ac.attributable_campaign_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS attributable_campaign_id
      FROM opportunity_contact_role AS ocr
      LEFT JOIN contact AS c
      ON c.id = ocr.contact_id
      LEFT JOIN (SELECT DISTINCT contact_id
                   , FIRST_VALUE(campaign_id IGNORE NULLS) OVER(PARTITION BY contact_id ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS attributable_campaign_id
                   , FIRST_VALUE(created_at IGNORE NULLS) OVER(PARTITION BY contact_id ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS attributable_campaign_date
                 FROM campaign_member) AS ac
      ON ac.contact_id = ocr.contact_id
      WHERE ocr.contact_id IN (SELECT who_id FROM task)
    persist_for: 1 hour
    distkey: opportunity_id
    sortkeys: [opportunity_id]

- view: lead_attributable_campaign_temp
  derived_table:
    sql: |
      SELECT DISTINCT lead_id
        , FIRST_VALUE(campaign_id IGNORE NULLS) OVER(PARTITION BY lead_id ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS attributable_campaign_id
      FROM campaign_member
      LIMIT 100
    persist_for: 1 hour
    distkey: lead_id
    sortkeys: [lead_id]

- view: contact_attributable_campaign_temp
  derived_table:
    sql: |
      SELECT DISTINCT contact_id
        , FIRST_VALUE(campaign_id IGNORE NULLS) OVER(PARTITION BY contact_id ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS attributable_campaign_id
      FROM campaign_member
    persist_for: 1 hour
    distkey: contact_id
    sortkeys: [contact_id]

- view: company_campaign_temp
  derived_table:
    sql: |
      SELECT DISTINCT MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(l.company, a.name)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', '')) AS company_id
        , COUNT(cm.campaign_id) OVER(PARTITION BY MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(l.company, a.name)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', ''))) AS campaign_touches
        , LAST_VALUE( CASE 
                        WHEN cm.created_at <= m.most_recent_meeting_at 
                        THEN cm.campaign_id 
                        ELSE NULL 
                      END IGNORE NULLS) 
          OVER(PARTITION BY MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(l.company, a.name)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', ''))
               ORDER BY cm.created_at
               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_prior_to_meeting
      FROM campaign_member AS cm
      LEFT JOIN contact AS c
      ON c.id = cm.contact_id
      LEFT JOIN lead AS l
      ON l.id = cm.lead_id
      LEFT JOIN account AS a
      ON a.id = c.account_id
      LEFT JOIN ( SELECT meeting.id
                    , meeting.who_id
                    , meeting.account_id
                    , meeting.created_date
                    , LAST_VALUE(meeting.created_date IGNORE NULLS) OVER(PARTITION BY MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(account.name, lead.company)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', ''))
                                                                         ORDER BY meeting.created_date
                                                                         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS most_recent_meeting_at        
                    , MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(account.name, lead.company)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', '')) AS company_id
                    , COUNT(meeting.id) OVER(PARTITION BY MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(account.name, lead.company)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', ''))) AS meetings
                  FROM task AS meeting
                  LEFT JOIN account
                  ON account.id = meeting.account_id
                  LEFT JOIN lead
                  ON lead.id = meeting.who_id
                  WHERE meeting.type = 'Intro Meeting') AS m
      ON m.company_id = MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(l.company, a.name)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', ''))
    persist_for: 1 hour
    distkey: company_id
    sortkeys: [company_id]

- view: the_switchboard
  derived_table:
    sql: |
      WITH first_pass AS (SELECT 
                            -- company fields
                            REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(account.name, lead.company, opportunity_account.name)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', '') AS company_name
                            , MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(account.name, lead.company, opportunity_account.name)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', '')) AS company_id
                            , CASE 
                                WHEN account.current_customer_c
                                THEN 'Customer'
                                ELSE 'Prospect'
                              END AS type
                            , LEAST(lead.created_at
                                      , FIRST_VALUE(account.created_at IGNORE NULLS) OVER(PARTITION BY account.id 
                                                                                          ORDER BY account.created_at
                                                                                          ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                    ) AS first_seen_at
                            , CASE 
                                WHEN meeting.who_id = lead.id
                                THEN lead.id
                                ELSE NULL
                              END AS attributable_lead_id 
                            , CASE 
                                WHEN meeting.who_id = contact.id
                                THEN contact.id
                                ELSE NULL
                              END AS attributable_contact_id                                      
                            , CASE 
                                WHEN opportunity.id = opportunity_attributable_campaign.opportunity_id
                                THEN opportunity_attributable_campaign.grouping
                                ELSE COALESCE(contact.grouping_c, lead.grouping_c)
                              END AS attributable_grouping
                            , CASE
                                WHEN opportunity.id = opportunity_attributable_campaign.opportunity_id
                                THEN opportunity_attributable_campaign.attributable_campaign_id
                                ELSE COALESCE(contact_attributable_campaign.attributable_campaign_id, lead_attributable_campaign.attributable_campaign_id)
                              END AS attributable_campaign_id
                              
                            -- lead fields  
                            , lead.id AS lead_id  
                            , lead.grouping_c AS lead_grouping
                            , lead.created_at AS created_date
                            
                            -- contact fields
                            , contact.id AS contact_id
                            
                            -- account fields
                            , account.id AS account_id
                            , account.created_at AS account_created_date
                            
                            -- meeting fields
                            , meeting.id AS meeting_id
                            , meeting.created_date AS meeting_created_date
                            
                            -- opportunity fields
                            , opportunity.id AS opportunity_id
                            
                            -- geo-fields
                            , COALESCE(account.city, lead.city) AS city
                            , COALESCE(account.state, lead.state) AS state
                            , COALESCE(account.country, lead.country) AS country
                          FROM ${lead.SQL_TABLE_NAME} AS lead
                          FULL OUTER JOIN ${account.SQL_TABLE_NAME} AS account
                          ON lead.account_id = account.id
                          FULL OUTER JOIN ${opportunity.SQL_TABLE_NAME} AS opportunity
                          ON opportunity.id = lead.converted_opportunity_id
                          LEFT JOIN ${account.SQL_TABLE_NAME} AS opportunity_account
                          ON opportunity_account.id = opportunity.account_id                          
                          FULL OUTER JOIN contact
                          ON contact.id = lead.converted_contact_id
                          LEFT JOIN ( SELECT *
                                      FROM task
                                      WHERE type = 'Intro Meeting') AS meeting
                          ON (meeting.who_id = lead.id OR meeting.who_id = contact.id)
                          LEFT JOIN ${opportunity_attributable_campaign_temp.SQL_TABLE_NAME} AS opportunity_attributable_campaign
                          ON opportunity_attributable_campaign.contact_id = contact.id
                          LEFT JOIN ${lead_attributable_campaign_temp.SQL_TABLE_NAME} AS lead_attributable_campaign
                          ON lead_attributable_campaign.lead_id = lead.id
                          LEFT JOIN ${contact_attributable_campaign_temp.SQL_TABLE_NAME}  AS contact_attributable_campaign
                          ON contact_attributable_campaign.contact_id = contact.id)
        , second_pass AS (  SELECT company_id
                              , company_name
                              , CASE
                                  WHEN company_id IN (SELECT company_id FROM first_pass WHERE type = 'Customer')
                                  THEN 'Customer'
                                  ELSE 'Prospect'
                                END AS type
                              , LAST_VALUE(city) OVER(PARTITION BY company_id ORDER BY account_created_date DESC, created_date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS city
                              , LAST_VALUE(state) OVER(PARTITION BY company_id ORDER BY account_created_date DESC, created_date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS state
                              , LAST_VALUE(country) OVER(PARTITION BY company_id ORDER BY account_created_date DESC, created_date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS country
                              , FIRST_VALUE(first_seen_at IGNORE NULLS) OVER(PARTITION BY company_id 
                                                                             ORDER BY first_seen_at
                                                                             ROWS UNBOUNDED PRECEDING) AS first_seen_at
                              , lead_id                                            
                              , lead_grouping
                              , FIRST_VALUE(attributable_lead_id IGNORE NULLS) OVER(PARTITION BY company_id 
                                                                                     ORDER BY created_date
                                                                                     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS attributable_lead_id
                              , FIRST_VALUE(attributable_contact_id IGNORE NULLS) OVER(PARTITION BY company_id 
                                                                                       ORDER BY created_date
                                                                                       ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS attributable_contact_id
                              , FIRST_VALUE(attributable_grouping IGNORE NULLS) OVER(PARTITION BY company_id 
                                                                                     ORDER BY created_date
                                                                                     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS attributable_grouping
                              , FIRST_VALUE(attributable_campaign_id IGNORE NULLS) OVER(PARTITION BY company_id 
                                                                       ORDER BY created_date
                                                                       ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS attributable_campaign_id
                              , contact_id
                              , meeting_id
                              , LAST_VALUE(meeting_id IGNORE NULLS) OVER(PARTITION BY company_id
                                                                         ORDER BY meeting_created_date
                                                                         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS most_recent_meeting_id
                              , FIRST_VALUE(account_id IGNORE NULLS) OVER(PARTITION BY company_id 
                                                                          ORDER BY created_date
                                                                          ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS account_id
                              , opportunity_id
                              , LAST_VALUE(opportunity_id IGNORE NULLS) OVER(PARTITION BY company_id 
                                                                             ORDER BY created_date
                                                                             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS company_opportunity_id
                            FROM first_pass)
        SELECT second_pass.company_id
          , second_pass.company_name
          , second_pass.type
          , second_pass.first_seen_at
          , lead_campaign.campaign_id
          , COALESCE(company_campaign.campaign_touches, 0) AS campaign_touches
          , company_campaign.campaign_prior_to_meeting AS prior_campaign_id
          , lead_campaign.created_at AS campaign_touch_date
          , second_pass.attributable_campaign_id
          , second_pass.lead_id
          , second_pass.attributable_lead_id
          , second_pass.attributable_contact_id
          , second_pass.attributable_grouping
          , second_pass.lead_grouping
          , modified_first_touch.modified_first_campaign_id
          , second_pass.contact_id
          , COALESCE(account_contact_role.id, opportunity_contact_role.id) AS contact_role_id
          , second_pass.meeting_id
          , second_pass.account_id
          , second_pass.opportunity_id
          , second_pass.company_opportunity_id
          , second_pass.city
          , second_pass.state
          , second_pass.country
        FROM second_pass
        LEFT JOIN campaign_member AS lead_campaign
        ON lead_campaign.lead_id = second_pass.lead_id
        LEFT JOIN ${company_campaign_temp.SQL_TABLE_NAME} AS company_campaign
        ON company_campaign.company_id = second_pass.company_id
        LEFT JOIN account_contact_role
        ON account_contact_role.contact_id = second_pass.contact_id
        LEFT JOIN opportunity_contact_role
        ON opportunity_contact_role.contact_id = second_pass.contact_id
        LEFT JOIN ${modified_first_touch.SQL_TABLE_NAME} AS modified_first_touch
        ON modified_first_touch.company_id = second_pass.company_id
    sql_trigger_value: SELECT COUNT(*) FROM public.lead
    distribution_style: EVEN
    indexes: [first_seen_at, account_id, contact_id, opportunity_id, meeting_id]
 
  fields:
  
  - dimension: id
    sql: ${TABLE}.company_id

  - dimension: name
    sql: ${TABLE}.company_name

  - dimension: type
    sql: ${TABLE}.type

  - dimension: first_seen
    type: time
    timeframes: [date, week, month, year]
    sql: ${TABLE}.first_seen_at
    
  - dimension: first_seen_current_quarter
    type: yesno
    hidden: true
    sql: EXTRACT(QUARTER FROM ${TABLE}.first_seen_at) || EXTRACT(YEAR FROM ${TABLE}.first_seen_at) = EXTRACT(QUARTER FROM CURRENT_DATE) || EXTRACT(YEAR FROM CURRENT_DATE)
    
  - dimension: attributable_campaign_id
    hidden: true
    sql: ${TABLE}.attributable_campaign_id

  - dimension: attributable_grouping
    hidden: true
    sql: ${TABLE}.attributable_grouping

  - dimension: attributable_lead_id
    hidden: true
    sql: ${TABLE}.attributable_lead_id
    
  - dimension: attributable_contact_id
    hidden: true
    sql: ${TABLE}.attributable_contact_id  
    
  - dimension: prior_campaign_id
    hidden: true
    sql: ${TABLE}.prior_campaign_id
    
  - dimension: modified_first_campaign_id
    hidden: true
    sql: ${TABLE}.modified_first_campaign_id

  - dimension: account_id
    hidden: true
    sql: ${TABLE}.account_id

# COMPANY-GEO FIELDS #
  
  - dimension: city
    sql: ${TABLE}.city

  - dimension: state
    map_layer: us_states
    sql: UPPER(REGEXP_SUBSTR(${TABLE}.state, '([A-Z]{1}[a-z]{1}$|[A-Z]{2})'))
    
  - dimension: country
    map_layer: countries
    sql: ${TABLE}.country

# LEAD-LEVEL FIELDS #

  - dimension: campaign_id
    hidden: true
    sql: ${TABLE}.campaign_id
    
  - dimension: touch_before_close
    view_label: 'Campaign'
    type: yesno
    sql: ${campaign.created_date} <= ${opportunity.closed_date}
    
  - dimension: campaign_touch
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.campaign_touch_date
    
  - dimension: lead_grouping
    sql: ${TABLE}.lead_grouping
    
  - dimension: lead_id
    hidden: true
    sql: ${TABLE}.lead_id

  - dimension: contact_id
    hidden: true
    sql: ${TABLE}.contact_id
    
  - dimension: contact_role_id
    hidden: true
    sql: ${TABLE}.contact_role_id

  - dimension: meeting_id
    hidden: true
    sql: ${TABLE}.meeting_id

  - dimension: opportunity_id
    hidden: true
    sql: ${TABLE}.opportunity_id
    
  - dimension: days_to_convert_to_opp
    type: number
    hidden: true
    sql: datediff('day',${meeting.raw_meeting_date},${opportunity.raw_created_date}) 
  
  - dimension: converts_to_opp_7d
    type: yesno
    hidden: true
    sql: ${days_to_convert_to_opp} <= 7
  
  - dimension: converts_to_opp_30d
    type: yesno
    hidden: true
    sql: ${days_to_convert_to_opp} <= 30

  
# MEASURES #

  - measure: total_companies
    type: count_distinct
    sql: ${id}
    drill_fields: detail*
    
  - measure: total_customers
    type: count_distinct
    filters:
      type: 'Customer'
    sql: ${id}
    drill_fields: detail*
    
  - measure: total_prospects
    type: count_distinct
    filters:
      type: 'Prospect'
    sql: ${id}
    drill_fields: detail*
    
  - measure: lead_to_meeting
    type: number
    sql: 1.00 * ${meeting.count} / NULLIF(${lead.count}, 0)
    value_format: '#0.00%'
    
  - measure: meeting_to_customer
    type: number
    sql: 1.00 * ${total_customers} / NULLIF(${meeting.count}, 0)
    value_format: '#0.00%'
  
  - measure: intro_meetings_converted_to_opp_within_7d
    type: count_distinct
    sql: ${meeting.id}
    hidden: true
    filters:
      meeting.status: 'Completed'
      converts_to_opp_7d: 'Yes'  
    
  - measure: intro_meetings_converted_to_opp_within_30d
    type: count_distinct
    sql: ${meeting.id}
    hidden: true
    filters:
      meeting.status: 'Completed'
      converts_to_opp_30d: 'Yes'

  - measure: meeting_to_opp_conversion_rate_07d
    label: 'Meeting to Opportunity Conversion within 07 days'
    view_label: 'Meeting'
    description: 'What percent of meetings converted to opportunities within 7 days of the meeting?'
    type: number
    value_format: '#.#\%'
    sql: 100.0 * ${intro_meetings_converted_to_opp_within_7d} / nullif(${meeting.meetings_completed},0)
    drill_fields: [name, meeting.meeting_date, account_representative_meeting.name, opportunity.created_date, opportunity.name, opportunity.stage_name]

    
  - measure: meeting_to_opp_conversion_rate_30d
    label: 'Meeting to Opportunity Conversion within 30 days'
    view_label: 'Meeting'
    description: 'What percent of meetings converted to opportunities within 30 days of the meeting?'
    type: number
    value_format: '#.#\%'
    sql: 100.0 * ${intro_meetings_converted_to_opp_within_30d} / nullif(${meeting.meetings_completed},0)
    drill_fields: [name, meeting.meeting_date, account_representative_meeting.name, opportunity.created_date, opportunity.name, opportunity.stage_name]  
  
# SETS #

  sets:
    detail:
      - id
      - name
      - type
      - first_seen_date
      - attributable_campaign.grouping
      - attributable_campaign.name
      - salesrep.name

  