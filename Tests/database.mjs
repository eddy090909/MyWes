import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
const { PGlite } = await import(process.env.MYWES_PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
let checks = 0;
const query = (sql, args) => db.query(sql, args);
const equal = (a, b) => { assert.deepEqual(a, b); checks++; };
const denied = async (sql, args) => {
  await assert.rejects(query(sql, args), e => ['42501','23514','23503'].includes(e.code)); checks++;
};
await db.exec(`
create role anon; create role authenticated; create role supabase_auth_admin;
create schema auth;
create table auth.users(id uuid primary key, email text);
create function auth.uid() returns uuid language sql stable as
$$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth, public to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
`);
const migrationDir = new URL('../supabase/migrations/', import.meta.url);
for (const name of (await readdir(migrationDir)).filter(n => n.endsWith('.sql')).sort()) {
  await db.exec(await readFile(new URL(name, migrationDir), 'utf8'));
}
const a = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', b = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
await query('insert into auth.users values ($1,$2),($3,$4)', [a, 'a@wesleyan.edu', b, 'b@wesleyan.edu']);
const { rows: [org] } = await query("insert into organizations(name,category) values ('Test org','Community') returning id");
const { rows: [event] } = await query("insert into events(org_id,title,category,location,start_at) values ($1,'Test event','Community','Campus',now()) returning id", [org.id]);
async function as(user) {
  await db.exec('reset role');
  await query("select set_config('request.jwt.claim.sub',$1,false)", [user || '']);
  await db.exec('set role ' + (user ? 'authenticated' : 'anon'));
}
await as(null);
for (const table of ['profiles','organizations','events','org_follows','event_saves','questions','answers','dining_locations']) {
  await denied('select * from ' + table);
}
await as(a);
equal((await query('select id from profiles')).rows, [{id:a}]);
equal((await query('select id from organizations')).rows.length, 1);
equal((await query('select * from dining_locations')).rows.length, 8);
equal((await query("select name from dining_locations where menu_slug is not null order by sort_order")).rows.map(r => r.name),
  ['Usdan Marketplace','Summerfields','Usdan Café','Pi² Café','Cardinal Café','Daniel Family Commons']);
equal((await query("select special_hours->'2026-11-26' as d from dining_locations where name='Usdan Marketplace'")).rows[0].d, []);
equal((await query("select count(*)::int as n from dining_locations where jsonb_array_length(weekly_hours) <> 7 or valid_through < '2026-12-01'")).rows[0].n, 0);
await denied("update dining_locations set menu_slug='x' where name='Summerfields'");
await query("update profiles set full_name='Student A',class_year=2028 where id=$1",[a]);
equal((await query('select full_name from profiles')).rows[0].full_name, 'Student A');
equal((await query("update profiles set full_name='Intruder' where id=$1 returning id",[b])).rows.length, 0);
await denied("update profiles set email='other@wesleyan.edu' where id=$1",[a]);
await denied("insert into organizations(name,category) values ('Unauthorized','Other')");
await query('insert into org_follows(user_id,org_id) values ($1,$2)', [a,org.id]);
await query('insert into event_saves(user_id,event_id) values ($1,$2)', [a,event.id]);
await denied('insert into org_follows(user_id,org_id) values ($1,$2)',[b,org.id]);
await denied('insert into event_saves(user_id,event_id) values ($1,$2)',[b,event.id]);
const {rows:[q]} = await query("insert into questions(title,body,topic) values ('Where is dining?','Looking for lunch.','Dining') returning *");
equal(q.author_id, a);
await denied("insert into questions(author_id,title,body,topic) values ($1,'Forged author','Body','Dining')", [b]);
await denied("insert into questions(title,body,topic) values ('bad','Body','Dining')");
await denied("update questions set body='Changed' where id=$1",[q.id]);
await as(b);
equal((await query('select * from event_saves')).rows.length, 0);
equal((await query('select * from org_follows')).rows.length, 0);
equal((await query('delete from event_saves where user_id=$1 returning *',[a])).rows.length,0);
equal((await query('delete from org_follows where user_id=$1 returning *',[a])).rows.length,0);
equal((await query('delete from questions where id=$1 returning id',[q.id])).rows.length,0);
const {rows:[answer]} = await query("insert into answers(question_id,body) values ($1,'Try Usdan.') returning *",[q.id]);
equal(answer.author_id,b);
await denied("insert into answers(question_id,body,author_id) values ($1,'Forged',$2)",[q.id,a]);
await as(a);
equal((await query('select * from answers where question_id=$1',[q.id])).rows.length,1);
equal((await query('delete from answers where id=$1 returning id',[answer.id])).rows.length,0);
await as(b);
equal((await query('delete from answers where id=$1 returning id',[answer.id])).rows.length,1);
await query("insert into answers(question_id,body) values ($1,'Another answer')",[q.id]);
await as(a);
equal((await query('delete from questions where id=$1 returning id',[q.id])).rows.length,1);
equal((await query('select * from answers where question_id=$1',[q.id])).rows.length,0);
equal((await query('delete from event_saves where user_id=$1 returning *',[a])).rows.length,1);
equal((await query('delete from org_follows where user_id=$1 returning *',[a])).rows.length,1);
await db.exec('reset role; set role supabase_auth_admin');
equal((await query(`select hook_restrict_wesleyan_email('{"user":{"email":"a@wesleyan.edu"}}') result`)).rows[0].result,{});
equal((await query(`select hook_restrict_wesleyan_email('{"user":{"email":"a@gmail.com"}}') result`)).rows[0].result.error.http_code,403);
await db.close();
console.log(`${checks} PostgreSQL permission and persistence checks passed. Auth schema/roles are local test fixtures; hosted OAuth is not tested here.`);
