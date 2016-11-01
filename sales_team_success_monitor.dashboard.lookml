## Need to add callouts for goal tracking/comparisons to previous quarters
## Need linkage to other dashboards

- dashboard: sales_team_success_monitor
  title: Sales Team Success Monitor
  layout: grid
  rows:
    - elements: [agregate_sales_tracking]
      height: 400
    - elements: [recent_deals_closed, deals_on_deck]
      height: 400
    - elements: [ pipeline_forecast, quarterly_pipeline_dev]
      height: 400
    - elements: [performance_by_sales_segment, funnel_by_sales_segment]
      height: 400
    - elements: [acv_by_sales_rep]
      height: 400
  tile_size: 100


  elements:

  - name: agregate_sales_tracking
    title: Aggregate Sales Team Tracking to Quota (Current Quarter)
    type: looker_area
    model: salesforce
    explore: the_switchboard
    dimensions: [opportunity.closed_week]
    measures: [opportunity.total_acv_won]
    dynamic_fields:
    - table_calculation: calculation_1
      label: Calculation 1
      expression: running_total(${opportunity.total_acv_won})
      value_format_name: usd
    hidden_fields: [opportunity.total_acv_won]
    filters:
      opportunity.is_current_quarter: 'Yes'
    sorts: [opportunity.closed_week]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#294987', '#5a1038', '#ff947c', '#1f6b62', '#764173', '#910303', '#b2947c',
      '#192d54', '#a31e67', '#a16154', '#0f544b', '#ffd9ba']
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    y_axis_combined: true
    y_axis_max: ['23000000']
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_labels: [Total ACV Won]
    y_axis_tick_density: default
    show_x_axis_label: true
    x_axis_label: Opportunity Closed Week
    show_x_axis_ticks: true
    x_axis_scale: auto
    reference_lines: [{reference_type: line, range_start: max, range_end: min, margin_top: deviation,
        margin_value: mean, margin_bottom: deviation, line_value: '15400000', color: purple,
        label: Goal ($15.4M)}]
    show_null_points: true
    point_style: none
    interpolation: monotone

  - name: recent_deals_closed
    title: Deals Closed (Past Week)
    type: table
    model: salesforce
    explore: the_switchboard
    dimensions: [account.name, salesrep.name]
    measures: [opportunity.total_acv_won, opportunity.total_mrr]
    filters:
      opportunity.closed_week: 1 weeks
      opportunity.is_won: 'Yes'
    sorts: [opportunity.acv desc, opportunity.total_acv_won desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_view_names: true
    show_row_numbers: true
    truncate_column_names: false

  - name: deals_on_deck
    title: Deals on Deck (Winning)
    type: table
    model: salesforce
    explore: the_switchboard
    dimensions: [account.name, opportunity.acv, opportunity.days_open, salesrep.name,
      salesrep.business_segment]
    filters:
      meeting.is_closed: 'No'
      opportunity.probability_group: Above 80%
      opportunity.stage_name_funnel: Winning
      salesrep.business_segment: -Top of Funnel/Not Assigned
    sorts: [opportunity.acv desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_view_names: true
    show_row_numbers: false
    truncate_column_names: false

  - name: pipeline_forecast
    title: Pipeline Forecast
    type: looker_column
    model: salesforce
    explore: the_switchboard
    dimensions: [opportunity.probability_group, opportunity.closed_month]
    pivots: [opportunity.probability_group]
    measures: [opportunity.total_acv]
    filters:
      opportunity.closed_month: 9 months ago for 12 months
    sorts: [opportunity.probability_group, opportunity.closed_month, opportunity.probability_group__sort_]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: normal
    colors: [lightgrey, '#1FD110', '#95d925', '#d0ca0e', '#c77706', '#bf2006', black]
    show_value_labels: true
    label_density: 21
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: false
    show_view_names: false
    series_labels:
      '0': Lost
      100 or Above: Won
    hidden_series: [Under 20%, Lost]
    y_axis_combined: true
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_labels: [Amount in Pipeline]
    y_axis_tick_density: default
    show_x_axis_label: true
    x_axis_label: Opportunity Close Month
    show_x_axis_ticks: true
    x_axis_datetime_label: '%b %y'
    x_axis_scale: ordinal
    ordering: none
    show_null_labels: false

  - name: quarterly_pipeline_dev
    title: Quarterly Pipeline Development Report
    type: looker_area
    model: salesforce
    explore: historical_snapshot
    dimensions: [historical_snapshot.snapshot_date, historical_snapshot.probability_tier]
    pivots: [historical_snapshot.probability_tier]
    measures: [historical_snapshot.total_amount]
    filters:
      historical_snapshot.close_date: 2016/01/01 to 2016/03/31
      historical_snapshot.snapshot_date: 2015/07/01 to 2016/04/01
      historical_snapshot.stage_name_funnel: Won,Winning,Trial,Prospect
    sorts: [historical_snapshot.snapshot_date, historical_snapshot.snapshot_month desc,
      historical_snapshot.close_month, historical_snapshot.stage_name_funnel__sort_,
      historical_snapshot.probability_tier, historical_snapshot.probability_tier__sort_]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: normal
    colors: [black, '#1FD110', '#95d925', '#d0ca0e', '#c77706', '#bf2006', lightgrey,
      black]
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    hidden_series: [20 - 39%, 1 - 19%]
    y_axis_combined: true
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    show_x_axis_label: true
    show_x_axis_ticks: true
    x_axis_scale: auto
    reference_lines: [{reference_type: line, range_start: max, range_end: min, margin_top: deviation,
        margin_value: mean, margin_bottom: deviation, line_value: '7200000', label: Goal ($7.2M),
        color: purple}]
    point_style: none
    interpolation: linear

  - name: performance_by_sales_segment
    title: Sales Segment Performance
    type: looker_column
    model: salesforce
    explore: the_switchboard
    dimensions: [salesrep.business_segment]
    measures: [opportunity.total_acv_won, opportunity.win_percentage]
    filters:
      opportunity.is_current_quarter: 'Yes'
      salesrep.business_segment: -Top of Funnel/Not Assigned
    sorts: [opportunity.total_acv_won desc]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#1ea8df', '#a2dcf3']
    show_value_labels: true
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    series_labels:
      company.count_customer: Total Customers
      opportunity.total_acv_m: Total ACV (M)
    y_axis_combined: false
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_labels: [Total Customers, Total ACV (M)]
    y_axis_tick_density: default
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_orientation: [left, right]
    show_null_labels: false

  - name: funnel_by_sales_segment
    title: Lead to Win Funnel by Business Segment
    type: looker_column
    model: salesforce
    explore: funnel
    dimensions: [salesrep.business_segment]
    measures: [lead.count, meeting.count, opportunity.count, opportunity.count_won]
    filters:
      account.type: Customer
      opportunity.type: New Business
      salesrep.business_segment: -Top of Funnel/Not Assigned
    sorts: [lead.count desc]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#635189', '#b3a0dd', '#a2dcf3', '#1ea8df']
    show_value_labels: true
    label_density: 10
    label_color: ['#635189', '#b3a0dd', '#a2dcf3', '#1ea8df']
    legend_position: center
    x_axis_gridlines: false
    show_view_names: false
    series_labels:
      lead.count: Leads
      meeting.count: Meetings
      opportunity.count: Opportunities
      opportunity.count_won: Won Opportunities
    y_axis_combined: true
    show_y_axis_labels: true
    show_y_axis_ticks: false
    y_axis_tick_density: default
    show_x_axis_label: true
    show_x_axis_ticks: true
    x_axis_scale: auto
    show_null_labels: false
    show_dropoff: true

  - name: acv_by_sales_rep
    title: Current Quarter AVC (Won and Pipeline) by Sales Rep
    type: looker_column
    model: salesforce
    explore: the_switchboard
    dimensions: [salesrep.name]
    measures: [opportunity.total_acv_won, opportunity.total_pipeline_acv]
    filters:
      opportunity.is_current_quarter: 'Yes'
      salesrep.name: -NULL
      opportunity.total_acv_won: '>0'
    sorts: [opportunity.total_acv_won desc]
    limit: 12
    query_timezone: America/Los_Angeles
    stacking: normal
    colors: ['#62bad4', '#a9c574', '#929292', '#9fdee0', '#1f3e5a', '#90c8ae', '#92818d',
      '#c5c6a6', '#82c2ca', '#cee0a0', '#928fb4', '#9fc190']
    show_value_labels: true
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: true
    x_padding_right: 15
    y_axis_combined: true
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: auto
    x_axis_label_rotation: 0
    ordering: none
    show_null_labels: false