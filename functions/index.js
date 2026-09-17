/**
 * Al-Ethiopi Real Estate — Cloud Functions (2nd gen, Node 20).
 *
 * Serverless backend jobs (no VPS needed):
 *  1. Maintain denormalized counters (comments / ratings / favorites / reports)
 *     so clients never need write access to other users' documents.
 *  2. Deliver push notifications for admin broadcasts + new featured
 *     properties to the `all_users` / `featured_properties` FCM topics.
 *
 * Deploy:  cd .. && firebase deploy --only functions
 */

const { setGlobalOptions } = require('firebase-functions/v2');
const { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onDocumentCreated: onDocCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');

admin.initializeApp();
const db = admin.firestore();
setGlobalOptions({ maxInstances: 10, region: 'europe-west1' });

const TOPIC_ALL = 'all_users';
const TOPIC_FEATURED = 'featured_properties';

async function adjustPropertyCounter(propertyId, field, delta) {
  if (!propertyId) return;
  try {
    await db
      .collection('properties')
      .doc(propertyId)
      .update({ [field]: admin.firestore.FieldValue.increment(delta) });
  } catch (e) {
    logger.warn(`adjustPropertyCounter ${field} failed`, e.message);
  }
}

// ------------------------------------------------------------ comments

exports.onCommentCreated = onDocumentCreated('comments/{commentId}', async (event) => {
  const data = event.data.data();
  await adjustPropertyCounter(data.propertyId, 'commentsCount', 1);
});

exports.onCommentDeleted = onDocumentDeleted('comments/{commentId}', async (event) => {
  const data = event.data.data();
  await adjustPropertyCounter(data.propertyId, 'commentsCount', -1);
});

// ------------------------------------------------------------ ratings

exports.onRatingWritten = onDocCreated('ratings/{ratingId}', async (event) => {
  await recomputeRating(event.data.data().propertyId);
});

exports.onRatingUpdated = onDocumentUpdated('ratings/{ratingId}', async (event) => {
  await recomputeRating(event.data.after.data().propertyId);
});

exports.onRatingDeleted = onDocumentDeleted('ratings/{ratingId}', async (event) => {
  await recomputeRating(event.data.data().propertyId);
});

async function recomputeRating(propertyId) {
  if (!propertyId) return;
  const snap = await db.collection('ratings').where('propertyId', '==', propertyId).get();
  let sum = 0;
  snap.forEach((d) => {
    sum += Number(d.data().value) || 0;
  });
  const count = snap.size;
  const avg = count === 0 ? 0 : Math.round((sum / count) * 10) / 10;
  await db.collection('properties').doc(propertyId).update({
    ratingAvg: avg,
    ratingCount: count,
  });
}

// ---------------------------------------------------------- favorites

exports.onFavoriteCreated = onDocumentCreated(
  'users/{uid}/favorites/{propertyId}',
  async (event) => {
    await adjustPropertyCounter(event.params.propertyId, 'favoritesCount', 1);
  },
);

exports.onFavoriteDeleted = onDocumentDeleted(
  'users/{uid}/favorites/{propertyId}',
  async (event) => {
    await adjustPropertyCounter(event.params.propertyId, 'favoritesCount', -1);
  },
);

// ------------------------------------------------------------ reports

exports.onReportCreated = onDocumentCreated('reports/{reportId}', async (event) => {
  const data = event.data.data();
  if (!data.commentId) return;
  try {
    await db
      .collection('comments')
      .doc(data.commentId)
      .update({ reportCount: admin.firestore.FieldValue.increment(1) });
  } catch (e) {
    logger.warn('reportCount increment failed', e.message);
  }
});

// ------------------------------------------------------ push: broadcasts

exports.onNotificationCreated = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const data = event.data.data();
    const topic = data.type === 'featured_property' ? TOPIC_FEATURED : TOPIC_ALL;
    const message = {
      topic,
      notification: {
        title: data.title || 'الأثيوبي للعقارات',
        body: data.body || '',
      },
      data: {
        propertyId: data.propertyId || '',
        type: data.type || 'announcement',
      },
      android: { priority: 'high' },
    };
    if (data.imageUrl) message.notification.imageUrl = data.imageUrl;
    try {
      const id = await admin.messaging().send(message);
      logger.info(`Push sent to ${topic}: ${id}`);
    } catch (e) {
      logger.error('Push send failed', e.message);
    }
  },
);

// ------------------------------------------- push: new featured properties

exports.onPropertyWritten = onDocumentCreated('properties/{propertyId}', async (event) => {
  const data = event.data.data();
  await maybeAnnounceFeatured(event.params.propertyId, null, data);
});

exports.onPropertyUpdated = onDocumentUpdated('properties/{propertyId}', async (event) => {
  await maybeAnnounceFeatured(
    event.params.propertyId,
    event.data.before.data(),
    event.data.after.data(),
  );
});

async function maybeAnnounceFeatured(propertyId, before, after) {
  const wasFeatured = before?.isFeatured === true && before?.isPublished === true;
  const isFeatured = after?.isFeatured === true && after?.isPublished === true;
  if (isFeatured === wasFeatured) return; // only on false -> true transitions
  try {
    await admin.messaging().send({
      topic: TOPIC_FEATURED,
      notification: {
        title: 'عقار مميز جديد',
        body: after.title || 'اكتشف أحدث العقارات المميزة',
      },
      data: { propertyId, type: 'featured_property' },
      android: { priority: 'high' },
    });
    logger.info(`Featured push sent for ${propertyId}`);
  } catch (e) {
    logger.error('Featured push failed', e.message);
  }
}
