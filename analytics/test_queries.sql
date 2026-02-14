-- ============================================================================
-- Mix & Mingle BigQuery Test Query Pack
-- Run these queries to verify your BigQuery export is working
-- ============================================================================

-- TEST 1: Basic Connection Test
-- Returns row count from all analytics tables
-- Expected: Number > 0 (if data is flowing)
-- ============================================================================
SELECT
  COUNT(*) as total_events
FROM `mixmingle-prod.analytics_*.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY));

-- If this returns 0, BigQuery export may not be configured yet or data hasn't populated
-- Wait 24-48 hours after linking Firebase → BigQuery


-- TEST 2: Event Distribution (Last 7 Days)
-- Shows which events are being tracked
-- Expected: See sign_up, user_engagement, room_joined, event_rsvp, etc.
-- ============================================================================
SELECT
  event_name,
  COUNT(*) as event_count,
  COUNT(DISTINCT user_pseudo_id) as unique_users
FROM `mixmingle-prod.analytics_*.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
GROUP BY event_name
ORDER BY event_count DESC
LIMIT 20;


-- TEST 3: Daily Active Users (Last 30 Days)
-- Verifies user engagement tracking
-- Expected: Growing trend line
-- ============================================================================
SELECT
  PARSE_DATE('%Y%m%d', event_date) as date,
  COUNT(DISTINCT user_pseudo_id) as dau
FROM `mixmingle-prod.analytics_*.events_*`
WHERE
  event_name = 'user_engagement'
  AND _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
GROUP BY date
ORDER BY date DESC;


-- TEST 4: Platform Distribution
-- Shows iOS vs Android vs Web usage
-- Expected: Split across platforms
-- ============================================================================
SELECT
  platform,
  COUNT(DISTINCT user_pseudo_id) as users,
  COUNT(*) as events
FROM `mixmingle-prod.analytics_*.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
GROUP BY platform
ORDER BY users DESC;


-- TEST 5: User Retention Check
-- Verifies signup tracking and subsequent activity
-- Expected: See users who signed up and returned
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
  s.signup_date,
  COUNT(DISTINCT s.user_pseudo_id) as signups,
  COUNT(DISTINCT CASE
    WHEN DATE_DIFF(a.activity_date, s.signup_date, DAY) = 1
    THEN s.user_pseudo_id
  END) as d1_retained
FROM signups s
LEFT JOIN activity a ON s.user_pseudo_id = a.user_pseudo_id
WHERE s.signup_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY s.signup_date
ORDER BY s.signup_date DESC
LIMIT 30;


-- TEST 6: Custom Events Verification
-- Checks if Mix & Mingle custom events are flowing
-- Expected: See room_joined, event_rsvp, speed_dating_match, etc.
-- ============================================================================
SELECT
  event_name,
  COUNT(*) as count,
  MIN(TIMESTAMP_MICROS(event_timestamp)) as first_seen,
  MAX(TIMESTAMP_MICROS(event_timestamp)) as last_seen
FROM `mixmingle-prod.analytics_*.events_*`
WHERE
  event_name IN (
    'room_joined',
    'room_left',
    'event_rsvp',
    'event_attended',
    'speed_dating_match',
    'message_sent',
    'premium_purchase'
  )
  AND _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
GROUP BY event_name
ORDER BY count DESC;


-- TEST 7: Event Parameters Check
-- Verifies custom parameters are being captured
-- Expected: See room_id, event_id, match_id in parameters
-- ============================================================================
SELECT
  event_name,
  param.key as parameter_key,
  COUNT(*) as occurrence_count
FROM `mixmingle-prod.analytics_*.events_*`,
UNNEST(event_params) as param
WHERE
  event_name IN ('room_joined', 'event_rsvp', 'speed_dating_match')
  AND _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
GROUP BY event_name, param.key
ORDER BY event_name, occurrence_count DESC;


-- TEST 8: User Property Verification
-- Checks if user properties are being set correctly
-- Expected: See user_id, premium_status, referral_code, etc.
-- ============================================================================
SELECT
  user_properties.key as property_name,
  COUNT(DISTINCT user_pseudo_id) as users_with_property,
  COUNT(*) as total_occurrences
FROM `mixmingle-prod.analytics_*.events_*`,
UNNEST(user_properties) as user_properties
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
GROUP BY property_name
ORDER BY users_with_property DESC;


-- TEST 9: Geographic Distribution
-- Shows where your users are located
-- Expected: See country distribution
-- ============================================================================
SELECT
  geo.country,
  geo.city,
  COUNT(DISTINCT user_pseudo_id) as users,
  COUNT(*) as events
FROM `mixmingle-prod.analytics_*.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
GROUP BY geo.country, geo.city
HAVING users >= 5
ORDER BY users DESC
LIMIT 50;


