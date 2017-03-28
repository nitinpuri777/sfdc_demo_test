view: account_facts {
  derived_table: {
    sql: WITH account_contact_role_sequence AS ( SELECT contact.id AS contact_id
                                          , account_contact_role.account_id AS account_id
                                          , contact.name
                                          , contact.title
                                          , contact.created_at AS created_at
                                          , contact.email
                                          , account_contact_role.role
                                          , ROW_NUMBER() OVER(PARTITION BY account_contact_role.account_id
                                                                , account_contact_role.role
                                                              ORDER BY contact.created_at) AS contact_role_sequence_number
                                        FROM account_contact_role
                                        LEFT JOIN contact contact
                                        ON contact.id = account_contact_role.contact_id)
      , first_reference_contact AS (SELECT account_id
                                      , contact_id AS first_reference_contact_id
                                      , name AS first_reference_contact_name
                                      , title AS first_reference_contact_title
                                      , created_at AS first_reference_contact_created_at
                                      , email AS first_reference_contact_email
                                    FROM account_contact_role_sequence
                                    WHERE contact_role_sequence_number = 1
                                    AND role = 'Reference Contact')
      , second_reference_contact AS (SELECT account_id
                                      , contact_id AS second_reference_contact_id
                                      , name AS second_reference_contact_name
                                      , title AS second_reference_contact_title
                                      , created_at AS second_reference_contact_created_at
                                      , email AS second_reference_contact_email
                                     FROM account_contact_role_sequence
                                     WHERE contact_role_sequence_number = 2
                                     AND role = 'Reference Contact')
      , first_technical_contact AS (SELECT account_id
                                      , contact_id AS first_technical_contact_id
                                      , name AS first_technical_contact_name
                                      , title AS first_technical_contact_title
                                      , created_at AS first_technical_contact_created_at
                                      , email AS first_technical_contact_email
                                    FROM account_contact_role_sequence
                                    WHERE contact_role_sequence_number = 1
                                    AND role = 'Technical Fox')
      , second_technical_contact AS (SELECT account_id
                                      , contact_id AS second_technical_contact_id
                                      , name AS second_technical_contact_name
                                      , title AS second_technical_contact_title
                                      , created_at AS second_technical_contact_created_at
                                      , email AS second_technical_contact_email
                                     FROM account_contact_role_sequence
                                     WHERE contact_role_sequence_number = 2
                                     AND role = 'Technical Fox')
      , first_economic_contact AS (SELECT account_id
                                      , contact_id AS first_economic_contact_id
                                      , name AS first_economic_contact_name
                                      , title AS first_economic_contact_title
                                      , created_at AS first_economic_contact_created_at
                                      , email AS first_economic_contact_email
                                    FROM account_contact_role_sequence
                                    WHERE contact_role_sequence_number = 1
                                    AND role = 'Economic Decision Maker')
      , second_economic_contact AS (SELECT account_id
                                      , contact_id AS second_economic_contact_id
                                      , name AS second_economic_contact_name
                                      , title AS second_economic_contact_title
                                      , created_at AS second_economic_contact_created_at
                                      , email AS second_economic_contact_email
                                     FROM account_contact_role_sequence
                                     WHERE contact_role_sequence_number = 2
                                     AND role = 'Economic Decision Maker')
      SELECT first_reference_contact.*
        , second_reference_contact_id
        , second_reference_contact_name
        , second_reference_contact_title
        , second_reference_contact_created_at
        , second_reference_contact_email
        , first_technical_contact_id
        , first_technical_contact_name
        , first_technical_contact_title
        , first_technical_contact_created_at
        , first_technical_contact_email
        , second_technical_contact_id
        , second_technical_contact_name
        , second_technical_contact_title
        , second_technical_contact_created_at
        , second_technical_contact_email
        , first_economic_contact_id
        , first_economic_contact_name
        , first_economic_contact_title
        , first_economic_contact_created_at
        , first_economic_contact_email
        , second_economic_contact_id
        , second_economic_contact_name
        , second_economic_contact_title
        , second_economic_contact_created_at
        , second_economic_contact_email
      FROM first_reference_contact
      LEFT JOIN first_technical_contact
      ON first_reference_contact.account_id = first_technical_contact.account_id
      LEFT JOIN first_economic_contact
      ON first_reference_contact.account_id = first_economic_contact.account_id
      LEFT JOIN second_reference_contact
      ON first_reference_contact.account_id = second_reference_contact.account_id
      LEFT JOIN second_technical_contact
      ON first_reference_contact.account_id = second_technical_contact.account_id
      LEFT JOIN second_economic_contact
      ON first_reference_contact.account_id = second_economic_contact.account_id
 ;;
## As of11/2/2016, SFDC etl to redshift moved to 8pm PST (8PM Santa Cruz, 11PM Eastern, 4AM London)
## consequently, moving all ETLs to 9:30pm PST (9:30PM PST, 12:30am Eastern, 5:30AM London)
## note that London time shift by an hour in the week between US and Europe start dates for daylight savings
    sql_trigger_value: SELECT DATE(DATEADD('minute', 150, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', getdate()))) ;;
    sortkeys: ["account_id"]
    distribution: "account_id"
  }

  # DIMENSIONS #

  dimension: account_id {
    primary_key: yes
    hidden: yes
    sql: ${TABLE}.account_id ;;
  }

  dimension: reference_contact_id {
    hidden: yes
    sql: ${TABLE}.first_reference_contact_id ;;
  }

  dimension: reference_contact_title {
    sql: ${TABLE}.first_reference_contact_title ;;
  }

  dimension_group: reference_contact_created {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.first_reference_contact_created_at ;;
  }

  dimension: technical_contact_id {
    hidden: yes
    sql: ${TABLE}.first_technical_contact_id ;;
  }

  dimension: technical_contact_title {
    sql: ${TABLE}.first_technical_contact_title ;;
  }

  dimension_group: technical_contact_created {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.first_technical_contact_created_at ;;
  }

  dimension: economic_contact_id {
    hidden: yes
    sql: ${TABLE}.first_economic_contact_id ;;
  }

  dimension: economic_contact_title {
    sql: ${TABLE}.first_economic_contact_title ;;
  }

  dimension_group: economic_contact_created {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.first_economic_contact_created_at ;;
  }
}
