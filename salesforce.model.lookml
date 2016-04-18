# PRELIMINARIES #

- connection: salesforce_demo
- include: "*.view.lookml"       # include all the views
- include: "*.dashboard.lookml"  # include all the dashboards
- value_formats:
  - name: usd_large
    value_format: '[>=1000000]0.00,,"M";[>=1000]0.00,"K";$0.00'
    
  

# VIEWS TO EXPLORE——i.e., "BASE VIEWS" #

- explore: the_switchboard
  label: '(1) The Switchboard'
  joins:
    - join: first_campaign
      from: campaign
      sql_on: ${first_campaign.id} = ${the_switchboard.attributable_campaign_id}
      relationship: many_to_one
    
    - join: task
      sql_on: ${the_switchboard.account_id} = ${task.account_id}
      relationship: one_to_many
    
    - join: license
      fields: []
      sql_on: ${the_switchboard.account_id} = ${license.salesforce_account_id}
      relationship: one_to_many
    
    - join: event
      view_label: "Usage"
      fields: [user_count]
      sql_on: ${license.license_slug} = ${event.license_slug}
      relationship: one_to_many
      
    - join: campaign
      sql_on: ${campaign.id} = ${the_switchboard.campaign_id}
      relationship: many_to_one
      
    - join: lead
      sql_on: ${lead.id} = ${the_switchboard.lead_id}
      relationship: many_to_one
      
    - join: attributable_lead
      from: lead
      sql_on: ${attributable_lead.id} = ${the_switchboard.attributable_lead_id}
      relationship: many_to_one
      fields: []

    - join: contact
      sql_on: ${contact.id} = ${the_switchboard.contact_id}
      relationship: many_to_one
      
    - join: zendesk_ticket
      sql_on: ${contact.id} = ${zendesk_ticket.requester}
      relationship: one_to_many      
      
    - join: attributable_contact
      from: contact
      sql_on: ${attributable_contact.id} = ${the_switchboard.attributable_contact_id}
      relationship: many_to_one
      fields: []
      
    - join: account
      sql_on: ${account.id} = ${the_switchboard.account_id}
      relationship: many_to_one
      fields: [export_set*]
      
    - join: account_facts
      view_label: 'Account'
      sql_on: ${account_facts.account_id} = ${account.id}
      relationship: many_to_one
      
    - join: opportunity
      relationship: many_to_one
      sql_on: ${opportunity.id} = ${the_switchboard.opportunity_id}
      
    - join: opportunity_zendesk_facts
      view_label: 'Opportunity'
      sql_on: ${opportunity.id} = ${opportunity_zendesk_facts.id}
      relationship: one_to_one      
      
    - join: meeting
      sql_on: ${meeting.id} = ${the_switchboard.meeting_id}
      relationship: many_to_one   
      
    - join: prior_campaign    # campaign prior to meeting
      from: campaign
      sql_on: ${the_switchboard.prior_campaign_id} = ${prior_campaign.id}
      relationship: many_to_one
      
    - join: modified_first_campaign
      from: campaign
      sql_on: ${the_switchboard.modified_first_campaign_id} = ${modified_first_campaign.id}
      relationship: many_to_one

    - join: sdr
      from: person
      view_label: 'SDR'
      sql_on: ${sdr.id} = ${meeting.owner_id}
      fields: [name]
      relationship: many_to_one   
    
    - join: salesrep
      view_label: 'Sales Representative'
      sql_on: ${salesrep.id} = ${account.owner_id}
      relationship: many_to_one 
      
    - join: usage
      sql_on: ${usage.salesforce_account_id} = ${account.id}
      type: inner   # to omit accounts for whom there is no usage due to no license mapping
      relationship: one_to_one  
    
    - join: account_weekly_usage
      view_label: 'Usage'
      sql_on: ${the_switchboard.account_id} = ${account_weekly_usage.account_id}
      relationship: one_to_many
      fields: [export_set*]
      
      
- explore: funnel
  label: '(2) Lead Funnel'
  joins: 
    - join: company
      sql_on: ${funnel.company_id} = ${company.company_id}
      relationship: one_to_one
    
    - join: lead
      sql_on: ${lead.company_id} = ${company.company_id}
      relationship: one_to_many
      type: inner
      
    - join: account
      sql_on: ${account.company_id} = ${company.company_id}
      relationship: one_to_many
      fields: [export_set*]    
    
    - join: salesrep
      sql_on: ${salesrep.id} = ${account.owner_id}
      fields: [name, business_segment]
      relationship: many_to_one 
    
    - join: meeting
      sql_on: ${meeting.account_id} = ${company.account_id}
      relationship: one_to_many
      type: inner
      
    - join: opportunity
      sql_on: ${opportunity.account_id} = ${company.account_id}
      relationship: one_to_many
      type: inner

- explore: historical_snapshot    
  label: '(3) Historical Opportunity Snapshot'
  joins:
    - join: opportunity
      view_label: 'Current Opportunity State'
      sql_on: ${historical_snapshot.opportunity_id} = ${opportunity.id}
      relationship: many_to_one
      fields: [export_set*]
      type: inner
      
    - join: account
      sql_on: ${opportunity.account_id} = ${account.id}
      relationship: many_to_one
      fields: [export_set*]
       
    - join: account_facts
      view_label: 'Account'
      sql_on: ${account_facts.account_id} = ${account.id}
      relationship: many_to_one
      
    - join: opportunity_zendesk_facts
      view_label: 'Opportunity'
      sql_on: ${opportunity.id} = ${opportunity_zendesk_facts.id}
      relationship: one_to_one      
      
    - join: salesrep
      sql_on: ${salesrep.id} = ${account.owner_id}
      relationship: many_to_one 

- explore: feature_usage
  from: events_in_past_180_days
  label: '(4) Sessions and Feature Usage'
  joins:
    - join: event_mapping
      view_label: 'Event'
      relationship: one_to_one
      type: inner
      sql_on: ${feature_usage.id} = ${event_mapping.event_id}

    - join: sessions
      relationship: many_to_one
      type: left_outer
      sql_on: ${event_mapping.unique_session_id} = ${sessions.unique_session_id}
    
    - join: account
      fields: [export_set*]
      sql_on: ${sessions.account_id} = ${account.id}
      relationship: many_to_one
    
    - join: account_weekly_usage
      view_label: 'Account'
      sql_on: ${account.id} = ${account_weekly_usage.account_id}
      relationship: one_to_many
      fields: [account_health_score, average_account_health]

    - join: salesrep
      view_label: 'Account'
      fields: [business_segment]
      sql_on: ${salesrep.id} = ${account.owner_id}
      relationship: many_to_one 

    - join: opportunity
      sql_on: ${account.id} = ${opportunity.account_id}
      relationship: one_to_many
      fields: [export_set*]
      type: inner

    - join: session_facts
      relationship: one_to_one
      type: inner
      view_label: 'Sessions'
      sql_on: ${sessions.unique_session_id} = ${session_facts.unique_session_id}
      
      
            
