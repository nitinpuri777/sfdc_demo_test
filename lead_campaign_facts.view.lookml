- view: lead_campaignmember_spread
  derived_table:
    sql: |
      SELECT
        cm.id AS campaignmember_id
        , l.id AS lead_id
        , cm.created_at AS created
        , cm.contact_id AS contact_id
      FROM campaign_member AS cm
      JOIN Lead AS l
      ON (CASE
            WHEN cm.lead_id IS NOT NULL
            THEN l.id
            ELSE l.converted_contact_id
          END)
      =
          (CASE
            WHEN cm.lead_id IS NOT NULL
            THEN cm.lead_id
            ELSE cm.contact_id
           END)
           
    sortkeys: [campaignmember_id, lead_id, created]
    sql_trigger_value: SELECT CURDATE()
  fields:
    - measure: count
      type: count
      
- view: contact_campaignmember_spread
  derived_table:
    sql: |
      SELECT
        lcs.campaignmember_id AS campaignmember_id
        , lcs.contact_id AS contact_id
        , lcs.created AS created
      FROM ${lead_campaignmember_spread.SQL_TABLE_NAME} AS lcs
      WHERE lcs.lead_id IS NULL
    sortkeys: [campaignmember_id, contact_id, created]
    sql_trigger_value: SELECT CURDATE()
  fields:
    - measure: count
      type: count

- view: sf_lead_campaignmember_map
  derived_table:
    sql: |
      SELECT
        l.Id AS lead_id
        ,(
        SELECT
          slcs1.campaignmember_id AS campaignmember_id
        FROM ${sf_lead_campaignmember_spread.SQL_TABLE_NAME} AS slcs1
        WHERE slcs1.lead_id = l.Id
        ORDER BY slcs1.created ASC
        LIMIT 1
        ) AS first_campaignmember_id
        ,(
        SELECT
          slcs2.campaignmember_id AS campaignmember_id
        FROM ${sf_lead_campaignmember_spread.SQL_TABLE_NAME} AS slcs2
        WHERE slcs2.lead_id = l.Id
        ORDER BY slcs2.created DESC
        LIMIT 1
        ) AS last_campaignmember_id
        , tcm.prior_campaignmember_id AS prior_campaignmember_id
      FROM Lead AS l
      LEFT JOIN ${sf_poly_task_map.SQL_TABLE_NAME} AS sptm
      ON sptm.lead_id = l.Id
      LEFT JOIN ${task_campaign_map.SQL_TABLE_NAME} AS tcm
      ON tcm.task_id = sptm.task_id
      AND sptm.map_type = 'lead'
    indexes: [lead_id]
    sql_trigger_value: SELECT CURDATE()
  fields:
    - measure: count
      type: count

#Symetric Difference on Contacts, grabbing Who 2
- view: sf_contact_lead_difference
  derived_table:
    sql: |
      SELECT
        c.Id AS contact_id
      FROM Contact AS c
      LEFT JOIN Lead AS l
      ON l.ConvertedContactId
      WHERE l.Id IS NULL
    indexes: [contact_id]
    sql_trigger_value: SELECT CURDATE()
  fields:
    - measure: count
      type: count
    
- view: sf_contact_campaignmember_map
  derived_table:
    sql: |
      SELECT
        scld.contact_id
        ,(
        SELECT
          sccs1.campaignmember_id AS campaignmember_id
        FROM ${sf_contact_campaignmember_spread.SQL_TABLE_NAME} AS sccs1
        WHERE sccs1.contact_id = scld.contact_id
        ORDER BY sccs1.created ASC
        LIMIT 1
        ) AS first_campaignmember_id
        ,(
        SELECT
          sccs2.campaignmember_id AS campaignmember_id
        FROM ${sf_contact_campaignmember_spread.SQL_TABLE_NAME} AS sccs2
        WHERE sccs2.contact_id = scld.contact_id
        ORDER BY sccs2.created DESC
        LIMIT 1
        ) AS last_campaignmember_id
        , tcm.prior_campaignmember_id AS prior_campaignmember_id
      FROM ${sf_contact_lead_difference.SQL_TABLE_NAME} AS scld
      LEFT JOIN ${sf_poly_task_map.SQL_TABLE_NAME} AS sptm
      ON sptm.contact_id = scld.contact_id
      LEFT JOIN ${task_campaign_map.SQL_TABLE_NAME} AS tcm
      ON tcm.task_id = sptm.task_id
      AND sptm.map_type = 'contact'
    indexes: [contact_id]
    sql_trigger_value: SELECT CURDATE()
  fields:
    - measure: count
      type: count

- view: sf_poly_campaignmember_map
  derived_table:
    sql: |
      SELECT
        'lead' AS map_type
        ,lcm.lead_id AS lead_id
        ,NULL AS contact_id
        ,lcm.first_campaignmember_id AS first_campaignmember_id
        ,lcm.last_campaignmember_id AS last_campaignmember_id
        ,lcm.prior_campaignmember_id AS prior_campaignmember_id
      FROM ${sf_lead_campaignmember_map.SQL_TABLE_NAME} lcm
      UNION
      SELECT
        'contact' AS map_type
        ,NULL AS lead_id
        ,ccc.contact_id AS contact_id
        ,ccc.first_campaignmember_id AS first_campaignmember_id
        ,ccc.last_campaignmember_id AS last_campaignmember_id
        ,ccc.prior_campaignmember_id AS prior_campaignmember_id
      FROM ${sf_contact_campaignmember_map.SQL_TABLE_NAME} ccc
    indexes: [lead_id, contact_id]
    sql_trigger_value: SELECT CURDATE()
  fields:
    - measure: count
      type: count
