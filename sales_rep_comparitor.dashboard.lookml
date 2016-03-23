## Need to add percent to quota

- dashboard: sales_rep_comparitor
  title: Sales Rep Comparitor
  layout: grid
  rows:
    - elements: [sales_rep_comp]
      height: 600

  filters:
  - name: business_segment
    title: 'Business Segment'
    type: field_filter
    model: salesforce
    explore: the_switchboard
    field: salesrep.business_segment

  elements:

  - name: sales_rep_comp
    title: Sales Rep Comparitor
    type: table
    model: salesforce
    explore: the_switchboard
    dimensions: [salesrep.name, salesrep.business_segment]
    measures: [opportunity.count_won_current_quarter, opportunity.count_won_last_quarter,
      opportunity.total_acv_won_current_quarter, opportunity.total_acv_won_last_quarter,
      opportunity.win_percentage_current_quarter, opportunity.win_percentage_last_quarter]
    filters:
      salesrep.name: -NULL
    sorts: [opportunity.count_won_current_quarter desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_view_names: false
    show_row_numbers: true
    truncate_column_names: false
    listen:
      business_segment: salesrep.business_segment
