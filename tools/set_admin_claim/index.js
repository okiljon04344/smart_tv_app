// Grants or revokes the `admin` custom claim for an existing Firebase Auth user.
//
// Usage:
//   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
//   node index.js grant  owner@example.com
//   node index.js revoke owner@example.com
//
// The service-account key must never be committed (see .gitignore).
import {initializeApp, applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';

const [action, email] = process.argv.slice(2);

if (!['grant', 'revoke'].includes(action) || !email) {
  console.error('Usage: node index.js <grant|revoke> <email>');
  process.exit(1);
}

initializeApp({credential: applicationDefault()});
const auth = getAuth();

try {
  const user = await auth.getUserByEmail(email);
  const claims = {...(user.customClaims ?? {})};
  if (action === 'grant') {
    claims.admin = true;
  } else {
    delete claims.admin;
  }
  await auth.setCustomUserClaims(user.uid, claims);
  console.log(`${action}: admin -> ${email} (uid: ${user.uid})`);
  console.log('The user must sign in again (or refresh the ID token) to receive it.');
} catch (err) {
  console.error(`Failed: ${err.message}`);
  process.exit(1);
}
