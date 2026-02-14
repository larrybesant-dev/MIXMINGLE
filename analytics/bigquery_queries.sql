-- ============================================================================
-- Mix & Mingle Analytics Queries for BigQuery
-- ============================================================================

-- QUERY 1: Weekly Active Users (WAU)
-- Returns count of unique users who engaged with the app in the last 7 days
-- ============================================================================
WITH weekly_users AS (
  SELECT
    COUNT(DISTINCT user_pseudo_id) as wau,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) as week_start
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE
    event_name = 'user_engagement'
    AND _TABLE_SUFFIX BETWEEN
      FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY week_start
)
SELECT
  week_start,
  wau,
  LAG(wau) OVER (ORDER BY week_start) as previous_wau,
  ROUND(((wau - LAG(wau) OVER (ORDER BY week_start)) / LAG(wau) OVER (ORDER BY week_start)) * 100, 2) as growth_rate_percent
FROM weekly_users
ORDER BY week_start DESC;


-- QUERY 2: Daily Active Users (DAU) and DAU/WAU Ratio
-- Returns daily active users and stickiness ratio
-- ============================================================================
WITH daily_stats AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) as date,
    COUNT(DISTINCT user_pseudo_id) as dau
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE
    event_name = 'user_engagement'
    AND _TABLE_SUFFIX BETWEEN
      FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY date
),
weekly_stats AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) as date,
    COUNT(DISTINCT user_pseudo_id) as wau
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE
    event_name = 'user_engagement'
    AND _TABLE_SUFFIX BETWEEN
      FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY date
)
SELECT
  d.date,
  d.dau,
  w.wau,
  ROUND((d.dau / w.wau) * 100, 2) as dau_wau_ratio_percent
FROM daily_stats d
LEFT JOIN weekly_stats w ON d.date = w.date
ORDER BY d.date DESC;


-- QUERY 3: User Retention Cohorts
-- Returns D1, D7, D30 retention by signup cohort
-- ============================================================================
WITH signups AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) as signup_date
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE event_name = 'sign_up'
  GROUP BY user_pseudo_id
),
activity AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) as activity_date
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE event_name = 'user_engagement'
)
SELECT
  s.signup_date as cohort,
  COUNT(DISTINCT s.user_pseudo_id) as total_users,
  COUNT(DISTINCT CASE
    WHEN DATE_DIFF(a.activity_date, s.signup_date, DAY) = 1
    THEN s.user_pseudo_id
  END) as d1_retained,
  ROUND(COUNT(DISTINCT CASE
    WHEN DATE_DIFF(a.activity_date, s.signup_date, DAY) = 1
    THEN s.user_pseudo_id
  END) / COUNT(DISTINCT s.user_pseudo_id) * 100, 2) as d1_retention_percent,
  COUNT(DISTINCT CASE
    WHEN DATE_DIFF(a.activity_date, s.signup_date, DAY) = 7
    THEN s.user_pseudo_id
  END) as d7_retained,
  ROUND(COUNT(DISTINCT CASE
    WHEN DATE_DIFF(a.activity_date, s.signup_date, DAY) = 7
    THEN s.user_pseudo_id
  END) / COUNT(DISTINCT s.user_pseudo_id) * 100, 2) as d7_retention_percent,
  COUNT(DISTINCT CASE
    WHEN DATE_DIFF(a.activity_date, s.signup_date, DAY) = 30
    THEN s.user_pseudo_id
  END) as d30_retained,
  ROUND(COUNT(DISTINCT CASE
    WHEN DATE_DIFF(a.activity_date, s.signup_date, DAY) = 30
    THEN s.user_pseudo_id
  END) / COUNT(DISTINCT s.user_pseudo_id) * 100, 2) as d30_retention_percent
FROM signups s
LEFT JOIN activity a ON s.user_pseudo_id = a.user_pseudo_id
WHERE s.signup_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)
GROUP BY s.signup_date
ORDER BY s.signup_date DESC;


