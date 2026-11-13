// Wesleyan events calendar (LiveWhale) → MyWes events/organizations payload.
// Pure logic with an injectable fetch so it runs in Deno (Edge Function) and
// Node (Tests/calendar.test.mjs).

export const CALENDAR_ORIGIN = "https://events.wesleyan.edu";
export const SOURCE = "wesleyan_calendar";

export type LiveWhaleEvent = {
  id: number | string;
  gid?: number | string | null;
  group_title?: string | null;
  title?: string | null;
  url?: string | null;
  date_iso?: string | null;
  date2_iso?: string | null;
  is_all_day?: number | boolean | null;
  is_canceled?: number | boolean | null;
  location?: string | null;
  summary?: string | null;
  event_types?: string[] | null;
};

export type SyncOrganization = { external_id: string; name: string; category: string; description: string };
export type SyncEvent = {
  external_id: string;
  org_external_id: string;
  title: string;
  category: string;
  description: string;
  location: string;
  start_at: string;
  end_at: string | null;
  is_all_day: boolean;
  source_url: string | null;
};
export type SyncPayload = {
  window_start: string;
  window_end: string;
  organizations: SyncOrganization[];
  events: SyncEvent[];
};

const TYPE_CATEGORY: Record<string, string> = {
  "Sports": "Athletics",
  "Arts and Performances": "Arts",
  "Exhibition": "Arts",
  "Film Screening": "Arts",
  "Talks and Lectures": "Academic",
  "Seminar and Workshops": "Academic",
  "Social Gatherings": "Social",
  "Special Events": "Social",
  "Community Outreach": "Community",
};

const GROUP_CATEGORY: Record<string, string> = {
  "Athletics": "Athletics",
  "Center for the Arts": "Arts",
  "Academic Events": "Academic",
};

export function eventCategory(e: LiveWhaleEvent): string {
  for (const type of e.event_types ?? []) {
    if (TYPE_CATEGORY[type]) return TYPE_CATEGORY[type];
  }
  return GROUP_CATEGORY[e.group_title ?? ""] ?? "Community";
}

const ENTITIES: Record<string, string> = {
  amp: "&", quot: '"', apos: "'", lt: "<", gt: ">", nbsp: " ",
  ndash: "–", mdash: "—", rsquo: "’", lsquo: "‘", rdquo: "”", ldquo: "“", hellip: "…",
};

export function plainText(html: string | null | undefined, maxLength = 2000): string {
  if (!html) return "";
  const text = html
    .replace(/<\s*(br|\/p|\/div|\/li)\b[^>]*>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (match, entity: string) => {
      if (entity[0] === "#") {
        const code = entity[1] === "x" || entity[1] === "X" ? parseInt(entity.slice(2), 16) : parseInt(entity.slice(1), 10);
        return Number.isFinite(code) && code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : match;
      }
      return ENTITIES[entity.toLowerCase()] ?? match;
    })
    .split("\n").map((line) => line.replace(/\s+/g, " ").trim()).filter(Boolean).join("\n");
  return text.length > maxLength ? text.slice(0, maxLength - 1).trimEnd() + "…" : text;
}

function validDate(value: string | null | undefined): string | null {
  if (!value) return null;
  const time = Date.parse(value);
  return Number.isNaN(time) ? null : new Date(time).toISOString();
}

/** Builds the RPC payload. Repeating events appear once per day in the feed;
 *  keep only the next occurrence so lists aren't flooded with exhibitions. */
export function buildPayload(raw: LiveWhaleEvent[], windowStart: Date, windowEnd: Date): SyncPayload {
  const organizations = new Map<string, SyncOrganization>();
  const events = new Map<string, SyncEvent>();

  for (const e of raw) {
    if (e.is_canceled) continue;
    const start = validDate(e.date_iso);
    const title = plainText(e.title, 200);
    const groupTitle = plainText(e.group_title, 100) || "Wesleyan University";
    if (!start || !title || e.id === undefined || e.id === null) continue;

    const orgID = String(e.gid ?? groupTitle);
    if (!organizations.has(orgID)) {
      organizations.set(orgID, {
        external_id: orgID,
        name: groupTitle,
        category: GROUP_CATEGORY[groupTitle] ?? "Community",
        description: `Events from ${groupTitle} on the Wesleyan University calendar.`,
      });
    }

    let end = validDate(e.date2_iso);
    if (end && end < start) end = null;
    const url = e.url && e.url.startsWith(`${CALENDAR_ORIGIN}/`) ? e.url : null;
    const candidate: SyncEvent = {
      external_id: String(e.id),
      org_external_id: orgID,
      title,
      category: eventCategory(e),
      description: plainText(e.summary),
      location: plainText(e.location, 200) || "Wesleyan University",
      start_at: start,
      end_at: end,
      is_all_day: Boolean(e.is_all_day),
      source_url: url,
    };
    const existing = events.get(candidate.external_id);
    if (!existing) {
      events.set(candidate.external_id, candidate);
    } else {
      // Keep the earliest occurrence; occurrences can omit fields the other has.
      const [first, other] = candidate.start_at < existing.start_at ? [candidate, existing] : [existing, candidate];
      events.set(candidate.external_id, {
        ...first,
        description: first.description || other.description,
        location: first.location !== "Wesleyan University" ? first.location : other.location,
        source_url: first.source_url ?? other.source_url,
      });
    }
  }

  return {
    window_start: windowStart.toISOString(),
    window_end: windowEnd.toISOString(),
    organizations: [...organizations.values()],
    events: [...events.values()].sort((a, b) => a.start_at.localeCompare(b.start_at)),
  };
}

const PAGE_LIMIT = 100;
const FIELDS = "location,summary,group_title,event_types";

function dayKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

/** Fetches [start, start + days) in week-sized windows. The feed returns at
 *  most 100 events per request, so a full window is split until it fits. */
export async function fetchCalendar(
  start: Date,
  days: number,
  fetcher: (url: string) => Promise<{ ok: boolean; status: number; json(): Promise<unknown> }> = fetch,
): Promise<LiveWhaleEvent[]> {
  const all: LiveWhaleEvent[] = [];

  async function load(from: Date, span: number): Promise<void> {
    const to = new Date(from.getTime() + (span - 1) * 86_400_000);
    const url = `${CALENDAR_ORIGIN}/live/json/events/start_date/${dayKey(from)}/end_date/${dayKey(to)}/max/${PAGE_LIMIT}/response_fields/${FIELDS}`;
    const response = await fetcher(url);
    if (!response.ok) throw new Error(`Calendar request failed (${response.status}) for ${dayKey(from)}`);
    const body = await response.json() as { data?: LiveWhaleEvent[] };
    if (!Array.isArray(body?.data)) throw new Error(`Unexpected calendar response for ${dayKey(from)}`);
    if (body.data.length >= PAGE_LIMIT && span > 1) {
      const half = Math.ceil(span / 2);
      await load(from, half);
      await load(new Date(from.getTime() + half * 86_400_000), span - half);
      return;
    }
    all.push(...body.data);
  }

  for (let offset = 0; offset < days; offset += 7) {
    await load(new Date(start.getTime() + offset * 86_400_000), Math.min(7, days - offset));
  }
  return all;
}
