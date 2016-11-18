- dashboard: sales_app_all_sales_pulse
  title: Sales App - All Sales Pulse
  layout: grid
  rows:
    - elements: [new_mrr, of_quota_this_time_last_q, new_acv, wins, days_left]
      height: 125
    - elements: [tracking_to_quota, pace_q_over_q]
      height: 350
    - elements: [pipeline_forecast, pipeline_by_sales_rep]
      height: 600
    - elements: [recent_deals, likely_to_close, at_risk_deals]
      height: 375

  filters:

  - name: quarter
    title: 'Quarter'
    type: date_filter
    default_value: this quarter

  elements:

  - name: new_mrr
    title: New MRR
    type: single_value
    model: salesforce
    explore: opportunity
    measures: [opportunity.total_mrr]
    sorts: [opportunity.total_mrr desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: false
    listen:
      quarter: opportunity.closed_quarter


  - name: wins
    title: Wins
    type: single_value
    model: salesforce
    explore: opportunity
    measures: [opportunity.count_current_quarter, opportunity.count_last_quarter]
    dynamic_fields:
    - table_calculation: difference_from_this_time_last_quarter
      label: Difference from this time Last Quarter
      expression: ${opportunity.count_current_quarter}-${opportunity.count_last_quarter}
    hidden_fields: [opportunity.count_last_quarter]
    filters:
      opportunity.is_quarter_to_date: 'Yes'
      opportunity.is_won: 'Yes'
    sorts: [opportunity.count_current_quarter desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: true
    comparison_type: change
    comparison_reverse_colors: false
    show_comparison_label: false
    listen:
      quarter: opportunity.closed_quarter

  - name: days_left
    title: Days Left
    type: single_value
    model: salesforce
    explore: opportunity
    dimensions: [opportunity.days_left_in_quarter]
    sorts: [opportunity.days_left_in_quarter]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    value_format: ''
    show_comparison: false

  - name: new_acv
    title: New ACV
    type: single_value
    model: salesforce
    explore: opportunity
    dimensions: [quota_aggregated.sales_team_quota]
    measures: [opportunity.total_acv_won]
    sorts: [opportunity.total_acv_won desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    show_comparison: true
    comparison_type: progress_percentage
    show_comparison_label: false
    listen:
      quarter: opportunity.closed_quarter

  - name: of_quota_this_time_last_q
    title: of Quota This Time Last Q
    type: single_value
    model: salesforce
    explore: opportunity
    measures: [quota_aggregated.tracking_to_quota]
    filters:
      opportunity.closed_quarter: last quarter
      opportunity.is_quarter_to_date: 'Yes'
    sorts: [tracking_to_quota desc, quota_aggregated.tracking_to_quota desc]
    limit: 500
    query_timezone: America/Los_Angeles
    show_single_value_title: true
    value_format: '#%'
    show_comparison: false

  - name: tracking_to_quota
    title: Tracking To Quota
    type: looker_line
    model: salesforce
    explore: opportunity
    dimensions: [salesrep.business_segment, opportunity.closed_week]
    pivots: [salesrep.business_segment]
    measures: [opportunity.total_acv_won, quota_aggregated.quota_sum]
    dynamic_fields:
    - table_calculation: acv_won_adjusted
      label: ACV Won Adjusted
      expression: |-
        if(diff_days(${opportunity.closed_week}, now()) < 0,
        null,
        running_total(${opportunity.total_acv_won}))
      value_format: '[>=1000000]0.00,,"M";[>=1000]0.00,"K";$0.00'
    - table_calculation: total_acv_won
      label: Total ACV Won
      expression: |-
        if(diff_days(${opportunity.closed_week}, now()) < 0,
        null,
        running_total(sum(pivot_row(${opportunity.total_acv_won}))))
      value_format_name: usd_0
    - table_calculation: goal
      label: Goal
      expression: (mean(pivot_index(${quota_aggregated.quota_sum},1)))/max(max(running_total(1))) * running_total(1)
      value_format_name: usd_0
    hidden_fields: [opportunity.total_acv_won, quota_aggregated.quota_sum]
    sorts: [opportunity.closed_week, salesrep.business_segment]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: ['#5245ed', '#635189', '#776fdf', '#1ea8df', red, '#a2dcf3', '#49cec1',
      '#1ea8df', '#a2dcf3', '#776fdf', '#776fdf', '#635189']
    show_value_labels: false
    label_density: 25
    legend_position: center
    y_axis_gridlines: true
    show_view_names: true
    series_types:
      Enterprise: column
      ? ''
      :
      Mid-Market: column
      Small Business: column
      Top of Funnel/Not Assigned: column
      goal: area
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_tick_density: default
    y_axis_value_format: $#,##0
    show_x_axis_label: true
    x_axis_label: Week of Quarter
    show_x_axis_ticks: false
    x_axis_scale: ordinal
    y_axis_scale_mode: linear
    reference_lines: [{reference_type: range, line_value: max, range_end: min, margin_top: deviation,
        margin_value: mean, margin_bottom: deviation, label: Goal, color: '#a2dcf3'}]
    show_null_points: false
    point_style: none
    interpolation: monotone
    listen:
      quarter: opportunity.closed_quarter


  - name: pace_q_over_q
    title: Pace (Q over Q)
    type: looker_line
    model: salesforce
    explore: opportunity
    dimensions: [opportunity.closed_day_of_quarter, opportunity.closed_quarter]
    pivots: [opportunity.closed_quarter]
    measures: [opportunity.total_acv_won, quota_aggregated.quota_sum]
    dynamic_fields:
    - table_calculation: to_quota
      label: '% to Quota'
      expression: |
        if(
        diff_days(date(
        extract_years(${opportunity.closed_quarter}),
        extract_months(${opportunity.closed_quarter})
          + floor(${opportunity.closed_day_of_quarter}/30),
        ${opportunity.closed_day_of_quarter}
          - floor(${opportunity.closed_day_of_quarter}/30)*30 + 1
          ), now()) < 0,
        null,
        running_total(${opportunity.total_acv_won})/${quota_aggregated.quota_sum})
      value_format_name: percent_1
    - table_calculation: goal
      label: Goal
      expression: if(is_null(pivot_index(${opportunity.total_acv_won}-${opportunity.total_acv_won},1)),1,1)
    hidden_fields: [opportunity.total_acv, running_acv, quota_pace, date, quota_aggregated.quota_sum,
      opportunity.total_acv_won]
    filters:
      opportunity.closed_quarter: 5 quarters
    sorts: [opportunity.closed_quarter desc, opportunity.closed_day_of_quarter]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: ''
    colors: [red, '#1ea8df', '#5245ed', '#706080', '#b3a0dd', '#a2dcf3', '', '#776fdf',
      '#635189', '']
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: false
    series_types:
      goal: area
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: false
    show_y_axis_ticks: true
    y_axis_tick_density: default
    y_axis_value_format: '#%'
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: auto
    y_axis_scale_mode: linear
    show_null_points: false
    point_style: none
    interpolation: monotone

  - name: pipeline_forecast
    title: Pipeline Forecast
    type: looker_column
    model: salesforce
    explore: opportunity
    dimensions: [opportunity.stage_name_funnel, opportunity.closed_month]
    pivots: [opportunity.stage_name_funnel]
    measures: [opportunity.total_acv]
    filters:
      opportunity.stage_name_funnel: -Lost,-Won
    sorts: [opportunity.stage_name_funnel desc, opportunity.closed_month, opportunity.stage_name_funnel__sort_]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: normal
    colors: ['#49cec1', '#1ea8df', '#e9b404', '#db7f2a', black, black, '#a2dcf3', '#776fdf',
      '#e9b404', '#635189']
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: true
    limit_displayed_rows: false
    y_axis_combined: true
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axis_labels: [Amount in Pipeline]
    y_axis_tick_density: default
    show_x_axis_label: false
    show_x_axis_ticks: true
    x_axis_scale: ordinal
    reference_lines: [{reference_type: line, range_start: max, range_end: min, margin_top: deviation,
        margin_value: mean, margin_bottom: deviation, line_value: '8333333', label: Avg Monthly ACV Goal (to Hit Quota)}]
    ordering: none
    show_null_labels: false
    show_totals_labels: false
    show_silhouette: false
    totals_color: '#808080'
    listen:
      quarter: opportunity.closed_quarter

  - name: pipeline_by_sales_rep
    title: Pipeline By Sales Rep
    type: looker_bar
    model: salesforce
    explore: opportunity
    dimensions: [opportunity.stage_name_funnel, salesrep.name]
    pivots: [opportunity.stage_name_funnel]
    measures: [opportunity.total_acv]
    dynamic_fields:
    - table_calculation: total_pipeline
      label: Total Pipeline
      expression: |-
        sum(pivot_row(${opportunity.total_acv}))

        # This field was created to be used to sort the chart. Another reasonable sort value would be the sum of won and winning deals:

        #coalesce(pivot_offset(${opportunity.total_acv}, 1), 0) + coalesce(pivot_offset(${opportunity.total_acv}, 2), 0)

        #The "coalesce" function is used above to ensure that null values are evaluated to 0 instead of null (which breaks the calculation)
      value_format_name: usd_0
    hidden_fields: [total_pipeline]
    filters:
      opportunity.stage_name_funnel: -Lost
      salesrep.name: -NULL
    sorts: [opportunity.stage_name_funnel desc, opportunity.stage_name_funnel__sort_,
      total_pipeline desc]
    limit: 500
    column_limit: 50
    query_timezone: America/Los_Angeles
    stacking: normal
    colors: ['#49cec1', '#49cec1', '#1ea8df', '#e9b404', '#db7f2a', black, black, '#a2dcf3',
      '#776fdf', '#e9b404', '#635189']
    show_value_labels: false
    label_density: 25
    legend_position: center
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_view_names: true
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
    listen:
      quarter: opportunity.closed_quarter

  - name: recent_deals
    title: Recent Deals
    type: table
    model: salesforce
    explore: opportunity
    dimensions: [account.name, opportunity.closed_date, opportunity.acv]
    filters:
      opportunity.is_won: 'Yes'
      salesrep.name: -NULL
    sorts: [opportunity.closed_date desc, opportunity.acv desc]
    limit: 15
    query_timezone: America/Los_Angeles
    show_view_names: true
    show_row_numbers: false
    truncate_column_names: false
    series_labels:
      account.name: Company
      salesrep.name: Rep
      opportunity.closed_date: Closed On
      opportunity.acv: ACV
    table_theme: gray
    limit_displayed_rows: false
    listen:
      quarter: opportunity.closed_quarter

  - name: likely_to_close
    title: Likely To Close
    type: table
    model: salesforce
    explore: opportunity
    dimensions: [account.name, opportunity.acv, opportunity.days_open]
    filters:
      opportunity.is_closed: 'No'
      opportunity.stage_name_funnel: Winning
      salesrep.name: -NULL
    sorts: [opportunity.acv desc, opportunity.days_open]
    limit: 15
    query_timezone: America/Los_Angeles
    show_view_names: true
    show_row_numbers: false
    truncate_column_names: false
    series_labels:
      account.name: Company
      salesrep.name: Rep
      opportunity.acv: ACV
      opportunity.days_open: Days Open
    table_theme: gray
    limit_displayed_rows: false
    listen:
      quarter: opportunity.closed_quarter

  - name: at_risk_deals
    title: At Risk Deals
    type: table
    model: salesforce
    explore: opportunity
    dimensions: [account.name, opportunity_zendesk_facts.health, salesrep.name]
    measures: [opportunity.total_acv, opportunity_zendesk_facts.total_days_open]
    filters:
      opportunity.is_closed: 'No'
      opportunity_zendesk_facts.health: <30
      salesrep.name: -NULL
      opportunity.total_acv: not 0
    sorts: [opportunity_zendesk_facts.health, salesrep.name desc]
    limit: 15
    query_timezone: America/Los_Angeles
    show_view_names: false
    show_row_numbers: false
    truncate_column_names: false
    series_labels:
      opportunity.total_acv: ACV
      zendesk_ticket.count_tickets_before_close: Tickets
      opportunity_zendesk_facts.total_days_open: Opp Age
      account.name: Company
      salesrep.name: Rep
    table_theme: gray
    limit_displayed_rows: false
    listen:
      quarter: opportunity.closed_quarter
