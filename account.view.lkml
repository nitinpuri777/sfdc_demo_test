view: account {
  derived_table: {
    sql: SELECT *
        , MD5(TRIM(BOTH ' ' FROM REGEXP_REPLACE(LOWER(name), '([[:space:]]|\\,)+([iInNcC]|[lLcC]).*$', ''))) AS company_id
      FROM public.account
       ;;
    sql_trigger_value: SELECT COUNT(*) FROM account ;;
    # using indexes for interleaved sort keys
    indexes: ["created_at", "company_id"]
    distribution: "company_id"
  }

  # DIMENSIONS #

  dimension: id {
    primary_key: yes
    sql: ${TABLE}.id ;;

    link: {
      label: "Salesforce Account"
      url: "https://blog.internetcreations.com/wp-content/uploads/2012/09/Business-Account_-Internet-Creations-salesforce.com-Enterprise-Edition-1.jpg"
      icon_url: "http://www.salesforce.com/favicon.ico"
    }
  }

  dimension: company_id {
    hidden: yes
    sql: ${TABLE}.company_id ;;
  }

  dimension: account_status {
    sql: COALESCE(${TABLE}.account_status_c, 'Unknown') ;;
  }

  dimension: account_tier {
    type: string
    sql: CASE
        WHEN ${salesrep.business_segment} = 'Enterprise' THEN 'Gold'
        WHEN ${salesrep.business_segment} = 'Mid-Market' THEN 'Silver'
        ELSE 'Bronze'
      END
       ;;
    html: {% if rendered_value == 'Bronze' %}
        <div style="color: #f6f8fa; text-align:center; border:1px solid #e6e6e6; background-color: #cd7f32; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif rendered_value == 'Silver' %}
        <div style="color: #f6f8fa; text-align:center; border:1px solid #e6e6e6; background-color: silver; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% elsif rendered_value == 'Gold' %}
        <div style="color: #f6f8fa; text-align:center; border:1px solid #e6e6e6; background-color: gold; font-size: 100%; text-align:center">{{ rendered_value }}</div>
      {% else %}
        {{ rendered_value }}
      {% endif %}
      ;;
  }

  dimension: campaign {
    hidden: yes
    sql: ${TABLE}.campaign2_c ;;
  }

  dimension: city {
    sql: ${TABLE}.city ;;
  }

  dimension: country {
    drill_fields: [city, state]
    map_layer_name: countries
    sql: ${TABLE}.country ;;
  }

  dimension_group: created {
    type: time
    timeframes: [time, date, week, month, year]
    sql: ${TABLE}.created_at ;;
  }

  dimension: current_customer {
    type: yesno
    sql: ${TABLE}.current_customer_c ;;
  }

  #   - dimension_group: customer_end
  #     type: time
  #     timeframes: [date, week, month]
  #     convert_tz: false
  #     sql: ${TABLE}.customer_end_date_c

  dimension: customer_reference {
    type: yesno
    sql: ${TABLE}.customer_reference_c ;;
  }

  dimension_group: customer_start {
    type: time
    timeframes: [raw, time, date, week, month, year]
    convert_tz: no
    sql: ${TABLE}.customer_start_date_c ;;
  }

  dimension: days_to_contract_renewal {
    type: number
    sql: CASE
        WHEN DATEDIFF(day, ${customer_start_raw}, CURRENT_DATE) < 0 THEN DATEDIFF(day, ${customer_start_raw}, CURRENT_DATE)
        ELSE 365 - (DATEDIFF(day, ${customer_start_raw}, CURRENT_DATE) % 365)
      END
       ;;
  }

  dimension: engagement_stage {
    case: {
      when: {
        sql: ${current_customer} = 'Yes' ;;
        label: "Customer"
      }

      when: {
        sql: ${current_customer} = 'No' AND ${TABLE}.engagement_stage_c IS NOT NULL ;;
        label: "Engaged"
      }

      else: "Prospecting"
    }
  }

  dimension: is_active_customer {
    type: yesno
    sql: ${current_customer} AND ${account_status} NOT IN ('Unknown', 'Black (Discontinued)') ;;
  }

  #used for filter suggestions on customer lookup dashboard to only show active customers
  dimension: active_customer_name {
    type: string
    sql: CASE
        WHEN ${is_active_customer} = 'YES' THEN ${name}
        ELSE NULL
      END
       ;;
  }

  dimension: name {
    sql: ${TABLE}.name ;;

    link: {
      label: "Customer Lookup Dashboard"
      url: "http://demonew.looker.com/dashboards/279?Account%20Name={{ value  }}"
      icon_url: "http://www.looker.com/favicon.ico"
    }

    link: {
      label: "Salesforce Account"
      url: "https://blog.internetcreations.com/wp-content/uploads/2012/09/Business-Account_-Internet-Creations-salesforce.com-Enterprise-Edition-1.jpg"
      icon_url: "http://www.salesforce.com/favicon.ico"
    }

    action: {
      label: "Send License Upgrade Email"
      url: "https://desolate-refuge-53336.herokuapp.com/posts"
      icon_url: "https://sendgrid.com/favicon.ico"
      form_param: {
        name: "Subject"
        type: string
        required:  yes
        default: "Upgrade Your Looker to the Latest Version!"
      }
      form_param: {
        name: "Body"
        type: textarea
        required: yes
        default:
        "Hey Team,

        I saw that you haven’t upgraded to the newest version yet. Anything I can do to help?

        Thanks,
        Dillon Morrison
        Manager | Customer Success
        Dillon@looker.com"
      }
      form_param: {
        name: "Send Me a Copy"
        type: select
        default: "yes"
        option: {
          name: "yes"
          label: "yes"
        }
      }
    }

      action: {
        label: "Send Zendesk Followup Email"
        url: "https://desolate-refuge-53336.herokuapp.com/posts"
        icon_url: "https://sendgrid.com/favicon.ico"
        form_param: {
          name: "Subject"
          type: string
          required:  yes
          default: "Following Up on Your Chat Support Conversation"
        }
        form_param: {
          name: "Body"
          type: textarea
          required: yes
          default:
          "Hey Team,

          I saw that you reached out to our support team. Is there anything I can do to help?

          Thanks,
          Dillon Morrison
          Manager | Customer Success
          Dillon@looker.com"
        }
        form_param: {
          name: "Send Me a Copy"
          type: select
          default: "yes"
          option: {
            name: "yes"
            label: "yes"
          }
        }
      }
    action: {
      label: "Update Git Repo"
      url: "https://desolate-refuge-53336.herokuapp.com/posts"
      icon_url: "https://sendgrid.com/favicon.ico"
      form_param: {
        name: "Subject"
        type: string
        required: yes
        default: "Time to Switch Your Git Repo"
      }
      form_param: {
        name: "Body"
        type: textarea
        required: yes
        default:
        "Hey Team,

        I saw that you haven’t switched out the default repo to your own yet. Anything I can do to help?

        Thanks,
        Dillon Morrison
        Manager | Customer Success
        Dillon@looker.com"
      }
    }
  }

  dimension: number_of_employees {
    type: number
    sql: ${TABLE}.number_of_employees ;;
  }

  dimension: owner_id {
    hidden: yes
    sql: ${TABLE}.owner_id ;;
  }

  dimension: state {
    drill_fields: [city]
    map_layer_name: us_states
    sql: ${TABLE}.state ;;
  }

  # We should consider removing this, unless we really want to build something around partnerships
  dimension: type {
    # default the type to customer
    sql: NVL(${TABLE}.type,'Customer') ;;
  }

  dimension: url {
    sql: ${TABLE}.url ;;

    link: {
      label: "Website"
      url: "{{ value }}"
      icon_url: "http://www.google.com/s2/favicons?domain_url={{ value | encode_uri }}"
    }
  }

  dimension: vertical {
    type: string
    sql: COALESCE(COALESCE(${TABLE}.vertical_c, ${TABLE}.market_segment_c), 'Unknown') ;;
  }

  dimension: vertical_segment {
    type: string
    sql: CASE
        WHEN ${vertical} = 'Retail, eCommerce & Marketplaces' THEN 'Retail'
        WHEN ${vertical} = 'Technology' THEN 'Technology'
        WHEN ${vertical} = 'Software & SaaS' THEN 'Software'
        WHEN ${vertical} = 'Ad Tech & Online Media' THEN 'Digital'
        WHEN ${vertical} = 'Finance & Payments' THEN 'Finance'
        WHEN ${vertical} = 'Non-profit & Education' THEN 'Non-Profit'
        WHEN ${vertical} = 'Mobile & Gaming' THEN 'Mobile'
        WHEN ${vertical} = 'Health' THEN 'Health'
        WHEN ${vertical} = 'Enterprise' THEN 'Enterprise'
        WHEN ${vertical} = 'Agency' THEN 'Agency'
        ELSE ${vertical}
      END
       ;;
  }

  dimension: zendesk_organization {
    hidden: yes
    sql: ${TABLE}.zendesk_organization ;;
  }

  dimension: number_of_employees_tier {
    type: tier
    tiers: [0, 10, 50, 100, 500, 1000, 10000]
    sql: ${number_of_employees} ;;
  }

  dimension: contact_email {
    sql: concat('example@', ${name}, '.com') ;;
  }

  dimension: reminder_email {
    sql: ${account.name} ;;
    html: <a href="mailto:{{ account.contact_email._value }}?subject=Looker and {{account.name._value}} Outstanding Invoices&cc=renee@looker.com&body=Hi Example,%0D%0DI was hoping you might be able to help us track down outstanding Looker invoice #6341, which was sent to example@example.com in the amount of $4,000 and is currently 27 days past due.%0D%0DPlease let us know if there is a different contact we should be reaching out to regarding invoices or if you have a grasp on the plan for payment.%0D%0DYour help is very much appreciated!%0D%0DRegards,%0DSteve" target="_blank">
        <img src="https://upload.wikimedia.org/wikipedia/commons/4/4e/Gmail_Icon.png" width="16" height="16" />
      </a>
      {{ linked_value }}
      ;;
  }

  # MEASURES #

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  measure: percent_of_accounts {
    type: percent_of_total
    sql: ${count} ;;
    drill_fields: [detail*]
  }

  measure: total_number_of_employees {
    type: sum
    sql: ${number_of_employees} ;;
    drill_fields: [detail*]
  }

  measure: average_number_of_employees {
    type: average
    sql: ${number_of_employees} ;;
    drill_fields: [detail*]
  }

  # SETS #

  set: detail {
    fields: [id, name, account_status, account_tier, city, state, number_of_employees_tier]
  }

  set: export_set {
    fields: [id, company_id, account_status, account_tier, city, created_time, created_date, created_week, created_month, current_customer, customer_start_time, customer_start_date, customer_start_week, customer_start_month, engagement_stage, name, number_of_employees, state, type, url, vertical, zendesk_organization, number_of_employees_tier, count, percent_of_accounts, total_number_of_employees, average_number_of_employees, owner_id, days_to_contract_renewal, reminder_email, active_customer_name]
  }
}
