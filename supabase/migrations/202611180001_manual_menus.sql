-- Hand-entered menus for services Bon Appétit doesn't publish (Summerfields
-- late night is only listed in the Wes2Go / Transact ordering app). Each entry:
-- {"service": "Late night", "start": 1290, "end": 1500, "source": "Wes2Go",
--  "verified_on": "YYYY-MM-DD",
--  "sections": [{"name": "...", "items": [{"name": "...", "details": "...", "price": "..."}]}]}
-- "start" must match the start of the service period in weekly/special hours.

alter table public.dining_locations
  add column manual_menus jsonb not null default '[]'::jsonb
    check (jsonb_typeof(manual_menus) = 'array');