-- QUERY 4: Event Funnel Analysis
-- Tracks user journey from event discovery to attendance
-- ============================================================================
WITH event_funnel AS (
  SELECT
    user_pseudo_id,
    MAX(CASE WHEN event_name = 'event_viewed' THEN 1 ELSE 0 END) as viewed,
    MAX(CASE WHEN event_name = 'event_rsvp' THEN 1 ELSE 0 END) as rsvp,
    MAX(CASE WHEN event_name = 'event_attended' THEN 1 ELSE 0 END) as attended
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN
      FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY user_pseudo_id
)
SELECT
  COUNT(DISTINCT CASE WHEN viewed = 1 THEN user_pseudo_id END) as viewed_events,
  COUNT(DISTINCT CASE WHEN rsvp = 1 THEN user_pseudo_id END) as rsvp_events,
  COUNT(DISTINCT CASE WHEN attended = 1 THEN user_pseudo_id END) as attended_events,
  ROUND(COUNT(DISTINCT CASE WHEN rsvp = 1 THEN user_pseudo_id END) /
    COUNT(DISTINCT CASE WHEN viewed = 1 THEN user_pseudo_id END) * 100, 2) as view_to_rsvp_percent,
  ROUND(COUNT(DISTINCT CASE WHEN attended = 1 THEN user_pseudo_id END) /
    COUNT(DISTINCT CASE WHEN rsvp = 1 THEN user_pseudo_id END) * 100, 2) as rsvp_to_attendance_percent
FROM event_funnel;


-- QUERY 5: Room Engagement Metrics
-- Tracks room joins and duration
-- ============================================================================
WITH room_sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'room_id') as room_id,
    TIMESTAMP_MICROS(event_timestamp) as join_time,
    LEAD(TIMESTAMP_MICROS(event_timestamp)) OVER (
      PARTITION BY user_pseudo_id
      ORDER BY event_timestamp
    ) as leave_time
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE
    event_name = 'room_joined'
    AND _TABLE_SUFFIX BETWEEN
      FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
)
SELECT
  COUNT(DISTINCT user_pseudo_id) as total_room_joiners,
  COUNT(*) as total_room_joins,
  ROUND(AVG(TIMESTAMP_DIFF(leave_time, join_time, SECOND)) / 60, 2) as avg_session_minutes,
  COUNT(DISTINCT room_id) as unique_rooms_joined
FROM room_sessions
WHERE leave_time IS NOT NULL;


-- QUERY 6: Power User Identification
-- Identifies users with high engagement across multiple features
-- ============================================================================
WITH user_activity AS (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT CASE WHEN event_name = 'room_joined' THEN
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'room_id')
    END) as rooms_joined,
    COUNT(DISTINCT CASE WHEN event_name = 'event_attended' THEN
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'event_id')
    END) as events_attended,
    COUNT(DISTINCT CASE WHEN event_name = 'message_sent' THEN 1 END) as messages_sent,
    COUNT(DISTINCT CASE WHEN event_name = 'speed_dating_match' THEN 1 END) as matches_made
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN
      FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY user_pseudo_id
)
SELECT
  user_pseudo_id,
  rooms_joined,
  events_attended,
  messages_sent,
  matches_made,
  CASE
    WHEN (rooms_joined >= 5 OR events_attended >= 3 OR messages_sent >= 15) THEN 'Power User'
    WHEN (rooms_joined >= 2 OR events_attended >= 1 OR messages_sent >= 5) THEN 'Active User'
    ELSE 'Casual User'
  END as user_segment
FROM user_activity
WHERE rooms_joined > 0 OR events_attended > 0 OR messages_sent > 0
ORDER BY
  (rooms_joined + events_attended + (messages_sent / 5)) DESC
LIMIT 100;


-- QUERY 7: Revenue and Monetization Metrics
-- Tracks premium subscriptions and event revenue
-- ============================================================================
WITH revenue_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    (SELECT value.double_value FROM UNNEST(event_params) WHERE key = 'value') as revenue_amount,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'currency') as currency,
    PARSE_DATE('%Y%m%d', event_date) as transaction_date
  FROM `mixmingle-prod.analytics_*.events_*`
  WHERE
    event_name IN ('premium_purchase', 'event_ticket_purchase', 'event_boost_purchase')
    AND _TABLE_SUFFIX BETWEEN
      FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
)
SELECT
  transaction_date,
  COUNT(DISTINCT user_pseudo_id) as paying_users,
  COUNT(*) as total_transactions,
  ROUND(SUM(revenue_amount), 2) as total_revenue,
  ROUND(AVG(revenue_amount), 2) as avg_transaction_value,
  COUNT(DISTINCT CASE WHEN event_name = 'premium_purchase' THEN user_pseudo_id END) as premium_subscribers
FROM revenue_events
GROUP BY transaction_date
ORDER BY transaction_date DESC;
