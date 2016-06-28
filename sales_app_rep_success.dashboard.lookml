- dashboard: sales_app_rep_success
  title: Sales App - Rep Success
  layout: grid
  rows: 
    - elements: [rep_tracking_to_quota, team_tracking_to_quota]
      height: 150
    - elements: [open_deal_health, progress_to_quota, trend_comparison]
      height: 400
    - elements: [loss_reasons, recent_wins]
      height: 300
    - elements: [acv_won_comparison, win_rate_comparison, pipeline_comparison]
      height: 200
    - elements: [meeting_to_close, team_meeting_to_close]
      height: 400
      
  filters:
  
  - name: sales_rep_name
    title: 'Sales Rep Name'
    type: field_filter
    explore: opportunity
    field: salesrep.name
    default_value: Kelsi Casados
  
  - name: business_segment
    title: 'Business Segment'
    type: field_filter
    explore: opportunity
    field: salesrep.segment_select
    default_value: Enterprise
  
  - name: closed_quarter
    title: 'Quarter'
    type: date_filter
    explore: opportunity
    field: opportunity.closed_quarter
    default_value: this quarter
 
 
  elements:

  - name: rep_tracking_to_quota
    title: Rep Tracking to Quota
    type: single_value
    model: salesforce
    explore: opportunity
    dimensions: [quota.quota]
    measures: [opportunity.total_acv_won]
    sorts: [salesrep.rep_comparitor, account.vertical, quota.tracking_to_quota_current_quarter_comparitor desc,
      quota.tracking_to_quota desc, opportunity.total_acv_won desc]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    single_value_title: Won
    show_comparison: true
    comparison_type: progress_percentage
    show_comparison_label: true
    comparison_label: Rep Quota
    listen:
      closed_quarter: opportunity.closed_quarter
      sales_rep_name: salesrep.name
      

  - name: team_tracking_to_quota
    title: Team Tracking to Quota
    type: single_value
    model: salesforce
    explore: opportunity
    dimensions: [quota_aggregated.sales_team_quota]
    measures: [opportunity.total_acv_won]
    sorts: [opportunity.total_acv_won desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    single_value_title: Won
    show_comparison: true
    comparison_type: progress_percentage
    show_comparison_label: true
    comparison_label: Team Quota
    listen:
      closed_quarter: opportunity.closed_quarter
    
  - name: progress_to_quota
    title: Progress to Quota
    type: looker_line
    model: salesforce
    explore: opportunity
    dimensions: [opportunity.closed_week]
    measures: [opportunity.total_acv_won, quota.sum_quota]
    dynamic_fields:
    - table_calculation: running_weekly_acv
      label: Running Weekly ACV
      expression: |-
        if(
          diff_days(now(),${opportunity.closed_week}) > 0
          , null
          , running_total(${opportunity.total_acv_won})
        )
      value_format: '[>=1000000]0.00,,"M";[>=1000]0.00,"K";$0.00'
    - table_calculation: quota
      label: Quota
      expression: ${quota.sum_quota}
      value_format_name: usd_0
    hidden_fields: [opportunity.total_acv_won, quota.sum_quota]
    sorts: [opportunity.closed_week]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#353b49', '#a2dcf3', '#b3a0dd', '#db7f2a', '#706080', '#a2dcf3', '#776fdf',
      '#e9b404', '#635189']
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    series_labels:
      quota.sum_quota: Quota
      running_weekly_acv: ACV Won
    series_types:
      quota: area
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: true
    y_axis_tick_density: custom
    y_axis_tick_density_custom: 5
    y_axis_value_format: $0,"K"
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_datetime_label: '%m-%d'
    x_axis_scale: auto
    y_axis_scale_mode: linear
    show_null_points: false
    point_style: none
    interpolation: step-after
    listen:
      closed_quarter: opportunity.closed_quarter
      sales_rep_name: salesrep.name
    
  - name: open_deal_health
    title: Open Deal Health
    type: table
    model: salesforce
    explore: opportunity
    dimensions: [account.name]
    measures: [opportunity.total_acv]
    filters:
      opportunity.is_closed: 'No'
      opportunity.total_acv: not 0
    sorts: [opportunity_zendesk_facts.health desc, opportunity.total_acv desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_view_names: false
    show_row_numbers: true
    truncate_column_names: false
    series_labels:
      opportunity.total_acv: ACV
      zendesk_ticket.count_tickets_before_close: Support Tickets
      opportunity_zendesk_facts.total_days_open: Days Open
      account.name: Company
    table_theme: gray
    limit_displayed_rows: false
    listen:
      closed_quarter: opportunity.closed_quarter
      sales_rep_name: salesrep.name

  - name: trend_comparison
    title: Trend Comparison - Tracking to Quota
    type: looker_line
    model: salesforce
    explore: opportunity
    dimensions: [salesrep.rep_comparitor, opportunity.closed_date]
    pivots: [salesrep.rep_comparitor]
    measures: [opportunity.total_acv_won, quota_aggregated.quota_sum, quota.sum_quota]
    dynamic_fields:
    - table_calculation: quota_pace
      label: Quota Pace
      expression: |-
        if(
        contains(${salesrep.rep_comparitor}, "1 -")
        , running_total(${opportunity.total_acv_won})/${quota.sum_quota}
        , running_total(${opportunity.total_acv_won})/${quota_aggregated.quota_sum}
        )
      value_format_name: percent_1
    hidden_fields: [opportunity.total_acv_won, quota_aggregated.quota_sum, running_acv,
      quota.sum_quota]
    filters:
      opportunity.is_quarter_to_date: 'Yes'
      salesrep.segment_select: 'zdf'
    sorts: [salesrep.rep_comparitor, opportunity.closed_date]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#353b49', '#776fdf', '#a2dcf3', '#353b49', '#49cec1', '#b3a0dd', '#db7f2a',
      '#706080', '#a2dcf3', '#776fdf', '#e9b404', '#635189']
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: true
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: true
    y_axis_tick_density: default
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    show_null_points: false
    point_style: none
    interpolation: linear
    discontinuous_nulls: false
    listen:
      closed_quarter: opportunity.closed_quarter
      sales_rep_name: salesrep.rep_select

  - name: loss_reasons
    title: Loss Reasons
    type: looker_pie
    model: salesforce
    explore: opportunity
    dimensions: [opportunity.lost_reason]
    measures: [opportunity.count]
    filters:
      opportunity.lost_reason: -NULL
    sorts: [opportunity.lost_reason]
    limit: 500
    query_timezone: America/Los_Angeles
    value_labels: legend
    colors: ['#5245ed', '#1ea8df', '#a2dcf3', '#b3a0dd', '#635189', '#776fdf', '#b3a0dd']
    show_view_names: true
    listen:
      closed_quarter: opportunity.closed_quarter
      sales_rep_name: salesrep.name
    
  - name: recent_wins
    title: Recent Wins
    type: table
    model: salesforce
    explore: opportunity
    dimensions: [account.name, opportunity.closed_date]
    measures: [opportunity.total_acv_won]
    filters:
      opportunity.is_won: 'Yes'
    sorts: [opportunity.closed_date desc]
    limit: 10
    total: true
    query_timezone: America/Los_Angeles
    show_view_names: true
    show_row_numbers: true
    truncate_column_names: false
    series_labels:
      account.name: Company
      opportunity.closed_date: Closed On
      opportunity.total_acv_won: ACV
    table_theme: gray
    limit_displayed_rows: false
    listen:
      closed_quarter: opportunity.closed_quarter
      sales_rep_name: salesrep.name
    
  - name: acv_won_comparison
    title: ACV Won Comparison
    type: looker_bar
    model: salesforce
    explore: opportunity
    dimensions: [salesrep.rep_comparitor]
    measures: [salesrep.avg_acv_won_comparitor]
    sorts: [salesrep.rep_comparitor]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#49cec1', '#ed6168', '#1ea8df', '#353b49', '#49cec1', '#b3a0dd', '#db7f2a',
      '#706080', '#a2dcf3', '#776fdf', '#e9b404', '#635189']
    show_value_labels: true
    label_density: 25
    label_color: ['#635189']
    font_size: small
    legend_position: center
    hide_legend: false
    x_axis_gridlines: false
    show_view_names: false
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: false
    y_axis_tick_density: default
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    show_null_labels: false
    listen:
      closed_quarter: opportunity.closed_quarter
      sales_rep_name: salesrep.rep_select
      business_segment: salesrep.segment_select
    
  - name: win_rate_comparison
    title: Win Rate Comparison
    type: looker_bar
    model: salesforce
    explore: opportunity
    dimensions: [salesrep.rep_comparitor]
    measures: [opportunity.win_percentage]
    sorts: [salesrep.rep_comparitor]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#49cec1', '#ed6168', '#1ea8df', '#353b49', '#49cec1', '#b3a0dd', '#db7f2a',
      '#706080', '#a2dcf3', '#776fdf', '#e9b404', '#635189']
    show_value_labels: true
    label_density: 25
    label_color: ['#353b49']
    font_size: small
    legend_position: center
    hide_legend: false
    x_axis_gridlines: false
    show_view_names: false
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: false
    y_axis_tick_density: default
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    show_null_labels: false
    listen:
      closed_quarter: opportunity.closed_quarter
      sales_rep_name: salesrep.rep_select
      business_segment: salesrep.segment_select
    
  - name: pipeline_comparison
    title: Pipeline Comparison
    type: looker_bar
    model: salesforce
    explore: opportunity
    dimensions: [salesrep.rep_comparitor]
    measures: [salesrep.avg_acv_pipeline]
    sorts: [salesrep.rep_comparitor]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#49cec1', '#ed6168', '#1ea8df', '#353b49', '#49cec1', '#b3a0dd', '#db7f2a',
      '#706080', '#a2dcf3', '#776fdf', '#e9b404', '#635189']
    show_value_labels: true
    label_density: 25
    label_color: ['#353b49']
    font_size: small
    legend_position: center
    hide_legend: false
    x_axis_gridlines: false
    show_view_names: false
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: false
    y_axis_tick_density: default
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    show_null_labels: false
    listen:
      closed_quarter: opportunity.closed_quarter
      sales_rep_name: salesrep.rep_select
      business_segment: salesrep.segment_select

  - name: team_meeting_to_close
    title: Team Meeting to Close
    type: looker_column
    model: salesforce
    explore: funnel
    measures: [meeting.count, opportunity.count, opportunity.count_won]
    filters:
      opportunity.type: New Business
    sorts: [opportunity.count_won desc]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#5245ed', '#776fdf', '#1ea8df', '#a2dcf3', '#49cec1', '#776fdf', '#49cec1',
      '#1ea8df', '#a2dcf3', '#776fdf', '#776fdf', '#635189']
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    show_view_names: true
    series_labels:
      meeting.count: Meetings
      opportunity.count: Opportunities
      opportunity.count_won: Wins
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: false
    y_axis_tick_density: default
    show_x_axis_label: true
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    show_null_labels: false
    show_dropoff: true
    listen:
      closed_quarter: opportunity.closed_quarter
      business_segment: salesrep.business_segment

  - name: meeting_to_close
    title: Meeting to Close
    type: looker_column
    model: salesforce
    explore: funnel
    measures: [meeting.count, opportunity.count, opportunity.count_won]
    filters:
      opportunity.type: New Business
    sorts: [opportunity.count_won desc]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#5245ed', '#776fdf', '#1ea8df', '#a2dcf3', '#49cec1', '#776fdf', '#49cec1',
      '#1ea8df', '#a2dcf3', '#776fdf', '#776fdf', '#635189']
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    show_view_names: true
    series_labels:
      meeting.count: Meetings
      opportunity.count: Opportunities
      opportunity.count_won: Wins
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: false
    y_axis_tick_density: default
    show_x_axis_label: true
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    show_null_labels: false
    show_dropoff: true
    listen:
      closed_quarter: opportunity.closed_quarter
      sales_rep_name: salesrep.name

  
  
  
  
