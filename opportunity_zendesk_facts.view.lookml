- view: opportunity_zendesk_facts
  derived_table:
    sql: |
        SELECT 
          opportunity.id
          , DATEDIFF( days, opportunity.created_at, opportunity.closed_date ) + 1 as days_open
          , COUNT(zendesk_ticket.id) AS "zendesk_ticket_count"
        FROM ${account.SQL_TABLE_NAME} AS account
          LEFT JOIN ${opportunity.SQL_TABLE_NAME} AS opportunity ON opportunity.account_id = account.id
          LEFT JOIN public.contact AS contact ON contact.account_id = account.id
          LEFT JOIN public.zendesk_ticket AS zendesk_ticket ON contact.id = zendesk_ticket.zendesk___requester___c AND zendesk_ticket.created_date < opportunity.closed_date
        WHERE opportunity.id <> '006E000000OiPXzIAN' AND opportunity.id <> '006E000000OiPYNIA3'
        GROUP BY 1,2
    sql_trigger_value: SELECT COUNT(*) FROM public.zendesk_ticket
    sortkeys: [id]
  fields:
  - dimension: id
    primary_key: true
    hidden: true
    sql: ${TABLE}.id

  - dimension: days_open
    hidden: true
    type: number
    sql: ${TABLE}.days_open
    
  - dimension: health
    type: number
    description: Aggregated score of opportunity health (out of 100)
    sql: |
          (CASE
            WHEN ${days_open} < 40 THEN 33
            WHEN ${days_open} < 60 THEN 27
            WHEN ${days_open} < 80 THEN 20
            WHEN ${days_open} < 100 THEN 15
            WHEN ${days_open} < 130 THEN 7
            ELSE 0 END)  
          +
          
          (CASE
            WHEN ${zendesk_ticket_count} > 8 THEN 33
            WHEN ${zendesk_ticket_count} > 7 THEN 27
            WHEN ${zendesk_ticket_count} > 6 THEN 20
            WHEN ${zendesk_ticket_count} > 5 THEN 15
            WHEN ${zendesk_ticket_count} > 4 THEN 7
            ELSE 0 END)  
            
          +   
          
          (CASE
            WHEN ${opportunity.days_open} < 5 THEN 33
            WHEN ${opportunity.days_open} < 20 THEN 27
            WHEN ${opportunity.days_open} > 50 THEN 20
            WHEN ${opportunity.days_open} > 80 THEN 15
            WHEN ${opportunity.days_open} > 110 THEN 7
            ELSE 0 END)  
            
    html: |
        {% if value < 30 %}
          <b><p style="color: white; background-color: #dc7350; font-size:100%; text-align:center; margin: 0; border-radius: 5px;">{{ rendered_value }}</p></b>
        {% elsif value < 60 %}
          <b><p style="color: black; background-color: #e9b404; font-size:100%; text-align:center; margin: 0; border-radius: 5px;">{{ rendered_value }}</p></b>
        {% else %}
          <b><p style="color: white; background-color: #49cec1; font-size:100%; text-align:center; margin: 0; border-radius: 5px;">{{ rendered_value }}</p></b>
        {% endif %}
        
  - dimension: zendesk_ticket_count
    hidden: true
    type: number
    sql: ${TABLE}.zendesk_ticket_count
    
  - measure: total_tickets
#     hidden: true
    type: sum
    sql: ${zendesk_ticket_count}
    drill_fields: [zendesk_ticket.created_date, zendesk_ticket.id, zendesk_ticket.assignee_name, zendesk_ticket.time_to_solve]
    
  - measure: average_tickets
    type: average
    sql: ${zendesk_ticket_count}
    
  - measure: avg_days_open
    hidden: true
    type: average
    sql: ${days_open}
    
  - measure: total_days_open
    type: sum
    sql: ${days_open}    

  sets:
    detail:
      - id
      - days_open
      - zendesk_ticketcount

