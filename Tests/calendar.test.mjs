// Calendar sync transform checks. Run: node Tests/calendar.test.mjs [saved-feed.json ...]
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { buildPayload, fetchCalendar, plainText, eventCategory } from '../supabase/functions/sync-campus-events/calendar.ts';

const start = new Date('2026-11-13T00:00:00Z'), end = new Date('2027-01-08T00:00:00Z');
const raw = [
  { id: 1, gid: 10, group_title: 'Academic Events', title: 'Jazz &amp; Democracy', url: 'https://events.wesleyan.edu/event/1-jazz',
    date_iso: '2026-11-14T00:00:00-05:00', is_all_day: 1, location: '', summary: '<p>Line one&#160;</p><p>Line&nbsp;two</p>', event_types: ['Exhibition'] },
  { id: 1, gid: 10, group_title: 'Academic Events', title: 'Jazz &amp; Democracy', url: 'https://events.wesleyan.edu/event/1-jazz',
    date_iso: '2026-11-13T00:00:00-05:00', is_all_day: 1, event_types: ['Exhibition'] },
  { id: 2, gid: 5, group_title: 'Athletics', title: 'Hockey vs. Trinity', url: 'https://evil.example/x',
    date_iso: '2026-11-15T19:00:00-05:00', date2_iso: '2026-11-15T18:00:00-05:00', location: 'Spurrier-Snyder Rink', event_types: [] },
  { id: 3, gid: 5, group_title: 'Athletics', title: 'Cancelled game', date_iso: '2026-11-16T19:00:00-05:00', is_canceled: 1 },
  { id: 4, group_title: null, title: '', date_iso: '2026-11-16T19:00:00-05:00' },
  { id: 5, title: 'Bad date', date_iso: 'soon' },
];
const p = buildPayload(raw, start, end);
assert.equal(p.events.length, 2);
assert.deepEqual(p.organizations.map(o => [o.external_id, o.name, o.category]), [['10','Academic Events','Academic'], ['5','Athletics','Athletics']]);
const [jazz, hockey] = p.events;
assert.equal(jazz.title, 'Jazz & Democracy');
assert.equal(jazz.start_at, '2026-11-13T05:00:00.000Z', 'repeating event keeps earliest occurrence');
assert.equal(jazz.category, 'Arts');
assert.equal(jazz.location, 'Wesleyan University');
assert.equal(jazz.description, 'Line one\nLine two');
assert.equal(jazz.is_all_day, true);
assert.equal(hockey.category, 'Athletics', 'falls back to group category');
assert.equal(hockey.end_at, null, 'end before start dropped');
assert.equal(hockey.source_url, null, 'only events.wesleyan.edu links kept');
assert.equal(plainText('x'.repeat(3000)).length, 2000);
assert.equal(eventCategory({ event_types: ['Talks and Lectures'] }), 'Academic');

// Windowing: full windows are split until each request returns < 100 events.
const requests = [];
const fake = async url => {
  requests.push(url);
  const [, from, to] = url.match(/start_date\/(\d{4}-\d\d-\d\d)\/end_date\/(\d{4}-\d\d-\d\d)/);
  const days = (Date.parse(to) - Date.parse(from)) / 86400000 + 1;
  const count = days > 2 ? 100 : 30 * days;
  return { ok: true, status: 200, json: async () => ({ data: Array.from({ length: count }, (_, i) => ({ id: `${from}-${i}` })) }) };
};
const fetched = await fetchCalendar(start, 7, fake);
assert.equal(fetched.length, 30 * 7);
assert.ok(requests.every(u => u.startsWith('https://events.wesleyan.edu/live/json/events/start_date/')));
await assert.rejects(fetchCalendar(start, 7, async () => ({ ok: false, status: 503, json: async () => ({}) })), /503/);
await assert.rejects(fetchCalendar(start, 7, async () => ({ ok: true, status: 200, json: async () => ({ error: 'x' }) })), /Unexpected/);
console.log('Calendar transform checks passed: entities, repeats, cancellations, categories, links, windowing, failures.');

for (const path of process.argv.slice(2)) {
  const feed = JSON.parse(await readFile(path, 'utf8'));
  const payload = buildPayload(feed.data, start, end);
  assert.ok(payload.events.length > 0);
  for (const e of payload.events) {
    assert.ok(e.title && e.location && !Number.isNaN(Date.parse(e.start_at)) && !/<[a-z]/i.test(e.description));
  }
  const counts = {};
  for (const e of payload.events) counts[e.category] = (counts[e.category] || 0) + 1;
  console.log(`${path.split('/').pop()}: ${feed.data.length} feed rows → ${payload.events.length} events, ${payload.organizations.length} hosts`, counts);
}
