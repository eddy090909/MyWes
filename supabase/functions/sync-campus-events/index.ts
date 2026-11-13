// Supabase Edge Function: syncs the public Wesleyan events calendar into
// public.events / public.organizations through public.sync_campus_events.
//
// Deploy:  supabase functions deploy sync-campus-events --no-verify-jwt
// Secret:  supabase secrets set CALENDAR_SYNC_SECRET=<random string>
// Invoke:  POST with header `x-sync-secret: <same string>` (hourly via pg_cron;
//          see docs/DEVELOPMENT.md).

import { createClient } from "npm:@supabase/supabase-js@2";
import { buildPayload, fetchCalendar } from "./calendar.ts";

const DAYS_AHEAD = 56;

function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (request) => {
  const secret = Deno.env.get("CALENDAR_SYNC_SECRET") ?? "";
  const provided = request.headers.get("x-sync-secret") ?? "";
  if (request.method !== "POST" || secret.length < 16 || !constantTimeEqual(provided, secret)) {
    return new Response("Forbidden", { status: 403 });
  }

  try {
    // Start at the beginning of today in campus time (UTC-5/-4); one extra
    // day back keeps today's all-day events inside the window.
    const now = new Date();
    const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - 1));
    const raw = await fetchCalendar(start, DAYS_AHEAD);
    const end = new Date(start.getTime() + DAYS_AHEAD * 86_400_000);
    const payload = buildPayload(raw, start, end);
    if (payload.events.length === 0) {
      // An empty feed is far more likely an outage than a cancelled semester.
      return Response.json({ skipped: "calendar returned no events" }, { status: 502 });
    }

    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
      auth: { persistSession: false },
    });
    const { data, error } = await supabase.rpc("sync_campus_events", { payload });
    if (error) throw error;
    return Response.json({ fetched: raw.length, ...data });
  } catch (error) {
    console.error("sync-campus-events failed", error);
    return Response.json({ error: "sync failed" }, { status: 500 });
  }
});
