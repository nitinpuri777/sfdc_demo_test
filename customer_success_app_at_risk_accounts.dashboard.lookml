#----------------------------
- dashboard: customer_success_app_at_risk_account
#----------------------------
  title: Customer Success - At Risk Accounts
  layout: grid
  rows:
    - elements: [count_of_at_risk_accounts, total_at_risk_customer_mrr, percent_of_at_risk_accounts, average_health_of_at_risk_accounts]
      height: 180
    - elements: [account_health_by_week]
      height: 300
    - elements: [red_accounts, health_score_jumps, health_score_decliners]
      height: 400
    - elements: [list_of_red_accounts]
      height: 400
    - elements: [negative_zd_tickets, upcoming_renewals]
      height: 300

  elements:

  - name: count_of_at_risk_accounts
    type: single_value
    model: salesforce
    explore: the_switchboard
    measures: [weekly_event_rollup.count_of_red_accounts]
    filters:
      account.current_customer: 'Yes'
      account.type: Customer
      opportunity.is_won: 'Yes'
      weekly_event_rollup.event_months_ago: '1'
    sorts: [weekly_event_rollup.count_of_red_accounts desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: false

  - name: total_at_risk_customer_mrr
    title: Total At Risk Customer MRR
    type: single_value
    model: salesforce
    explore: the_switchboard
    measures: [opportunity.total_mrr]
    filters:
      account.current_customer: 'Yes'
      account.type: Customer
      opportunity.is_won: 'Yes'
      weekly_event_rollup.account_health_score: <50
      weekly_event_rollup.event_months_ago: '1'
    sorts: [opportunity.total_mrr desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: false

  - name: percent_of_at_risk_accounts
    title: Percent of At Risk Accounts
    type: single_value
    model: salesforce
    explore: the_switchboard
    measures: [weekly_event_rollup.percent_red_accounts]
    filters:
      account.current_customer: 'Yes'
      account.type: Customer
      opportunity.is_won: 'Yes'
      weekly_event_rollup.event_months_ago: '1'
    sorts: [weekly_event_rollup.percent_red_accounts desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: false

  - name: average_health_of_at_risk_accounts
    title: Average Health of At Risk Accounts
    type: single_value
    model: salesforce
    explore: the_switchboard
    measures: [weekly_event_rollup.average_account_health]
    dynamic_fields:
    - table_calculation: average_health_of_at_risk_accounts
      label: Average Health of At Risk Accounts
      expression: ${weekly_event_rollup.average_account_health}
      value_format_name: decimal_1
    hidden_fields: [weekly_event_rollup.average_account_health]
    filters:
      account.current_customer: 'Yes'
      account.type: Customer
      opportunity.is_won: 'Yes'
      weekly_event_rollup.account_health_score: <50
      weekly_event_rollup.event_months_ago: '1'
    sorts: [weekly_event_rollup.average_account_health desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: false

  - name: account_health_by_week
    title: Account Health by Week
    type: looker_line
    model: salesforce
    explore: weekly_event_rollup
    dimensions: [weekly_event_rollup.event_weeks_ago]
    measures: [weekly_event_rollup.average_account_health]
    filters:
      opportunity.is_won: 'Yes'
      weekly_event_rollup.event_weeks_ago: <52
    sorts: [weekly_event_rollup.event_weeks_ago desc]
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
        range_end: min, margin_top: '20', margin_value: '20', margin_bottom: '20', label: At Risk,
        color: '#dc7350'}, {reference_type: margins, line_value: mean, range_start: max,
        range_end: min, margin_top: '15', margin_value: '55', margin_bottom: '15', label: Standard,
        color: '#e9b404'}, {reference_type: margins, line_value: mean, range_start: max,
        range_end: min, margin_top: '15', margin_value: '85', margin_bottom: '15', label: Safe,
        color: '#49cec1'}]
    y_axis_orientation: [left, right, left]
    show_null_points: false
    point_style: none
    interpolation: linear

  - name: red_accounts
    title: Red Accounts
    type: looker_column
    model: salesforce
    explore: the_switchboard
    dimensions: [weekly_event_rollup.event_months_ago]
    measures: [weekly_event_rollup.count_of_red_accounts]
    filters:
      account.current_customer: 'Yes'
      account.type: Customer
      opportunity.is_won: 'Yes'
      weekly_event_rollup.event_months_ago: <=12
    sorts: [weekly_event_rollup.event_months_ago desc]
    limit: 500
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#F16358', '#E0635E', '#D06464', '#BF656B', '#AF6671', '#9F6777', '#8E687E',
      '#7E6984', '#6E6A8A', '#5D6B91', '#4D6C97', '#3D6D9E']
    show_value_labels: false
    label_density: 25
    font_size: medium
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: true
    series_colors:
      weekly_event_rollup.count_of_red_accounts: '#dc7350'
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_labels: [Count]
    y_axis_tick_density: default
    show_x_axis_label: true
    x_axis_label: Months Ago
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    show_null_labels: false

  - name: health_score_jumps
    title: Health Score Jumps (Week over Week)
    type: looker_column
    model: salesforce
    explore: weekly_event_rollup
    dimensions: [account.name]
    measures: [weekly_event_rollup.average_account_health_change]
    hidden_fields: [change_3, health_score_change_from_two_week_ago_to_this_week, health_score_change_from_two_weeks_ago_to_last_week]
    filters:
      account.account_status: -Black (Discontinued)
      account.current_customer: 'Yes'
      account.type: Customer
      opportunity.is_won: 'Yes'
      weekly_event_rollup.account_health_score: <50
      weekly_event_rollup.average_account_health_change: '>0'
      weekly_event_rollup.average_account_health_this_week: NOT NULL
    sorts: [weekly_event_rollup.average_account_health_change desc]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: normal
    colors: ['#62bad4', '#a9c574', '#929292', '#9fdee0', '#1f3e5a', '#90c8ae', '#92818d',
      '#c5c6a6', '#82c2ca', '#cee0a0', '#928fb4', '#9fc190']
    show_value_labels: false
    label_density: 25
    legend_position: center
    hide_legend: false
    y_axis_gridlines: true
    show_view_names: true
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: true
    y_axis_tick_density: default
    show_x_axis_label: true
    show_x_axis_ticks: false
    x_axis_scale: auto
    reference_lines: [{reference_type: line, line_value: mean, range_start: max, range_end: min,
        margin_top: deviation, margin_value: mean, margin_bottom: deviation, label: ''}]
    ordering: none
    show_null_labels: false
    show_totals_labels: false
    show_silhouette: false
    totals_color: '#808080'

  - name: health_score_decliners
    title: Health Score Decliners (Week over Week)
    type: looker_column
    model: salesforce
    explore: weekly_event_rollup
    dimensions: [account.name]
    measures: [weekly_event_rollup.average_account_health_change]
    hidden_fields: [change_3, health_score_change_from_two_week_ago_to_this_week, health_score_change_from_two_weeks_ago_to_last_week]
    filters:
      account.account_status: -Black (Discontinued)
      account.current_customer: 'Yes'
      account.type: Customer
      opportunity.is_won: 'Yes'
      weekly_event_rollup.account_health_score: <50
      weekly_event_rollup.average_account_health_change: <0
      weekly_event_rollup.average_account_health_this_week: NOT NULL
    sorts: [weekly_event_rollup.average_account_health_change desc]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: normal
    colors: ['#62bad4', '#a9c574', '#929292', '#9fdee0', '#1f3e5a', '#90c8ae', '#92818d',
      '#c5c6a6', '#82c2ca', '#cee0a0', '#928fb4', '#9fc190']
    show_value_labels: false
    label_density: 25
    legend_position: center
    hide_legend: false
    y_axis_gridlines: true
    show_view_names: true
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: true
    y_axis_tick_density: default
    show_x_axis_label: true
    show_x_axis_ticks: false
    x_axis_scale: auto
    reference_lines: [{reference_type: line, line_value: mean, range_start: max, range_end: min,
        margin_top: deviation, margin_value: mean, margin_bottom: deviation, label: ''}]
    ordering: none
    show_null_labels: false
    show_totals_labels: false
    show_silhouette: false
    totals_color: '#808080'

  - name: list_of_red_accounts
    title: List of Red Accounts
    type: table
    model: salesforce
    explore: weekly_event_rollup
    dimensions: [account.name, account.days_to_contract_renewal]
    measures: [opportunity.total_mrr, weekly_event_rollup.average_account_health, weekly_event_rollup.total_usage,
      weekly_event_rollup.cumulative_weekly_users, weekly_event_rollup.total_count_of_logins,
      weekly_event_rollup.total_count_of_query_runs, weekly_event_rollup.total_count_of_query_result_downloads,
      weekly_event_rollup.total_count_of_git_commits, weekly_event_rollup.total_count_of_api_calls,
      weekly_event_rollup.total_count_of_support_chats, weekly_event_rollup.total_count_of_dashboard_queries,
      weekly_event_rollup.total_count_of_dashboard_downloads]
    filters:
      account.current_customer: 'Yes'
      account.type: Customer
      opportunity.is_won: 'Yes'
      weekly_event_rollup.event_months_ago: '1'
      weekly_event_rollup.average_account_health: <50
    sorts: [opportunity.total_mrr desc]
    limit: 20
    query_timezone: America/Los_Angeles
    show_view_names: false
    show_row_numbers: false
    truncate_column_names: true
    series_labels:
      weekly_event_rollup.average_account_health: Health Score
      weekly_event_rollup.event_months_ago: Months Ago
      weekly_event_rollup.total_count_of_logins: Logins
      weekly_event_rollup.total_count_of_query_runs: Queries
      weekly_event_rollup.total_count_of_query_result_downloads: Downloads
      weekly_event_rollup.total_count_of_git_commits: Git Commits
      weekly_event_rollup.total_count_of_api_calls: API Calls
      weekly_event_rollup.total_count_of_support_chats: ZD Chats
      weekly_event_rollup.total_count_of_dashboard_queries: Dash Queries
      weekly_event_rollup.total_count_of_dashboard_downloads: Dash Downloads
      account.days_to_contract_renewal: Days to Renewal
      opportunity.total_mrr: MRR
      weekly_event_rollup.cumulative_weekly_users: Users
    table_theme: white
    limit_displayed_rows: false

  - name: negative_zd_tickets
    title: Negative ZD Tickets (30 days)
    type: table
    model: salesforce
    explore: the_switchboard
    dimensions: [account.name, zendesk_ticket.created_date, zendesk_ticket.id,
      zendesk_ticket.status, zendesk_ticket.time_to_solve_hours]
    filters:
      account.name: -NULL
      zendesk_ticket.created_date: 30 days
      zendesk_ticket.tone: negative
    sorts: [zendesk_ticket.created_date desc, account.name]
    limit: 15
    column_limit: 50
    query_timezone: America/Los_Angeles
    show_view_names: false
    show_row_numbers: false
    truncate_column_names: false
    table_theme: white
    limit_displayed_rows: false

  - name: upcoming_renewals
    title: Upcoming Renewals
    type: table
    model: salesforce
    explore: the_switchboard
    dimensions: [account.name, account.days_to_contract_renewal, account.account_tier]
    measures: [opportunity.total_mrr]
    filters:
      account.days_to_contract_renewal: '[0, 30]'
    sorts: [account.days_to_contract_renewal]
    limit: 50
    query_timezone: America/Los_Angeles
    show_view_names: false
    show_row_numbers: false
    truncate_column_names: false
    series_labels:
      weekly_event_rollup.average_account_health_this_week: Health Score
    table_theme: white
    limit_displayed_rows: false
