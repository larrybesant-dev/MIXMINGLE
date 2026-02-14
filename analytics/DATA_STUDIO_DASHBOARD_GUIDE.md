# Mix & Mingle Data Studio Dashboard Setup Guide

## Quick Start: Create Your Dashboard in 5 Minutes

### Step 1: Open Data Studio
Go to: **https://datastudio.google.com**

Click: **Create** → **Report**

---

### Step 2: Connect BigQuery Data Source

1. Click **"Add data"**
2. Select **"BigQuery"**
3. Choose **"Custom Query"**
4. Project: `mixmingle-prod`
5. Paste this query:

```sql
SELECT
  PARSE_DATE('%Y%m%d', event_date) as date,
  event_name,
  platform,
  geo.country as country,
  COUNT(DISTINCT user_pseudo_id) as users,
  COUNT(*) as events,
  COUNT(DISTINCT CASE WHEN event_name = 'sign_up' THEN user_pseudo_id END) as signups,
  COUNT(DISTINCT CASE WHEN event_name = 'room_joined' THEN user_pseudo_id END) as room_users,
  COUNT(DISTINCT CASE WHEN event_name = 'event_rsvp' THEN user_pseudo_id END) as event_users
FROM `mixmingle-prod.analytics_*.events_*`
WHERE _TABLE_SUFFIX BETWEEN @DS_START_DATE AND @DS_END_DATE
GROUP BY date, event_name, platform, country
```

6. Click **"Add"**
7. Name it: **"Mix & Mingle Analytics"**

---

### Step 3: Build Dashboard Layout

Your dashboard should have **5 panels**:

---

## PANEL 1: North Star Metric (Top Banner)

**Position**: Top, full width
**Height**: 150px

### Scorecard 1: Weekly Active Users (WAU)
- **Chart Type**: Scorecard
- **Metric**: `users` (SUM)
- **Date Range**: Last 7 days
- **Style**:
  - Font size: 48pt
  - Color: #6366F1 (indigo)
  - Label: "Weekly Active Users"

### Scorecard 2: Daily Active Users (DAU)
- **Chart Type**: Scorecard
- **Metric**: `users` (SUM)
- **Date Range**: Today
- **Style**:
  - Font size: 48pt
  - Color: #10B981 (green)
  - Label: "Daily Active Users"

### Scorecard 3: DAU/WAU Ratio
- **Chart Type**: Calculated Field
- **Formula**: `SUM(users_today) / SUM(users_last_7_days)`
- **Display**: Percentage
- **Style**:
  - Font size: 48pt
  - Color: #F59E0B (amber)
  - Label: "Stickiness (DAU/WAU)"

---

## PANEL 2: Growth Trends (Left Side)

**Position**: Top-left, 50% width
**Height**: 400px

### Time Series Chart: User Growth
- **Chart Type**: Time series (line chart)
- **Dimension**: `date`
- **Metrics**:
  - `users` (blue line)
  - `signups` (green line)
- **Date Range**: Last 30 days
- **Style**:
  - Smooth lines
  - Show data labels
  - Legend: bottom

### Goal Line (Optional):
- Add comparison period: Previous 30 days
- Show trend line

---

## PANEL 3: Engagement Metrics (Right Side)

**Position**: Top-right, 50% width
**Height**: 400px

### Scorecard Grid (2x2):

**Card 1: Rooms**
- Metric: `room_users` (COUNT DISTINCT)
- Label: "Users in Rooms Today"
- Icon: 🎙️

**Card 2: Events**
- Metric: `event_users` (COUNT DISTINCT)
- Label: "Event RSVPs Today"
- Icon: 📅

**Card 3: Session Duration**
- Metric: Custom (from Firebase)
- Label: "Avg Session (minutes)"
- Icon: ⏱️

**Card 4: Crash-Free Rate**
- Metric: Custom (from Crashlytics)
- Label: "Crash-Free Rate"
- Icon: ✅

---

## PANEL 4: Platform & Geography (Middle)

**Position**: Middle, full width
**Height**: 300px

### Chart 1: Platform Distribution (Pie Chart)
- **Dimension**: `platform`
- **Metric**: `users`
- **Style**:
  - Donut chart
  - Show percentages
  - Colors: iOS (blue), Android (green), Web (purple)

### Chart 2: Top Countries (Bar Chart)
- **Dimension**: `country`
- **Metric**: `users`
- **Sort**: Descending
- **Limit**: Top 10
- **Style**: Horizontal bars

---

## PANEL 5: Event Funnel (Bottom)

**Position**: Bottom, full width
**Height**: 250px

### Table: Event Breakdown
- **Dimension**: `event_name`
- **Metrics**:
  - `events` (total count)
  - `users` (unique users)
  - Calculated: `events/users` (events per user)
- **Sort**: By `events` DESC
- **Limit**: Top 20
- **Style**:
  - Heatmap formatting (green = high, red = low)
  - Compact view

---

## Step 4: Add Filters (Sidebar)

Add these filters to your dashboard:

### Filter 1: Date Range
- **Type**: Date range control
- **Default**: Last 7 days
- **Position**: Top of page

### Filter 2: Platform
- **Type**: Drop-down list
- **Dimension**: `platform`
- **Options**: All, iOS, Android, Web
- **Default**: All

### Filter 3: Country
- **Type**: Drop-down list with search
- **Dimension**: `country`
- **Default**: All

---

## Step 5: Set Up Auto-Refresh

