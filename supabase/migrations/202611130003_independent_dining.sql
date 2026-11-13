-- Independent dining locations (not run by Bon Appétit). Wesleyan lists them at
-- https://www.wesleyan.edu/dining/placestoeat.html ("Dining at Independent
-- Locations"). Checked 2026-11-13:
--   WesWings / Red & Black Café hours and addresses: https://weswings.com/
--   Cohen's Bagels hours: Wesleyan Hours of Operation page.
--   Star & Crescent and Espwesso publish no hours we can verify, so they are
--   stored with hours_published = false and the app never claims open/closed.

alter table public.dining_locations
  add column operator text not null default 'bon_appetit'
    check (operator in ('bon_appetit', 'independent')),
  add column menu_url text
    check (menu_url is null or menu_url ~ '^https://[a-z0-9.-]+/'),
  add column specials_source text
    check (specials_source is null or specials_source in ('weswings', 'red_black_cafe')),
  add column hours_published boolean not null default true;

alter table public.dining_locations drop constraint dining_locations_source_url_check;
alter table public.dining_locations add constraint dining_locations_source_url_check
  check (source_url like 'https://www.wesleyan.edu/dining/%' or source_url like 'https://weswings.com/%');

insert into public.dining_locations
  (name, location, weekly_hours, notes, source_url, operator, menu_url, specials_source,
   hours_published, sort_order, verified_on, valid_through)
values
('WesWings', '156 High St, lower level (entrance behind Religious Studies)',
 '[[{"start":660,"end":1200}],[{"start":660,"end":1200}],[{"start":660,"end":1200}],[{"start":660,"end":1200}],[{"start":660,"end":1200}],[{"start":660,"end":1200}],[{"start":660,"end":1200}]]',
 'Independent, student-favorite spot for wings, burgers, falafel, and weekend brunch. Meal plan points, Middletown Cash, and cards. Break hours may differ.',
 'https://weswings.com/', 'independent', 'https://weswings.com/weswings-2/weswings-menu/', 'weswings',
 true, 200, '2026-11-13', '2026-12-13'),
('Red & Black Café', '45 Broad St, at Williams St',
 '[[{"start":540,"end":1020}],[{"start":540,"end":1020}],[{"start":540,"end":1020}],[{"start":540,"end":1020}],[{"start":540,"end":1020}],[{"start":540,"end":1020}],[{"start":540,"end":1020}]]',
 'Independent café: panini, soups, all-day breakfast, smoothies, weekend brunch. Text orders to 860-650-1214. Meal plan points, Middletown Cash, and cards. Break hours may differ.',
 'https://weswings.com/', 'independent', 'https://weswings.com/red-black-cafe/red-black-cafe-menu/', 'red_black_cafe',
 true, 210, '2026-11-13', '2026-12-13'),
('Cohen''s Bagels', 'Inside the Wesleyan RJ Julia Bookstore, Main St',
 '[[{"start":540,"end":1020}],[{"start":540,"end":1020}],[{"start":540,"end":1020}],[{"start":540,"end":1020}],[{"start":540,"end":1020}],[{"start":540,"end":1020}],[{"start":540,"end":1020}]]',
 'Independent bagel shop. Meal plan points, Middletown Cash, and cards.',
 'https://www.wesleyan.edu/dining/Hours%20of%20Operation.html', 'independent', null, null,
 true, 220, '2026-11-13', '2026-12-13'),
('Star & Crescent', 'Alpha Delta Phi Society',
 '[[],[],[],[],[],[],[]]',
 'Eating club run by the Alpha Delta Phi Society, with chef-prepared lunch and dinner and a weekly menu that includes vegetarian options. Hours and menus are not published in a form MyWes can read.',
 'https://www.wesleyan.edu/dining/placestoeat.html', 'independent', 'https://middletown.adps.org/', null,
 false, 230, '2026-11-13', '2026-12-13'),
('Espwesso', 'Allbritton Center, lower level',
 '[[],[],[],[],[],[],[]]',
 'Student-run café. Hours change by semester and are not published online.',
 'https://www.wesleyan.edu/dining/placestoeat.html', 'independent', null, null,
 false, 240, '2026-11-13', '2026-12-13');
