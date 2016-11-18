#----------------------------
- dashboard: customer_overview
#----------------------------
  title: Customer Overview
  layout: grid
  rows:
    - elements: [total_active_customers, customer_health_count, cmrr, customer_health_mrr]
      height: 200
    - elements: [net_expansion_by_month]
      height: 400
    - elements: [potential_churn_by_close_month, count_of_accounts_per_health_tier]
      height: 400
    - elements: [average_usage, average_account_health_by_signup_week]
      height: 400
    - elements: [dau_mau_ratio_trailing_365]
      height: 400

  elements:

  - name: total_active_customers
    type: single_value
    model: salesforce
    explore: the_switchboard
    dimensions: [account.created_week]
    measures: [weekly_event_rollup.count_of_accounts]
    dynamic_fields:
    - table_calculation: total_customers
      label: Total Customers
      expression: |
        ${weekly_event_rollup.count_of_accounts:total}
    - table_calculation: new_this_week
      label: new this week
      expression: ${weekly_event_rollup.count_of_accounts}
    hidden_fields: [weekly_event_rollup.count_of_accounts]
    filters:
      account.account_status: -Black (Discontinued)
      account.current_customer: 'Yes'
      account.type: Customer
      weekly_event_rollup.event_weeks_ago: '1'
    sorts: [account.created_week desc]
    limit: 500
    total: true
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: true
    comparison_type: change
    comparison_reverse_colors: false
    show_comparison_label: true

  - name: customer_health_count
    type: looker_pie
    model: salesforce
    explore: the_switchboard
    dimensions: [weekly_event_rollup.account_health]
    measures: [weekly_event_rollup.count_of_accounts]
    filters:
      account.account_status: -Black (Discontinued)
      account.current_customer: 'Yes'
      account.type: Customer
      weekly_event_rollup.event_weeks_ago: '1'
    sorts: [weekly_event_rollup.account_health]
    limit: 500
    total: true
    query_timezone: America/Los_Angeles
    value_labels: labels
    label_type: val
    colors: ['#5245ed', '#776fdf', '#1ea8df', '#a2dcf3', '#49cec1', '#776fdf', '#49cec1',
      '#1ea8df', '#a2dcf3', '#776fdf', '#776fdf', '#635189']
    series_colors:
      1. At Risk: '#dc7350'
      2. Standard: '#e9b404'
      3. Safe: '#49cec1'
    show_view_names: true

  - name: cmrr
    title: cMRR
    type: single_value
    model: salesforce
    explore: the_switchboard
    dimensions: [opportunity.closed_week]
    measures: [opportunity.total_mrr]
    dynamic_fields:
    - table_calculation: total_cmrr
      label: Total cMRR
      expression: sum(${new_mrr_this_week})
      value_format_name: usd_large
    - table_calculation: new_mrr_this_week
      label: new MRR this week
      expression: ${opportunity.total_mrr}
      value_format_name: usd_large
    hidden_fields: [opportunity.total_mrr]
    filters:
      account.account_status: -Black (Discontinued)
      account.current_customer: 'Yes'
      account.type: Customer
      opportunity.closed_week: before tomorrow
      weekly_event_rollup.event_weeks_ago: '1'
    sorts: [opportunity.closed_week desc]
    limit: 500
    total: true
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: true
    comparison_type: change
    comparison_reverse_colors: false
    show_comparison_label: true

  - name: customer_health_mrr
    title: Customer Health MRR
    type: looker_pie
    model: salesforce
    explore: the_switchboard
    dimensions: [weekly_event_rollup.account_health]
    measures: [opportunity.total_mrr]
    dynamic_fields:
    - table_calculation: total_mrr
      label: Total MRR
      expression: ${opportunity.total_mrr}
      value_format_name: usd_0
    hidden_fields: [opportunity.total_mrr]
    filters:
      account.account_status: -Black (Discontinued)
      account.current_customer: 'Yes'
      account.type: Customer
      weekly_event_rollup.event_weeks_ago: '1'
    sorts: [weekly_event_rollup.account_health]
    limit: 500
    query_timezone: America/Los_Angeles
    value_labels: labels
    label_type: val
    colors: ['#5245ed', '#a2dcf3', '#776fdf', '#1ea8df', '#49cec1', '#776fdf', '#49cec1',
      '#1ea8df', '#a2dcf3', '#776fdf', '#776fdf', '#635189']
    series_colors:
      1. At Risk: '#dc7350'
      2. Standard: '#e9b404'
      3. Safe: '#49cec1'
    show_view_names: true

  - name: net_expansion_by_month
    type: looker_line
    model: salesforce
    explore: the_switchboard
    dimensions: [opportunity.closed_month]
    measures: [opportunity.total_churn_acv, opportunity.total_expansion_acv]
    dynamic_fields:
    - table_calculation: net_expansion
      label: Net Expansion
      expression: ${opportunity.total_expansion_acv} - ${opportunity.total_churn_acv}
    - table_calculation: expansion_acv
      label: Expansion ACV
      expression: ${opportunity.total_expansion_acv}
    - table_calculation: churn_acv
      label: Churn ACV
      expression: -1.0 * ${opportunity.total_churn_acv}
    hidden_fields: [opportunity.total_churn_acv, opportunity.total_expansion_acv]
    filters:
      opportunity.closed_week: 13 months
      opportunity.lost_reason: NULL,Non-renewal
      opportunity.type: Renewal,Addon/Upsell,NULL
    sorts: [opportunity.closed_month]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: [black, '#49cec1', '#dc7350']
    show_value_labels: true
    label_density: 25
    label_color: [black, transparent, transparent]
    font_size: 10px
    legend_position: center
    x_axis_gridlines: true
    y_axis_gridlines: true
    show_view_names: false
    series_types:
      expansion_acv: column
      churn_acv: column
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: true
    y_axis_tick_density: default
    y_axis_value_format: $#,##0
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: ordinal
    y_axis_scale_mode: linear
    label_value_format: $#,##0
    swap_axes: false
    show_null_points: true
    point_style: circle_outline
    interpolation: linear

  - name: potential_churn_by_close_month
    type: looker_column
    model: salesforce
    explore: weekly_event_rollup
    dimensions: [opportunity.closed_month, opportunity.churn_status]
    pivots: [opportunity.churn_status]
    measures: [account.count]
    filters:
      account.account_status: -Black (Discontinued)
      account.current_customer: 'Yes'
      opportunity.churn_status: 3 - Red,2 - Orange,1 - Yellow
    sorts: [opportunity.closed_month desc, opportunity.churn_status]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: normal
    colors: ['#5245ed', '#a2dcf3', '#776fdf', '#1ea8df', '#49cec1', '#776fdf', '#49cec1',
      '#1ea8df', '#a2dcf3', '#776fdf', '#776fdf', '#635189']
    show_value_labels: true
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: true
    series_colors:
      1 - Yellow: '#e9b404'
      3 - Red: '#dc7350'
      2 - Orange: '#ff7f00'
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    show_x_axis_label: true
    show_x_axis_ticks: true
    x_axis_scale: auto
    ordering: none
    show_null_labels: false
    show_totals_labels: false
    show_silhouette: false
    totals_color: '#808080'

  - name: count_of_accounts_per_health_tier
    title: Count of Accounts per Health Tier
    type: looker_column
    model: salesforce
    explore: weekly_event_rollup
    dimensions: [weekly_event_rollup.account_health, weekly_event_rollup.event_weeks_ago]
    pivots: [weekly_event_rollup.account_health]
    measures: [weekly_event_rollup.count_of_accounts]
    filters:
      account.account_status: -Black (Discontinued)
      account.current_customer: 'Yes'
      weekly_event_rollup.event_months_ago: <=12
    sorts: [weekly_event_rollup.account_health, weekly_event_rollup.event_weeks_ago desc]
    limit: 500
    column_limit: 50
    row_total: right
    query_timezone: America/Los_Angeles
    stacking: normal
    colors: ['#dc7350', '#e9b404', '#49cec1']
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: true
    y_axis_gridlines: true
    show_view_names: false
    series_colors:
      At Risk: '#dc7350'
      Standard: '#e9b404'
      Safe: '#49cec1'
    limit_displayed_rows: false
    hidden_series: [Row Total]
    y_axis_combined: true
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    show_x_axis_label: true
    show_x_axis_ticks: true
    x_axis_scale: ordinal
    ordering: none
    show_null_labels: false
    show_totals_labels: false
    show_silhouette: false
    totals_color: '#808080'

  - name: average_usage
    type: looker_line
    model: salesforce
    explore: weekly_event_rollup
    dimensions: [weekly_event_rollup.event_week]
    measures: [weekly_event_rollup.cumulative_weekly_users, weekly_event_rollup.total_usage]
    dynamic_fields:
    - table_calculation: avg_mins
      label: Avg Mins
      expression: ${weekly_event_rollup.total_usage} / ${weekly_event_rollup.cumulative_weekly_users} / 60
      value_format_name: decimal_0
    - table_calculation: total_users
      label: Total Users
      expression: ${weekly_event_rollup.cumulative_weekly_users}
    hidden_fields: [weekly_event_rollup.total_usage, weekly_event_rollup.cumulative_weekly_users]
    filters:
      weekly_event_rollup.event_week: 26 weeks
    sorts: [weekly_event_rollup.event_week]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#ff1200', '#0e0e83']
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    series_types:
      total_users: column
    limit_displayed_rows: false
    y_axis_combined: false
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    show_x_axis_label: true
    show_x_axis_ticks: true
    x_axis_scale: ordinal
    y_axis_scale_mode: linear
    y_axis_orientation: [left, right]
    show_null_points: true
    point_style: circle_outline
    interpolation: linear

  - name: average_account_health_by_signup_week
    title: Average Account Health by Weeks Since Signup
    type: looker_line
    model: salesforce
    explore: weekly_event_rollup
    dimensions: [weekly_event_rollup.weeks_since_signup]
    measures: [weekly_event_rollup.average_account_health]
    filters:
      opportunity.is_won: 'Yes'
      weekly_event_rollup.event_week: NOT NULL
      weekly_event_rollup.weeks_since_signup: '[0, 52]'
    sorts: [weekly_event_rollup.weeks_since_signup]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: [black]
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    series_types:
      '#49cec1':
      '#e9b404':
      '#dc7350':
    limit_displayed_rows: false
    hidden_series: [average_usage]
    y_axis_combined: true
    y_axis_max: ['100']
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    show_x_axis_label: true
    show_x_axis_ticks: true
    x_axis_scale: ordinal
    y_axis_scale_mode: linear
    reference_lines: [{reference_type: margins, line_value: mean, range_start: max,
        range_end: min, margin_top: '25', margin_value: '25', margin_bottom: '25', label: At Risk,
        color: '#dc7350'}, {reference_type: margins, line_value: mean, range_start: max,
        range_end: min, margin_top: '10', margin_value: '60', margin_bottom: '10', label: Standard,
        color: '#e9b404'}, {reference_type: margins, line_value: mean, range_start: max,
        range_end: min, margin_top: '15', margin_value: '85', margin_bottom: '15', label: Safe,
        color: '#49cec1'}]
    y_axis_orientation: [left, right, left]
    show_null_points: false
    point_style: none
    interpolation: linear

  - name: dau_mau_ratio_trailing_365
    title: DAU-MAU Ratio - Trailing 365 Days
    type: looker_line
    model: salesforce
    explore: rolling_30_day_activity_facts
    dimensions: [rolling_30_day_activity_facts.date_date]
    measures: [rolling_30_day_activity_facts.user_count_active_this_day, rolling_30_day_activity_facts.user_count_active_30_days]
    dynamic_fields:
    - table_calculation: dau_mau_ratio
      label: DAU-MAU Ratio
      expression: ${rolling_30_day_activity_facts.user_count_active_this_day} / ${rolling_30_day_activity_facts.user_count_active_30_days}
      value_format_name: percent_2
    - table_calculation: 7_day_rolling_avg_dau_mau
      label: 7-Day Rolling Avg DAU-MAU
      expression: mean(offset_list(${dau_mau_ratio}, 0, 7))
      value_format_name: percent_0
    hidden_fields: [rolling_30_day_activity_facts.user_count_active_this_day, dau_mau_ratio]
    filters:
      rolling_30_day_activity_facts.date_date: 365 days
    sorts: [rolling_30_day_activity_facts.date_date desc]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#5245ed', '#ed6168', '#1ea8df', '#353b49', '#49cec1', '#b3a0dd', '#db7f2a',
      '#706080', '#a2dcf3', '#776fdf', '#e9b404', '#635189']
    show_value_labels: false
    label_density: 14
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    limit_displayed_rows: false
    y_axis_combined: false
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_labels: [User Count]
    y_axis_tick_density: default
    y_axis_value_format: ''
    show_x_axis_label: true
    x_axis_label: Date
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    y_axis_orientation: [left, right]
    show_null_points: true
    point_style: none
    interpolation: linear
