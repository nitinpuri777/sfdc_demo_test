# Because Accounts are not created until a Lead is converted to a Contact (at the conversion to an Opportunity),
# there is no inherent way to search across all businesses in your system in one place.
#
# This derived table joins all instances of company names from the account and lead tables to ensure a single list of businesses.
# First, it cleans company names by stripping spaces and modifiers to create a consistent way of referring to each company.
# Then, it joins those cleaned names from the account table to the lead table,
# and classifies any company that is not yet a customer as a prospect (including any company in the lead table).

# This table will regenerate any time a new record is added to the lead table.
# As of 11/2016, this table is getting moved to a daily rebuild after all ETL jobs are complete.
# We shouldn't regen based on queries against the leads table, because other tables used in the query might still be old/empty.

view: company {
  derived_table: {
    sql: WITH temp_company AS ( SELECT DISTINCT MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(name), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
                        , TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(name), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', '')) AS name
                        , CASE
                            WHEN type = 'Customer' AND current_customer_c
                            THEN 'Customer'
                            ELSE 'Prospect'
                          END AS type
                      FROM public.account
                      UNION
                      SELECT DISTINCT MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(company), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
                        , TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(company), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', '')) AS name
                        , 'Prospect' AS type
                      FROM public.lead)
, temp_account AS ( SELECT MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(name), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
                      , MIN(id) AS id
                    FROM public.account
                    GROUP BY 1)
SELECT ROW_NUMBER() OVER(ORDER BY 1) AS auto_id
  , temp_company.company_id
  , temp_company.type
  , temp_account.id AS account_id
  , temp_company.name
FROM temp_company
LEFT JOIN temp_account
ON temp_company.company_id = temp_account.company_id
 ;;
## As of11/2/2016, SFDC etl to redshift moved to 8pm PST (8PM Santa Cruz, 11PM Eastern, 4AM London)
## consequently, moving all ETLs to 9:30pm PST (9:30PM PST, 12:30am Eastern, 5:30AM London)
## note that London time shift by an hour in the week between US and Europe start dates for daylight savings
    sql_trigger_value: SELECT DATE(DATEADD('minute', 150, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', getdate()))) ;;

    indexes: ["company_id", "account_id"]
    distribution_style: all
  }

  # DIMENSIONS #

  dimension: auto_id {
    primary_key: yes
    hidden: yes
    type: number
    sql: ${TABLE}.auto_id ;;
  }

  dimension: company_id {
    hidden: yes
    sql: ${TABLE}.company_id ;;
  }

  dimension: account_id {
    hidden: yes
    sql: ${TABLE}.account_id ;;
  }

  dimension: name {
    sql: ${TABLE}.name ;;
  }

  dimension: type {
    sql: ${TABLE}.type ;;
  }

  # MEASURES #

  measure: count {
    type: count
    drill_fields: [company_set*]
  }

  # The following two measures are "filtered measures" which allow a user to bring in two versions of the same measure in a single query

  measure: count_prospect {
    type: count

    filters: {
      field: type
      value: "Prospect"
    }

    drill_fields: [company_set*]
  }

  measure: count_customer {
    type: count

    filters: {
      field: type
      value: "Customer"
    }

    drill_fields: [company.name, salesrep.name, usage.approximate_usage_in_minutes_total, opportunity.total_acv]
  }

  # SETS #

  set: company_set {
    fields: [company_id, name, type]
  }
}
