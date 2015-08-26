- view: modified_first_touch
  derived_table:
    sql: |
      WITH who_meeting AS ( SELECT who_id
                              , MAX(created_date) AS meeting_date
                            FROM task
                            WHERE type = 'Intro Meeting'
                            GROUP BY 1)
      , touches_before_meeting AS (SELECT COALESCE(a.name, l.company) AS company_name
                                    , MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(a.name, l.company)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', '')) AS company_id
                                    , cm.id AS campaign_touch_id
                                    , cm.campaign_id
                                    , cm.created_at AS created_date
                                    , DATEDIFF(DAY
                                                , LAG(cm.created_at, 1) OVER(PARTITION BY MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(a.name, l.company)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', ''))
                                                                                ORDER BY cm.created_at)
                                                , cm.created_at                                          
                                      ) AS days_between_touches
                                    , DATEDIFF(DAY
                                                , LAST_VALUE(COALESCE(contact_meeting.meeting_date, lead_meeting.meeting_date) IGNORE NULLS) OVER(PARTITION BY MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(a.name, l.company)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', ''))
                                                                                                                                                        ORDER BY COALESCE(contact_meeting.meeting_date, lead_meeting.meeting_date)
                                                                                                                                                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                , cm.created_at
                                      ) AS days_from_meeting
                                    , cm.lead_id
                                    , cm.contact_id
                                    , LAST_VALUE(COALESCE(contact_meeting.meeting_date, lead_meeting.meeting_date) IGNORE NULLS) OVER(PARTITION BY MD5(REGEXP_REPLACE(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(COALESCE(a.name, l.company)), '(\.|,|\s)(inc|ltd|llc|llp|incorporated)+[^a-zA-Z]*$', '')), '[[:punct:]]', ''))
                                                                                                                                                        ORDER BY COALESCE(contact_meeting.meeting_date, lead_meeting.meeting_date)
                                                                                                                                                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS meeting_date                                                                                     
                                  FROM campaign_member AS cm
                                  LEFT JOIN lead AS l
                                  ON cm.lead_id = l.id
                                  LEFT JOIN contact AS c
                                  ON cm.contact_id = c.id
                                  LEFT JOIN account AS a
                                  ON c.account_id = a.id
                                  LEFT JOIN who_meeting AS lead_meeting
                                  ON lead_meeting.who_id = cm.lead_id
                                  LEFT JOIN who_meeting AS contact_meeting
                                  ON contact_meeting.who_id = cm.contact_id)
      , session_boundaries AS ( SELECT company_id
                                  , created_date AS session_start
                                  , LEAD(created_date, 1) OVER(PARTITION BY company_id ORDER BY created_date) AS next_session_start
                                  , ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY created_date) AS company_session
                                FROM touches_before_meeting
                                WHERE days_between_touches > 30 OR days_between_touches IS NULL)
      , sessions AS (SELECT touches_before_meeting.*
                        , session_boundaries.company_session
                        , LAST_VALUE(CASE WHEN touches_before_meeting.created_date <= touches_before_meeting.meeting_date THEN session_boundaries.company_session ELSE NULL END IGNORE NULLS) 
                          OVER(PARTITION BY touches_before_meeting.company_id ORDER BY touches_before_meeting.created_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS session_before_meeting
                      FROM touches_before_meeting
                      LEFT JOIN session_boundaries
                      ON session_boundaries.company_id = touches_before_meeting.company_id
                      AND touches_before_meeting.created_date BETWEEN session_boundaries.session_start AND session_boundaries.next_session_start)
      SELECT DISTINCT company_id
        , FIRST_VALUE(campaign_id IGNORE NULLS) OVER(PARTITION BY company_id ORDER BY created_date ROWS UNBOUNDED PRECEDING) AS modified_first_campaign_id
      FROM sessions
      WHERE company_session = session_before_meeting
    persist_for: 1 hour
    distkey: company_id
    sortkeys: [company_id]
  fields:
  
# DIMENSIONS #  

  - dimension: company_id
    sql: ${TABLE}.company_id

  - dimension: modified_first_campaign_id
    sql: ${TABLE}.modified_first_campaign_id  

# MEASURES #

  - measure: count
    type: count
    drill_fields: detail*