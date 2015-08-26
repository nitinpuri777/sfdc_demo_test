# PRELIMINARIES #

- connection: salesforce_demo
- include: "*.view.lookml"       # include all the views
- include: "*.dashboard.lookml"  # include all the dashboards
- template: liquid

# VIEWS TO EXPLORE——i.e., "BASE VIEWS" #

- explore: the_switchboard
  label: 'Company'
  joins:
    - join: first_campaign
      from: campaign
      sql_on: ${first_campaign.id} = ${the_switchboard.attributable_campaign_id}
      relationship: many_to_one
      
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
      sql_on: ${opportunity.id} = ${the_switchboard.opportunity_id}
      relationship: many_to_one
      
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
      sql_on: ${salesrep.id} = ${account.owner_id}
      relationship: many_to_one 
      
    - join: usage
      sql_on: ${usage.salesforce_account_id} = ${account.id}
      type: inner   # to omit accounts for whom there is no usage due to no license mapping
      relationship: one_to_one      
      
- explore: funnel
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
      
            

# - explore: company
#   joins:
#     - join: lead
#       sql_on: ${lead.company_id} = ${company.company_id}
#       relationship: one_to_many
#       fields: [export_set*]
#       
#     - join: lead_facts
#       view_label: 'Lead'
#       sql_on: ${lead_facts.company_id} = ${company.company_id}
#       relationship: many_to_one
# 
#     - join: account
#       sql_on: ${account.company_id} = ${company.company_id}
#       relationship: one_to_many
#       fields: [export_set*]
#       
#     - join: salesrep
#       foreign_key: account.owner_id
#     
#     - join: account_facts
#       view_label: 'Account'
#       sql_on: ${account_facts.account_id} = ${account.id}
#       relationship: many_to_one
#       
#     - join: opportunity
#       sql_on: ${opportunity.account_id} = ${account.id}
#       relationship: one_to_many
#       
#     - join: opportunity_facts
#       view_label: 'Opportunity'
#       sql_on: ${opportunity_facts.account_id} = ${opportunity.account_id}
#       relationship: one_to_one
#       
#     - join: opportunity_zendesk_facts
#       view_label: 'Opportunity'
#       sql_on: ${opportunity.id} = ${opportunity_zendesk_facts.id}
#       relationship: one_to_one
# 
#     - join: lead_campaign
#       sql_on: ${lead_campaign.lead_id} =  ${lead.id}
#       relationship: one_to_one
#       fields: []      # expose no fields; used strictly as a map for campaign join
#       
#     - join: campaign
#       sql_on: ${lead_campaign.first_campaign_id} = ${campaign.id}
#       relationship: one_to_one
#       
#     - join: contact
#       sql_on: ${contact.account_id} = ${account.id}
#       relationship: one_to_many
#       fields: [export_set*]
#       
#     - join: meeting
#       sql_on: ${meeting.account_id} = company.account_id
#       relationship: one_to_many
#       
#     - join: zendesk_ticket
#       sql_on: ${contact.id} = ${zendesk_ticket.requester}
#       relationship: one_to_many
#     
#     - join: usage
#       sql_on: ${usage.salesforce_account_id} = ${account.id}
#       type: inner   # to omit accounts for whom there is no usage due to no license mapping
#       relationship: one_to_one
#       
#     - join: country_region_map
#       view_label: 'Account'
#       sql_on: ${account.country} = ${country_region_map.three_char_code}
#       relationship: one_to_one
#       fields: [country_name, continent_name]
            