-- TEST 10: Traffic Source Analysis
-- Shows how users are finding your app
-- Expected: See organic, referral, campaign sources
-- ============================================================================
SELECT
  traffic_source.source,
  traffic_source.medium,
  traffic_source.campaign,
  COUNT(DISTINCT user_pseudo_id) as users,
  COUNT(DISTINCT CASE WHEN event_name = 'sign_up' THEN user_pseudo_id END) as signups
FROM `mixmingle-prod.analytics_*.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
GROUP BY traffic_source.source, traffic_source.medium, traffic_source.campaign
ORDER BY users DESC
LIMIT 20;


-- ============================================================================
-- TROUBLESHOOTING QUERIES
-- ============================================================================

-- TROUBLESHOOT 1: Check Table List
-- Lists all analytics tables in your dataset
-- ============================================================================
SELECT
  table_name,
  PARSE_DATE('%Y%m%d', REGEXP_EXTRACT(table_name, r'events_(\d{8})')) as date,
  size_bytes / 1024 / 1024 as size_mb,
  row_count
FROM `mixmingle-prod.analytics_*.__TABLES__`
ORDER BY table_name DESC
LIMIT 30;


-- TROUBLESHOOT 2: Check Data Freshness
-- Shows the most recent event timestamp
-- Expected: Within last few hours (if app is active)
-- ============================================================================
SELECT
  MAX(TIMESTAMP_MICROS(event_timestamp)) as latest_event,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(TIMESTAMP_MICROS(event_timestamp)), HOUR) as hours_ago
FROM `mixmingle-prod.analytics_*.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', CURRENT_DATE());


-- TROUBLESHOOT 3: Check for Duplicate Events
-- Identifies potential data quality issues
-- Expected: Low duplication rate (<1%)
-- ============================================================================
SELECT
  event_name,
  COUNT(*) as total_events,
  COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(event_timestamp AS STRING))) as unique_events,
  ROUND((1 - COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(event_timestamp AS STRING))) / COUNT(*)) * 100, 2) as duplication_rate_percent
FROM `mixmingle-prod.analytics_*.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
GROUP BY event_name
HAVING total_events > 100
ORDER BY duplication_rate_percent DESC;


-- ============================================================================
-- HOW TO RUN THESE QUERIES
-- ============================================================================

-- Option 1: BigQuery Console (Web UI)
-- 1. Go to: https://console.cloud.google.com/bigquery?project=mixmingle-prod
-- 2. Click "Compose New Query"
-- 3. Copy/paste any query above
-- 4. Click "Run"

-- Option 2: Command Line (bq tool)
-- bq query --project_id=mixmingle-prod --use_legacy_sql=false "
-- SELECT COUNT(*) FROM \`mixmingle-prod.analytics_*.events_*\`
-- "

-- Option 3: PowerShell Script
-- $query = "SELECT COUNT(*) FROM \`mixmingle-prod.analytics_*.events_*\`"
-- bq query --project_id=mixmingle-prod --use_legacy_sql=false $query

-- ============================================================================
-- EXPECTED RESULTS IF EVERYTHING IS WORKING
-- ============================================================================

-- TEST 1: total_events > 0
-- TEST 2: 10-20 different event types
-- TEST 3: Daily trend showing growth or stable usage
-- TEST 4: Platform split (iOS, Android, Web)
-- TEST 5: Retention data showing D1 return rate
-- TEST 6: Custom events like room_joined, event_rsvp
-- TEST 7: Event parameters like room_id, event_id
-- TEST 8: User properties set correctly
-- TEST 9: Geographic distribution matching your users
-- TEST 10: Traffic sources showing acquisition channels

-- If any test returns 0 rows or errors:
-- - BigQuery export may not be linked yet
-- - Wait 24-48 hours after linking
-- - Check Firebase Console → Analytics → Events to verify data is being collected
-- - Verify project ID is correct: mixmingle-prod
