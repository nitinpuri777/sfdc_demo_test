- dashboard: sales_app_rep_overview
  title: Sales App - Rep Overview
  layout: grid
  rows:
    - elements: [top_performer, most_improved, bottom_performer]
      height: 150
    - elements: [rep_comparison]
      height: 550
    - elements: [lead_to_intros, meetings_to_opps, opps_to_wins]
      height: 500

  filters:
  
  - name: sales_segment
    title: 'Sales Segment'
    type: field_filter
    explore: opportunity
    field: salesrep.segment_select
    

  elements:

  - name: top_performer
    title: Top Performer
    type: single_value
    model: salesforce
    explore: opportunity
    dimensions: [salesrep.name]
    measures: [quota.pace_current_quarter]
    hidden_fields: [quota.tracking_to_quota_current_quarter, quota.tracking_to_quota,
      quota.pace_current_quarter]
    filters:
      opportunity.is_quarter_to_date: 'Yes'
      salesrep.name: -NULL
      opportunity.total_acv_won_last_quarter: '>0'
      quota.pace_current_quarter: NOT NULL
    sorts: [quota.pace_current_quarter desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: false
    listen:
      sales_segment: salesrep.business_segment

  - name: most_improved
    title: Most Improved
    type: single_value
    model: salesforce
    explore: opportunity
    dimensions: [salesrep.name]
    measures: [opportunity.win_percentage_change]
    hidden_fields: [opportunity.win_percentage_change]
    filters:
      opportunity.is_quarter_to_date: 'Yes'
      opportunity.total_acv_won_last_quarter: '>0'
      opportunity.win_percentage_change: NOT NULL
    sorts: [opportunity.win_percentage_change desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: false
    listen:
      sales_segment: salesrep.business_segment
    
  - name: bottom_performer
    title: Bottom Performer
    type: single_value
    model: salesforce
    explore: opportunity
    dimensions: [salesrep.name]
    measures: [quota.pace_current_quarter]
    hidden_fields: [quota.tracking_to_quota_current_quarter, quota.tracking_to_quota,
      quota.pace_current_quarter]
    filters:
      opportunity.is_quarter_to_date: 'Yes'
      salesrep.name: -NULL
      opportunity.total_acv_won_last_quarter: '>0'
      quota.pace_current_quarter: NOT NULL
    sorts: [quota.pace_current_quarter]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: false
    listen:
      sales_segment: salesrep.business_segment

  - name: rep_comparison
    title: Sales Rep Comparison
    type: table
    model: salesforce
    explore: opportunity
    dimensions: [salesrep.name]
    measures: [quota.pace_current_quarter, quota.pace_change, opportunity.total_acv_won_current_quarter,
      opportunity.total_acv_won_percent_change, opportunity.win_percentage_current_quarter,
      opportunity.win_percentage_change, opportunity.count_won_current_quarter, opportunity.count_won_percent_change]
    filters:
      opportunity.is_quarter_to_date: 'Yes'
      salesrep.name: -NULL
      opportunity.total_acv_won_last_quarter: '>0'
      quota.pace_current_quarter: NOT NULL
    sorts: [quota.pace_current_quarter desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_view_names: true
    show_row_numbers: true
    truncate_column_names: false
    series_labels:
      opportunity.count_won_current_quarter: Wins
      opportunity.count_won_percent_change: Change
      opportunity.total_acv_won_current_quarter: Total ACV
      opportunity.total_acv_won_percent_change: Change
      opportunity.win_percentage_current_quarter: Win Rate
      opportunity.win_percentage_change: Change
      quota.pace_change: Change
      quota.pace_current_quarter: Quota Pace
    table_theme: gray
    limit_displayed_rows: false
    listen:
      sales_segment: salesrep.business_segment
    
  - name: lead_to_intros
    title: Lead to Intro Meetings
    type: looker_bar
    model: salesforce
    explore: funnel
    dimensions: [salesrep.name]
    measures: [funnel.lead_to_intro_meeting, lead.count]
    filters:
      meeting.meeting_date: this quarter
      salesrep.name: -NULL
    sorts: [salesrep.name]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#5245ed', '#ed6168', '#1ea8df', '#353b49', '#49cec1', '#b3a0dd', '#db7f2a',
      '#706080', '#a2dcf3', '#776fdf', '#e9b404', '#635189']
    show_value_labels: false
    label_density: 25
    hide_legend: true
    x_axis_gridlines: false
    show_view_names: false
    series_types:
      funnel.lead_to_intro_meeting: line
    limit_displayed_rows: false
    y_axis_combined: false
    show_y_axis_labels: false
    show_y_axis_ticks: false
    y_axis_tick_density: default
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    reference_lines: [{reference_type: line, range_start: max, range_end: min, margin_top: deviation,
        margin_value: mean, margin_bottom: deviation, color: '#5245ed', label: 'Conversion
          Average: {{mean}}', line_value: mean}]
    show_null_labels: false
    listen:
      sales_segment: salesrep.business_segment
  
  - name: meetings_to_opps
    title: Meetings to Opportunities
    type: looker_bar
    model: salesforce
    explore: funnel
    dimensions: [salesrep.name]
    measures: [funnel.meeting_to_opportunity, meeting.count]
    filters:
      opportunity.created_date: this quarter
      salesrep.name: -NULL
    sorts: [salesrep.name]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#1ea8df', '#e9b404', '#1ea8df', '#353b49', '#49cec1', '#b3a0dd', '#db7f2a',
      '#706080', '#a2dcf3', '#776fdf', '#e9b404', '#635189']
    show_value_labels: false
    label_density: 25
    hide_legend: true
    x_axis_gridlines: false
    show_view_names: false
    series_types:
      funnel.meeting_to_opportunity: line
    limit_displayed_rows: false
    y_axis_combined: false
    show_y_axis_labels: false
    show_y_axis_ticks: false
    y_axis_tick_density: default
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    reference_lines: [{reference_type: line, range_start: max, range_end: min, margin_top: deviation,
        margin_value: mean, margin_bottom: deviation, color: '#1ea8df', label: 'Conversion
          Average: {{mean}}', line_value: mean}]
    show_null_labels: false
    listen:
      sales_segment: salesrep.business_segment

  - name: opps_to_wins
    title: Opportunities to Closed Won
    type: looker_bar
    model: salesforce
    explore: funnel
    dimensions: [salesrep.name]
    measures: [funnel.opportunity_to_win, opportunity.count]
    filters:
      opportunity.closed_date: this quarter
      salesrep.name: -NULL
    sorts: [salesrep.name]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#776fdf', '#49cec1', '#353b49', '#49cec1', '#b3a0dd', '#db7f2a', '#706080',
      '#a2dcf3', '#776fdf', '#e9b404', '#635189']
    show_value_labels: false
    label_density: 25
    hide_legend: true
    x_axis_gridlines: false
    show_view_names: false
    series_types:
      funnel.opportunity_to_win: line
    limit_displayed_rows: false
    y_axis_combined: false
    show_y_axis_labels: false
    show_y_axis_ticks: false
    y_axis_tick_density: default
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    reference_lines: [{reference_type: line, range_start: max, range_end: min, margin_top: deviation,
        margin_value: mean, margin_bottom: deviation, color: '#b3a0dd', label: 'Conversion
          Average: {{mean}}', line_value: mean}]
    show_null_labels: false
    listen:
      sales_segment: salesrep.business_segment

