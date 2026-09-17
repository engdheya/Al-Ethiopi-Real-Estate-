#!/usr/bin/env node
/**
 * Grants (or revokes) the administrator custom claim.
 *
 * The app + security rules trust ONLY the `admin` custom claim — never any
 * client-side flag. There should be exactly ONE admin account.
 *
 * Usage:
 *   cd scripts && npm install
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node make_admin.js admin@example.com
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node make_admin.js admin@example.com --revoke
 *
 * The user must already exist (register in the app first), and must sign out
 * and back in for the new claim to take effect.
 */

const admin = require('firebase-admin');

admin.initializeApp({ credential: admin.applicationDefault() });

async function main() {
  const email = process.argv[2];
  const revoke = process.argv.includes('--revoke');
  if (!email || email.startsWith('--')) {
    console.error('Usage: node make_admin.js <email> [--revoke]');
    process.exit(1);
  }
  const user = await admin.auth().getUserByEmail(email);
  await admin.auth().setCustomUserClaims(user.uid, revoke ? {} : { admin: true });
  // Force existing sessions to refresh their token on next request.
  await admin.auth().revokeRefreshTokens(user.uid);
  console.log(
    revoke
      ? `Admin claim REVOKED for ${email} (${user.uid}).`
      : `Admin claim GRANTED to ${email} (${user.uid}). Ask them to sign out and back in.`,
  );
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
