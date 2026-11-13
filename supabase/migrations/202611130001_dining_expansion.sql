-- Dining expansion: every Bon Appétit location on campus, date-specific
-- hours (breaks and holidays), Bon Appétit menu slugs, and display order.
--
-- Hours checked against https://www.wesleyan.edu/dining/Hours%20of%20Operation.html
-- and placestoeat.html on 2026-11-13. Regular hours resume 2026-11-30; the
-- schedule expires 2026-12-13 so the app stops claiming open/closed once
-- finals and winter-break hours (not yet published) take over.

alter table public.dining_locations
  add column special_hours jsonb not null default '{}'::jsonb
    check (jsonb_typeof(special_hours) = 'object'),
  add column menu_slug text
    check (menu_slug is null or menu_slug ~ '^[a-z0-9-]{1,80}$'),
  add column sort_order int not null default 100;

-- Thanksgiving break 2026 (Fri 11/20 – Sun 11/29). Keys are campus dates;
-- an empty array means closed that day.
update public.dining_locations set
  menu_slug = 'the-marketplace-at-usdan', sort_order = 10,
  location = 'Usdan University Center, 2nd floor',
  notes = 'All-you-care-to-eat. Meal swipes, points, Middletown Cash, and cards. Weekends: brunch 11–2, dinner 5–8.',
  special_hours = '{
    "2026-11-25": [{"start":660,"end":780},{"start":1020,"end":1140}],
    "2026-11-26": [], "2026-11-27": [],
    "2026-11-28": [{"start":660,"end":780},{"start":1020,"end":1140}],
    "2026-11-29": [{"start":660,"end":780},{"start":1020,"end":1200}]
  }'::jsonb
where name = 'Usdan Marketplace';

update public.dining_locations set
  menu_slug = 'summerfields', sort_order = 20,
  location = 'Butterfield C',
  notes = 'Made-to-order meals. Late night 9:30 PM–1 AM daily; order in Wes2Go by 12:30 AM. Late night may close early when busy.',
  special_hours = '{
    "2026-11-23": [{"start":660,"end":1260}],
    "2026-11-24": [], "2026-11-25": [], "2026-11-26": [], "2026-11-27": [], "2026-11-28": [],
    "2026-11-29": [{"start":1050,"end":1260}]
  }'::jsonb
where name = 'Summerfields';

update public.dining_locations set
  menu_slug = 'usdan-cafe', sort_order = 30,
  location = 'Usdan University Center, 1st floor',
  notes = 'Grab-and-go, coffee, and snacks. Meal swipes for breakfast (8–10 AM) and lunch (11 AM–2 PM). Special weekend openings may differ.',
  special_hours = '{
    "2026-11-24": [{"start":480,"end":1020}],
    "2026-11-25": [], "2026-11-26": [], "2026-11-27": []
  }'::jsonb
where name = 'Usdan Café';

insert into public.dining_locations
  (name, location, weekly_hours, special_hours, notes, source_url, menu_slug, sort_order, verified_on, valid_through)
values
('Pi² Café', 'Casper Life Sciences Building',
 '[[],[{"start":480,"end":1140}],[{"start":480,"end":1140}],[{"start":480,"end":1140}],[{"start":480,"end":1140}],[{"start":480,"end":1020}],[]]',
 '{"2026-11-24": [{"start":480,"end":960}], "2026-11-25": [], "2026-11-26": [], "2026-11-27": []}',
 'Breakfast sandwiches, crepes, and Pierce Brothers coffee. Meal swipes 8 AM–2 PM. Hours may change as the new space settles.',
 'https://www.wesleyan.edu/dining/Hours%20of%20Operation.html', 'pi-cafe', 40, '2026-11-13', '2026-12-13'),
('Cardinal Café', 'Freeman Athletic Center',
 '[[],[{"start":480,"end":1200}],[{"start":480,"end":1200}],[{"start":480,"end":1200}],[{"start":480,"end":1200}],[{"start":480,"end":1200}],[]]',
 '{"2026-11-23": [], "2026-11-24": [], "2026-11-25": [], "2026-11-26": [], "2026-11-27": []}',
 'Smoothies and quick bites. Meal swipes for breakfast, lunch, and dinner.',
 'https://www.wesleyan.edu/dining/Hours%20of%20Operation.html', 'cardinal-cafe', 50, '2026-11-13', '2026-12-13'),
('WesShop Essentials', 'Campus convenience market',
 '[[{"start":720,"end":1440}],[{"start":690,"end":1440}],[{"start":690,"end":1440}],[{"start":690,"end":1440}],[{"start":690,"end":1440}],[{"start":840,"end":1080}],[{"start":840,"end":1080}]]',
 '{"2026-11-24": [{"start":720,"end":960}], "2026-11-25": [], "2026-11-26": [], "2026-11-27": [], "2026-11-28": [], "2026-11-29": [{"start":960,"end":1440}]}',
 'Groceries, local brands, and Halal, Kosher, and Organic options. Meal swipes accepted for lunch Monday–Thursday.',
 'https://www.wesleyan.edu/dining/Hours%20of%20Operation.html', null, 60, '2026-11-13', '2026-12-13'),
('Daniel Family Commons', 'Usdan University Center, 3rd floor',
 '[[],[{"start":690,"end":810}],[{"start":690,"end":810}],[{"start":690,"end":810}],[{"start":690,"end":810}],[{"start":690,"end":810}],[]]',
 '{"2026-11-20": [], "2026-11-23": [], "2026-11-24": [], "2026-11-25": [], "2026-11-26": [], "2026-11-27": []}',
 'Faculty and staff dining; students welcome as guests. $14 with Middletown Cash, card, or faculty/staff swipes.',
 'https://www.wesleyan.edu/dining/Hours%20of%20Operation.html', 'daniel-family-commons', 70, '2026-11-13', '2026-12-13'),
('Wesleyan Food Truck', 'Huss Courtyard',
 '[[],[{"start":660,"end":810}],[{"start":660,"end":810}],[{"start":660,"end":810}],[{"start":660,"end":810}],[{"start":660,"end":810}],[]]',
 '{"2026-11-26": [], "2026-11-27": []}',
 'Weather permitting. Meal swipes, points, Middletown Cash, and cards.',
 'https://www.wesleyan.edu/dining/Hours%20of%20Operation.html', null, 80, '2026-11-13', '2026-12-13');

update public.dining_locations
set verified_on = '2026-11-13', valid_through = '2026-12-13'
where name in ('Usdan Marketplace', 'Summerfields', 'Usdan Café');
