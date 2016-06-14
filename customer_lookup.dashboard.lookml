#----------------------------
- dashboard: customer_lookup
#----------------------------
  title: Customer Lookup
  layout: grid
  rows:
#     - elements: [account_information]
#       height: 100
    - elements: [health, mrr, days_to_renewal, active_users, license_utilization, zd_tickets]
      height: 200
#     - elements: [product_usage]
#       height: 100
    - elements: [trending_health_score, dau_mau_ratio, usage_by_user]
      height: 400
    - elements: [monthly_feature_usage_report]
      height: 350
#     - elements: [recent_account_activity]
#       height: 100
    - elements: [opportunity_history, support_tickets_by_week]
      height: 300

  filters:
    - name: account_name
      type: field_filter
      explore: the_switchboard
      field: account.name

  elements:

#     - name: account_information
#       type: "text"
#       title_text: "Account Information"
#       subtitle_text: "License, Health and MRR"
#   
    #   - name: account_tier
  #     type: single_value
  #     model: salesforce
  #     explore: the_switchboard
  #     dimensions: [account.account_tier]
  #     dynamic_fields:
  #     - table_calculation: account_tier
  #       label: Account Tier
  #       expression: ${account.account_tier}
  #     hidden_fields: [account.account_tier]
  #     listen:
  #       account_name: account.name
  #     sorts: [opportunity.account_tier, account.account_tier]
  #     limit: 1
  #     query_timezone: America/Los_Angeles
  #     show_single_value_title: true
  #     value_format: ''
  #     show_comparison: false
  
    - name: health
      type: single_value
      model: salesforce
      explore: the_switchboard
      dimensions: [weekly_event_rollup.event_months_ago]
      measures: [weekly_event_rollup.average_account_health]
      dynamic_fields:
      - table_calculation: health_score
        label: Health Score
        expression: ${weekly_event_rollup.average_account_health}
        value_format_name: decimal_0
      - table_calculation: pts
        label: pts
        expression: (${health_score}-offset(${health_score},1))
        value_format_name: decimal_0
      hidden_fields: [weekly_event_rollup.average_account_health]
      filters:
        opportunity.is_won: 'Yes'
        weekly_event_rollup.event_months_ago: '0,1'
      sorts: [weekly_event_rollup.event_months_ago]
      limit: 100
      query_timezone: America/Los_Angeles
      show_single_value_title: true
      show_comparison: true
      comparison_type: change
      comparison_reverse_colors: false
      show_comparison_label: true
  
    - name: mrr
      type: single_value
      model: salesforce
      explore: the_switchboard
      measures: [opportunity.total_pipeline_mrr]
      listen:
        account_name: account.name
      sorts: [opportunity.total_pipeline_mrr desc]
      limit: 500
      query_timezone: America/Los_Angeles
      show_single_value_title: true
      value_format: $#,##0
      show_comparison: false
  
    - name: days_to_renewal
      type: single_value
      model: salesforce
      explore: the_switchboard
      dimensions: [account.days_to_contract_renewal]
      listen:
        account_name: account.name
      sorts: [account.days_to_contract_renewal]
      limit: 1
      query_timezone: America/Los_Angeles
      show_single_value_title: true
      show_comparison: false
  
    - name: active_users
      type: single_value
      model: salesforce
      explore: weekly_event_rollup
      measures: [daily_event_rollup.user_count]
      listen:
        account_name: account.name
      sorts: [event.user_count desc, feature_usage.user_count desc, daily_event_rollup.user_count desc]
      limit: 500
      query_timezone: America/Los_Angeles
      show_single_value_title: true
      show_comparison: false
  
    - name: license_utilization
      type: single_value
      model: salesforce
      explore: weekly_event_rollup
      measures: [daily_event_rollup.user_count]
      dynamic_fields:
      - table_calculation: license_utilization
        label: License Utilization
        expression: (${daily_event_rollup.user_count} + ${users_over_contract}) / ${daily_event_rollup.user_count}
        value_format_name: percent_0
      - table_calculation: users_over_contract
        label: Users Over Contract
        expression: ${daily_event_rollup.user_count} * rand() * 0.25
        value_format_name: decimal_0
      hidden_fields: [daily_event_rollup.user_count]
      listen:
        account_name: account.name
      sorts: [event.user_count desc, feature_usage.user_count desc, daily_event_rollup.user_count desc]
      limit: 500
      query_timezone: America/Los_Angeles
      show_single_value_title: true
      show_comparison: true
      comparison_type: value
      show_comparison_label: true
  
    - name: zd_tickets
      title: ZD Tickets (30 days)
      type: single_value
      model: salesforce
      explore: the_switchboard
      measures: [zendesk_ticket.count]
      listen:
        account_name: account.name
      filters:
        zendesk_ticket.created_date: 30 days
      sorts: [zendesk_ticket.created_date desc, zendesk_ticket.count desc]
      limit: 500
      column_limit: 50
      query_timezone: America/Los_Angeles
      show_single_value_title: true
      show_comparison: false
  
