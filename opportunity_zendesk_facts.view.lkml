# This derived table combines Salesforce data with information from Zendesk, a customer support tool,
# which can then be used to create custom metrics, like a health score for prospects.
# The health score created from this derived table is based off of:
#   number of users (more is better);
#   number of chats (more is better in this case, suggesting engagement);
#   and days that the opportunity has been open (more is bad, suggesting a languishing lead).
# The actual pieces of information that create a custom health score depend on how a company wants its prospects or customers to interact with its support team.


view: opportunity_zendesk_facts {
  derived_table: {
    sql: SELECT
        opportunity.id
        , DATEDIFF( days, opportunity.created_at, opportunity.closed_date ) + 1 AS days_open
        , COUNT(zendesk_ticket.id) AS zendesk_ticket_count
        , COUNT(contact.id) AS user_count
      FROM ${account.SQL_TABLE_NAME} AS account
      LEFT JOIN ${opportunity.SQL_TABLE_NAME} AS opportunity
        ON opportunity.account_id = account.id
      LEFT JOIN public.contact AS contact
        ON contact.account_id = account.id
      LEFT JOIN public.zendesk_ticket AS zendesk_ticket
        ON contact.id = zendesk_ticket.zendesk___requester___c
        AND zendesk_ticket.created_date < opportunity.closed_date
      WHERE opportunity.id <> '006E000000OiPXzIAN'
        AND opportunity.id <> '006E000000OiPYNIA3'
      GROUP BY 1,2
       ;;

## As of11/2/2016, SFDC etl to redshift moved to 8pm PST (8PM Santa Cruz, 11PM Eastern, 4AM London)
## consequently, moving all ETLs to 9:30pm PST (9:30PM PST, 12:30am Eastern, 5:30AM London)
## note that London time shift by an hour in the week between US and Europe start dates for daylight savings
## This PDT was previously regenerated using SELECT COUNT(*) FROM public.zendesk_ticket
## We changed this to a calendered rebuild to avoid accidentally querying tables that are empty while ETL is still running

    sql_trigger_value: SELECT DATE(DATEADD('minute', 150, CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', getdate()))) ;;


    distribution: "id"
    sortkeys: ["id"]
  }

  dimension: id {
    primary_key: yes
    hidden: yes
    sql: ${TABLE}.id ;;
  }

  dimension: days_open {
    hidden: yes
    type: number
    sql: ${TABLE}.days_open ;;
  }

  dimension: user_count {
    type: number
    sql: ${TABLE}.user_count ;;
  }

  dimension: health {
    type: number
    description: "Aggregated score of opportunity health (out of 100)"
    sql: (CASE
        WHEN ${days_open} < 40 THEN 31
        WHEN ${days_open} < 60 THEN 25
        WHEN ${days_open} < 80 THEN 18
        WHEN ${days_open} < 100 THEN 13
        WHEN ${days_open} < 130 THEN 5
        ELSE 0
      END)
      +

      (CASE
        WHEN ${zendesk_ticket_count} > 8 THEN 33
        WHEN ${zendesk_ticket_count} > 7 THEN 27
        WHEN ${zendesk_ticket_count} > 6 THEN 20
        WHEN ${zendesk_ticket_count} > 5 THEN 15
        WHEN ${zendesk_ticket_count} > 4 THEN 7
        ELSE 0
      END)

      +

      (CASE
        WHEN ${user_count} > 15 THEN 35
        WHEN ${user_count} > 10 THEN 29
        WHEN ${user_count} > 8 THEN 22
        WHEN ${user_count} > 6 THEN 17
        WHEN ${user_count} > 3 THEN 9
        ELSE 0
      END)
       ;;
    html: {% if value < 30 %}
        <b><p style="color: white; background-color: #dc7350; font-size:100%; text-align:center; margin: 0; border-radius: 5px;">{{ rendered_value }}</p></b>
      {% elsif value < 60 %}
        <b><p style="color: black; background-color: #e9b404; font-size:100%; text-align:center; margin: 0; border-radius: 5px;">{{ rendered_value }}</p></b>
      {% else %}
        <b><p style="color: white; background-color: #49cec1; font-size:100%; text-align:center; margin: 0; border-radius: 5px;">{{ rendered_value }}</p></b>
      {% endif %}
      ;;
  }

  dimension: zendesk_ticket_count {
    hidden: yes
    type: number
    sql: ${TABLE}.zendesk_ticket_count ;;
  }

  measure: total_tickets {
    #     hidden: true
    type: sum
    sql: ${zendesk_ticket_count} ;;
    drill_fields: [zendesk_ticket.created_date, zendesk_ticket.id, zendesk_ticket.time_to_solve]
  }

  measure: average_tickets {
    type: average
    sql: ${zendesk_ticket_count} ;;
  }

  measure: avg_days_open {
    hidden: yes
    type: average
    sql: ${days_open} ;;
  }

  measure: total_days_open {
    type: sum
    sql: ${days_open} ;;
  }

  set: detail {
    fields: [id, days_open, zendesk_ticket_count]
  }
}
