// Verifies ../database.rules.json against the local Realtime Database emulator.
// Run: npm install && npm test
import {readFileSync} from 'node:fs';
import {after, before, beforeEach, describe, test} from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {get, ref, set, update} from 'firebase/database';

let env;
const owner = () => env.authenticatedContext('u1').database();
const other = () => env.authenticatedContext('u2').database();
const admin = () => env.authenticatedContext('admin1', {admin: true}).database();
const guest = () => env.unauthenticatedContext().database();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-smart-tv',
    database: {rules: readFileSync('../database.rules.json', 'utf8')},
  });
});
beforeEach(() => env.clearDatabase());
after(() => env.cleanup());

describe('catalog', () => {
  test('anyone can read movies', async () => {
    await assertSucceeds(get(ref(guest(), 'movies')));
  });

  test('the former hard-coded admin email no longer grants write access', async () => {
    const db = env
      .authenticatedContext('attacker', {email: 'okiljonnabev@gmail.com', email_verified: false})
      .database();
    await assertFails(set(ref(db, 'movies/1'), {title: 'Injected'}));
  });

  test('admin claim can publish movies', async () => {
    await assertSucceeds(set(ref(admin(), 'movies/1'), {title: 'Demo'}));
  });
});

describe('user data', () => {
  test('users can only read their own data', async () => {
    await assertSucceeds(get(ref(owner(), 'users/u1')));
    await assertFails(get(ref(other(), 'users/u1')));
  });

  test('users can create their default free subscription', async () => {
    await assertSucceeds(
      set(ref(owner(), 'users/u1/subscription'), {plan: 'free', active: false, updated_at: 1}),
    );
  });

  test('users cannot upgrade themselves to a paid plan', async () => {
    await assertFails(
      set(ref(owner(), 'users/u1/subscription'), {plan: 'premium', active: true, updated_at: 1}),
    );
  });

  test('users can refresh the timestamp of a plan granted by an admin', async () => {
    await assertSucceeds(
      set(ref(admin(), 'users/u1/subscription'), {plan: 'premium', active: true, updated_at: 1}),
    );
    await assertSucceeds(update(ref(owner(), 'users/u1/subscription'), {updated_at: 2}));
  });

  test('users cannot write another user\'s favorites', async () => {
    await assertFails(set(ref(other(), 'users/u1/favorites'), {m1: true}));
  });
});