#     - name: product_usage
#       type: text
#       title_text: "Product Usage and Engagement"
#       subtitle_text: "Health Score, DAU-MAU, Usage"
  
    - name: trending_health_score
      type: looker_line
      model: salesforce
      explore: the_switchboard
      dimensions: [weekly_event_rollup.event_weeks_ago]
      measures: [weekly_event_rollup.average_account_health]
      listen:
        account_name: account.name
      filters:
        weekly_event_rollup.event_weeks_ago: <=52
      sorts: [weekly_event_rollup.event_weeks_ago desc]
      limit: 500
      query_timezone: America/Los_Angeles
      stacking: ''
      colors: ['#5245ed', '#a2dcf3', '#776fdf', '#1ea8df', '#49cec1', '#776fdf', '#49cec1',
        '#1ea8df', '#a2dcf3', '#776fdf', '#776fdf', '#635189']
      show_value_labels: false
      label_density: 25
      legend_position: center
      x_axis_gridlines: false
      y_axis_gridlines: true
      show_view_names: false
      limit_displayed_rows: false
      y_axis_combined: true
      y_axis_min: ['0']
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
          range_end: min, margin_top: '10', margin_value: '60', margin_bottom: '10', color: '#e9b404',
          label: Standard}, {reference_type: margins, line_value: mean, range_start: max,
          range_end: min, margin_top: '15', margin_value: '85', margin_bottom: '15', label: Safe,
          color: '#49cec1'}]
      show_null_points: false
      point_style: circle_outline
      interpolation: linear
  
    - name: dau_mau_ratio
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
      listen:
        account_name: account.name
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
  
    - name: usage_by_user
      title: Usage by User - Past Week
      type: looker_bar
      model: salesforce
      explore: weekly_event_rollup
      dimensions: [daily_event_rollup.instance_user_id]
      measures: [daily_event_rollup.usage_minutes]
      listen:
        account_name: account.name
      filters:
        weekly_event_rollup.event_weeks_ago: '1'
      sorts: [daily_event_rollup.usage_minutes desc]
      limit: 20
      query_timezone: America/Los_Angeles
      stacking: ''
      colors: ['#5245ed', '#a2dcf3', '#776fdf', '#1ea8df', '#49cec1', '#776fdf', '#49cec1',
        '#1ea8df', '#a2dcf3', '#776fdf', '#776fdf', '#635189']
      show_value_labels: false
      label_density: 25
      legend_position: center
      y_axis_gridlines: true
      show_view_names: false
      limit_displayed_rows: false
      y_axis_combined: true
      show_y_axis_labels: true
      show_y_axis_ticks: true
      y_axis_tick_density: default
      show_x_axis_label: false
      show_x_axis_ticks: false
      x_axis_scale: auto
      y_axis_scale_mode: linear
      reference_lines: [{reference_type: line, range_start: max, range_end: min, margin_top: deviation,
          margin_value: mean, margin_bottom: deviation, line_value: median, label: 'Median:
            {{median}} mins', value_format: '#'}]
      show_null_labels: false
  
    - name: monthly_feature_usage_report
      type: table
      model: salesforce
      explore: weekly_event_rollup
      dimensions: [weekly_event_rollup.event_months_ago]
      measures: [weekly_event_rollup.average_account_health, weekly_event_rollup.total_usage,
        weekly_event_rollup.total_count_of_logins, weekly_event_rollup.total_count_of_query_runs,
        weekly_event_rollup.total_count_of_query_result_downloads, weekly_event_rollup.total_count_of_git_commits,
        weekly_event_rollup.total_count_of_api_calls, weekly_event_rollup.total_count_of_support_chats,
        weekly_event_rollup.total_count_of_dashboard_queries, weekly_event_rollup.total_count_of_dashboard_downloads]
      listen:
        account_name: account.name
      filters:
        weekly_event_rollup.event_months_ago: <=12
      sorts: [weekly_event_rollup.event_months_ago]
      limit: 500
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
        weekly_event_rollup.concentration_score: Concentration Score
      table_theme: white
      limit_displayed_rows: false
  
#     - name: recent_account_activity
#       type: text
#       title_text: "Recent Account Activity"
#       subtitle_text: "Opportunity Events, Support Tickets"
  
    - name: opportunity_history
      type: table
      model: salesforce
      explore: the_switchboard
      dimensions: [opportunity.closed_date, opportunity.type, opportunity.stage_name,
        opportunity.id, opportunity.acv, opportunity.mrr, opportunity.nrr]
      listen:
        account_name: account.name
      filters:
        opportunity.id: -NULL
      sorts: [opportunity.closed_date desc]
      limit: 500
      query_timezone: America/Los_Angeles
      show_view_names: false
      show_row_numbers: false
      truncate_column_names: false
      series_labels:
        opportunity.id: Salesforce Lookup
      table_theme: white
      limit_displayed_rows: false
  
    - name: support_tickets_by_week
      type: looker_column
      model: salesforce
      explore: the_switchboard
      dimensions: [zendesk_ticket.created_week, zendesk_ticket.tone]
      pivots: [zendesk_ticket.tone]
      measures: [zendesk_ticket.count]
      listen:
        account_name: account.name
      filters:
        zendesk_ticket.created_week: NOT NULL
      sorts: [zendesk_ticket.created_date desc, zendesk_ticket.created_week desc, zendesk_ticket.tone desc]
      limit: 500
      column_limit: 50
      query_timezone: America/Los_Angeles
      stacking: normal
      colors: ['#5245ed', '#a2dcf3', '#776fdf', '#1ea8df', '#49cec1', '#776fdf', '#49cec1',
        '#1ea8df', '#a2dcf3', '#776fdf', '#776fdf', '#635189']
      show_value_labels: false
      label_density: 25
      legend_position: center
      x_axis_gridlines: false
      y_axis_gridlines: true
      show_view_names: false
      series_colors:
        neutral: lightblue
        ∅: lightgrey
        angry: red
        annoyed: pink
        happy: green
        negative: red
        positive: green
        very_negative: darkred
      limit_displayed_rows: false
      y_axis_combined: true
      show_y_axis_labels: true
      show_y_axis_ticks: true
      y_axis_tick_density: default
      show_x_axis_label: false
      show_x_axis_ticks: true
      x_axis_datetime_label: '%b'
      x_axis_scale: time
      ordering: none
      show_null_labels: false
      show_totals_labels: false
      show_silhouette: false
      totals_color: '#808080'