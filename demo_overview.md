# Salesforce Demo



**Overview**

 <i>Cloudly</i>  is the fictitious SaaS company used for this Salesforce demo. The demo primarily demonstrates the combination of disparate data into a consolidated database. The different data sources are Salesforce data, application data, and support (ticket) data. 

**Demo Flow**

1. [Executive Summary Dashboard](https://demo.looker.com/dashboards/381)
- This dashboard is intended for a sales executive who wants to get a better understanding of how the different sales segments are performing. To further inspect a particular sales segment, click on the desired segment's sparkline at the bottom of the dashboard in the "Sales Segment Performance" look. 

2. [Sales Segment Dashboard](https://demo.looker.com/dashboards/526)
- The sales segment db is where we can demonstrate the utility of having different datasets combined into a single database. The "Customer by License Health" look uses Salesforce, application, and ticket data to determine the health of a license/account. Click on the sparkline next to a salesrep's name to be taken to the salesrep db.

3. [Salesrep Dashboard](https://demo.looker.com/dashboards/463)
- Demonstrate complex/highly customized analytics like comparing a salesrep to the rest of sales segement.
- Click opportunity id to show the ability to link to external web applications.
- The opportunity health metric indicates the likelihood an open opportunity has to become a win. This metric is based on historical data from Salesforce, appliation, and ticket data.  
- Drill down to granular data.

**Pitfalls**

- When demonstrating LookML, be conscientious that many of the view files are complex PDTs and may intimidate prospective clients. 

**Definitions**

- **Campaign:** A Salesforce campaign is an outbound marketing project that you want to plan, manage, and track within Salesforce. It can be a direct mail program, seminar, print advertisement, email, or other type of marketing initiative. Leads are generated through campaigns.
- **Lead:** A Salesforce lead is a prospect which needs to be qualified as a real sales opportunity. Once the lead has been qualified, the lead record is converted to a contact and an account.
- **Task:** A Salesforce task is basically an action or event. Tasks in the Salesforce demo data are referring to meetings. So, a meeting is a task where the action/event is referring to a meeting between a lead and a <i>Cloudly</i>  salesrep.
- **Contact:** A Salesforce contact contains personal information about the lead and is created once a lead has been qualified.
- **Account:** A Salesforce account has company details and is created once a lead has been qualified. 
- **Opportunity:** A Salesforce opportunity includes sales information. An account may have many opportunities.
- **ACV:** ACV is a SaaS metric referring to Annual Contract Value.
- **MRR:** MRR is also a SaaS metric which stands for Monthly Recurring Revenue. Click [here](http://www.insidesales.com/insider/execution/how-saas-metrics-can-help-you-drive-explosive-growth-like-salesforce-com/) for a more in-depth discussion of common SaaS metrics.
- **First vs Last Touch Attribution:** Click [here](http://www.thatagency.com/design-studio-blog/2013/08/first-touch-vs-last-touch-conversion-attribution/) for an explanation. This salesforce demo uses first touch attribution for its conversion funnel.












