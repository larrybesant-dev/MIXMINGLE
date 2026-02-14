/**
 * Firebase Cloud Function: Send Slack/Email alerts for critical metrics
 * Triggers:
 * - Crash rate exceeds threshold
 * - User signups drop significantly
 * - Revenue milestone reached
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

admin.initializeApp();

// Configuration
const SLACK_WEBHOOK_URL = functions.config().slack?.webhook_url || '';
const CRASH_THRESHOLD = 0.02; // 2% crash rate
const SIGNUP_DROP_THRESHOLD = 0.3; // 30% drop in signups

/**
 * Monitor crash rate and alert if exceeds threshold
 */
export const monitorCrashRate = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const db = admin.firestore();

    // Get crash count in last hour
    const oneHourAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 60 * 60 * 1000)
    );

    const crashesSnapshot = await db.collection('crashes')
      .where('timestamp', '>', oneHourAgo)
      .get();

    const crashCount = crashesSnapshot.size;

    // Get total sessions in last hour (from analytics)
    const sessionsSnapshot = await db.collection('analytics_sessions')
      .where('timestamp', '>', oneHourAgo)
      .get();

    const sessionCount = sessionsSnapshot.size;

    if (sessionCount === 0) return;

    const crashRate = crashCount / sessionCount;

    if (crashRate > CRASH_THRESHOLD) {
      await sendSlackAlert({
        title: '🔴 CRITICAL: High Crash Rate Detected',
        message: `Crash rate: ${(crashRate * 100).toFixed(2)}% (${crashCount} crashes in ${sessionCount} sessions)`,
        severity: 'critical',
        action: 'Investigate immediately in Firebase Crashlytics',
      });
    }

    console.log(`Crash rate: ${(crashRate * 100).toFixed(2)}%`);
  });

/**
 * Monitor daily signups and alert if drops significantly
 */
export const monitorSignups = functions.pubsub
  .schedule('every day 09:00')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const db = admin.firestore();

    // Get signups yesterday
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);

    const yesterdayEnd = new Date(yesterday);
    yesterdayEnd.setHours(23, 59, 59, 999);

    const yesterdaySignups = await db.collection('users')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(yesterday))
      .where('createdAt', '<=', admin.firestore.Timestamp.fromDate(yesterdayEnd))
      .get();

    // Get signups day before yesterday (for comparison)
    const dayBefore = new Date(yesterday);
    dayBefore.setDate(dayBefore.getDate() - 1);

    const dayBeforeEnd = new Date(dayBefore);
    dayBeforeEnd.setHours(23, 59, 59, 999);

    const dayBeforeSignups = await db.collection('users')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(dayBefore))
      .where('createdAt', '<=', admin.firestore.Timestamp.fromDate(dayBeforeEnd))
      .get();

    const yesterdayCount = yesterdaySignups.size;
    const dayBeforeCount = dayBeforeSignups.size;

    if (dayBeforeCount === 0) return;

    const dropPercent = (dayBeforeCount - yesterdayCount) / dayBeforeCount;

    if (dropPercent > SIGNUP_DROP_THRESHOLD) {
      await sendSlackAlert({
        title: '🟡 WARNING: Signup Drop Detected',
        message: `Signups dropped ${(dropPercent * 100).toFixed(0)}% (${dayBeforeCount} → ${yesterdayCount})`,
        severity: 'warning',
        action: 'Check marketing campaigns and app store listing',
      });
    } else {
      // Send daily summary
      await sendSlackAlert({
        title: '📊 Daily Signup Report',
        message: `Yesterday: ${yesterdayCount} signups (${dropPercent > 0 ? '-' : '+'}${Math.abs(dropPercent * 100).toFixed(0)}% vs. day before)`,
        severity: 'info',
        action: null,
      });
    }
  });

/**
 * Celebrate revenue milestones
 */
export const monitorRevenue = functions.firestore
  .document('transactions/{transactionId}')
  .onCreate(async (snap, context) => {
    const transaction = snap.data();
    const db = admin.firestore();

    // Calculate total revenue
    const allTransactions = await db.collection('transactions').get();
    let totalRevenue = 0;

    allTransactions.forEach(doc => {
      totalRevenue += doc.data().amount || 0;
    });

    // Check for milestones
    const milestones = [100, 500, 1000, 5000, 10000, 50000];

    for (const milestone of milestones) {
      if (totalRevenue >= milestone && (totalRevenue - transaction.amount) < milestone) {
        await sendSlackAlert({
          title: '🎉 REVENUE MILESTONE REACHED!',
          message: `Total revenue: $${totalRevenue.toFixed(2)} (just passed $${milestone})`,
          severity: 'success',
          action: 'Celebrate with the team!',
        });
      }
    }
  });

/**
 * Send alert to Slack
 */
async function sendSlackAlert(alert: {
  title: string;
  message: string;
  severity: 'critical' | 'warning' | 'info' | 'success';
  action: string | null;
}) {
  if (!SLACK_WEBHOOK_URL) {
    console.warn('Slack webhook URL not configured');
    return;
  }

  const colors = {
    critical: '#FF0000',
    warning: '#FFA500',
    info: '#0000FF',
    success: '#00FF00',
  };

  const payload = {
    attachments: [
      {
        color: colors[alert.severity],
        title: alert.title,
        text: alert.message,
        fields: alert.action ? [
          {
            title: 'Recommended Action',
            value: alert.action,
            short: false,
          },
        ] : [],
        footer: 'Mix & Mingle Analytics',
        ts: Math.floor(Date.now() / 1000),
      },
    ],
  };

  try {
    await axios.post(SLACK_WEBHOOK_URL, payload);
    console.log('Slack alert sent:', alert.title);
  } catch (error) {
    console.error('Failed to send Slack alert:', error);
  }
}