1. Click **"Resource"** → **"Manage added data sources"**
2. Select your BigQuery data source
3. Set **"Data freshness"**: **1 hour**
4. Enable **"Enable cache"**
5. Click **"Update"**

---

## Step 6: Share Dashboard

1. Click **"Share"** (top-right)
2. Add team members:
   - **Larry (you)**: Owner
   - **Co-founders**: Can edit
   - **Team**: Can view
3. Copy shareable link
4. Pin link in Slack #launch-metrics channel

---

## Custom Calculated Fields

### Field 1: Activation Rate
```
COUNT_DISTINCT(CASE WHEN event_name IN ('room_joined', 'event_rsvp') THEN user_pseudo_id END)
/ COUNT_DISTINCT(CASE WHEN event_name = 'sign_up' THEN user_pseudo_id END)
```

### Field 2: Events Per User
```
COUNT(events) / COUNT_DISTINCT(users)
```

### Field 3: Premium Conversion Rate
```
COUNT_DISTINCT(CASE WHEN event_name = 'premium_purchase' THEN user_pseudo_id END)
/ COUNT_DISTINCT(users)
```

---

## Advanced: Add Retention Cohort Chart

### Custom Query for Cohort Analysis:
```sql
WITH signups AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) as cohort_date
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE event_name = 'sign_up'
    AND _TABLE_SUFFIX BETWEEN @DS_START_DATE AND @DS_END_DATE
  GROUP BY user_pseudo_id
),
activity AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) as activity_date
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @DS_START_DATE AND @DS_END_DATE
)
SELECT
  s.cohort_date,
  DATE_DIFF(a.activity_date, s.cohort_date, DAY) as days_since_signup,
  COUNT(DISTINCT s.user_pseudo_id) as retained_users
FROM signups s
JOIN activity a ON s.user_pseudo_id = a.user_pseudo_id
GROUP BY s.cohort_date, days_since_signup
ORDER BY s.cohort_date, days_since_signup
```

**Chart Type**: Heatmap
- **Rows**: `cohort_date`
- **Columns**: `days_since_signup`
- **Metric**: `retained_users`
- **Color**: Green (high) to Red (low)

---

## Mobile-Friendly Dashboard

Create a second dashboard optimized for mobile:

### Layout:
- **Single column** (no side-by-side charts)
- **Scorecards only** (4 key metrics)
- **Simplified charts** (no tables)

### Key Metrics for Mobile:
1. WAU
2. DAU
3. Signups Today
4. Crash-Free Rate

---

## Alerting Setup

Data Studio doesn't have native alerting, but you can:

1. **Schedule email reports**:
   - File → Schedule email delivery
   - Daily at 9 AM
   - Recipients: Larry, co-founders

2. **Set up Slack alerts** (via Cloud Functions):
   - See: `functions/src/analyticsAlerts.ts`
   - Triggers on thresholds (crash rate, signup drop)

---

## Dashboard URL (After Creation)

Save your dashboard URL and share it:

**Internal Link**: https://datastudio.google.com/reporting/[YOUR_REPORT_ID]
**Public Link** (if you want to share externally): Enable "Anyone with link can view"

---

## Troubleshooting

### Issue 1: "No data available"
**Solution**:
- Check BigQuery export is linked (see setup_bigquery.ps1)
- Wait 24-48 hours for data to populate
- Verify date range includes recent dates

### Issue 2: "Query exceeds quota"
**Solution**:
- Reduce date range in query
- Add `LIMIT 10000` to custom queries
- Enable data caching (Resource → Data freshness)

### Issue 3: Slow dashboard loading
**Solution**:
- Use date range controls (don't query all-time data)
- Pre-aggregate data in BigQuery views
- Enable "Use cache" on all charts

---

## Next Steps

After creating your dashboard:

1. ✅ Bookmark dashboard URL
2. ✅ Share with team
3. ✅ Set up daily email reports
4. ✅ Create mobile-friendly version
5. ✅ Build cohort retention heatmap
6. ✅ Integrate with Slack (Cloud Functions)

---

## Example Dashboard Screenshot

Your final dashboard should look like this:

```
┌────────────────────────────────────────────────────────────┐
│  [Filter: Last 7 days ▼]  [Platform: All ▼]  [Country ▼]  │
└────────────────────────────────────────────────────────────┘

┌──────────────┬──────────────┬──────────────────────────────┐
│ WAU: 1,247   │ DAU: 423     │ DAU/WAU: 34%                 │
└──────────────┴──────────────┴──────────────────────────────┘

┌─────────────────────────────┬─────────────────────────────┐
│ [User Growth Line Chart]    │ [Engagement Scorecards]     │
│                             │  Rooms: 147 users           │
│                             │  Events: 89 RSVPs           │
└─────────────────────────────┴─────────────────────────────┘

┌─────────────────────────────┬─────────────────────────────┐
│ [Platform Pie Chart]        │ [Top Countries Bar Chart]   │
└─────────────────────────────┴─────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ [Event Breakdown Table]                                    │
│ room_joined    1,234 events    567 users    2.2 per user  │
│ event_rsvp       892 events    423 users    2.1 per user  │
└────────────────────────────────────────────────────────────┘
```

---

## Cost: $0

Data Studio is **100% free** for unlimited dashboards and viewers.

BigQuery costs apply only to data storage and queries (covered by free tier for first few months).

---

## Support

- Data Studio Help: https://support.google.com/datastudio
- BigQuery Docs: https://cloud.google.com/bigquery/docs
- Mix & Mingle Analytics Guide: This file
