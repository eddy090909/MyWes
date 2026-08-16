-- Campus catalog only. Do not seed auth.users or profiles.
-- Organization and event IDs match MockData.swift for Checkpoint 3C.
-- Event times are stored as timestamptz and interpreted in America/New_York.
-- Home org-update blurbs stay mock and are intentionally not seeded here.

insert into public.organizations (
  id,
  name,
  category,
  description,
  member_count,
  contact_email,
  instagram_handle
) values
  (
    '00000000-0000-0000-0000-000000000001',
    'Wesleyan Student Assembly',
    'Governance',
    'The elected student government representing all Wesleyan undergraduates.',
    45,
    'contact@wesleyan.edu',
    'wesleyanwsa'
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'WesWings Radio',
    'Media',
    'Student-run radio station broadcasting music, talk, and live event coverage.',
    60,
    'contact@wesleyan.edu',
    'weswingsradio'
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'Fries Center for Global Studies',
    'Academic',
    'Supports study abroad, global fellowships, and international student life.',
    20,
    'contact@wesleyan.edu',
    'friescenter'
  ),
  (
    '00000000-0000-0000-0000-000000000004',
    'First-Gen Network',
    'Community',
    'A community and resource hub for first-generation college students.',
    80,
    'contact@wesleyan.edu',
    'wesfirstgen'
  ),
  (
    '00000000-0000-0000-0000-000000000005',
    'Eclectic Society',
    'Social',
    'One of Wesleyan''s program houses, known for concerts and community events.',
    35,
    'contact@wesleyan.edu',
    'eclecticwes'
  ),
  (
    '00000000-0000-0000-0000-000000000006',
    'Career Center',
    'Academic',
    'Helps students find internships, jobs, and plan life after Wesleyan.',
    15,
    'contact@wesleyan.edu',
    'wescareercenter'
  ),
  (
    '00000000-0000-0000-0000-000000000007',
    'Class of 2027 Council',
    'Governance',
    'Plans class events and represents first-years to the administration.',
    12,
    'contact@wesleyan.edu',
    'wes2027'
  ),
  (
    '00000000-0000-0000-0000-000000000008',
    'Wesleyan Dining',
    'Campus Services',
    'Runs Usdan, Summerfield, and Pi Cafe, and coordinates dining events.',
    25,
    'contact@wesleyan.edu',
    'wesdining'
  )
on conflict (id) do update set
  name = excluded.name,
  category = excluded.category,
  description = excluded.description,
  member_count = excluded.member_count,
  contact_email = excluded.contact_email,
  instagram_handle = excluded.instagram_handle;

-- WSA (…0001) and Eclectic Society (…0005) intentionally have no events.

insert into public.events (
  id,
  org_id,
  title,
  category,
  description,
  location,
  start_at,
  end_at
) values
  (
    '00000000-0000-0000-0001-000000000001',
    '00000000-0000-0000-0000-000000000007',
    'Fall Formal Kickoff',
    'Social',
    'Kick off the semester with music, food trucks, and the whole class of 2027. Dress: campus casual.',
    'Beckham Hall',
    timestamptz '2026-09-12 20:00:00 America/New_York',
    timestamptz '2026-09-12 23:00:00 America/New_York'
  ),
  (
    '00000000-0000-0000-0001-000000000002',
    '00000000-0000-0000-0000-000000000006',
    'AskWes Live: Internship Panel',
    'Academic',
    'Upperclassmen share how they landed summer internships in tech, finance, and research.',
    'PAC Rm 001',
    timestamptz '2026-09-17 18:30:00 America/New_York',
    timestamptz '2026-09-17 20:00:00 America/New_York'
  ),
  (
    '00000000-0000-0000-0001-000000000003',
    '00000000-0000-0000-0000-000000000008',
    'Midnight Breakfast',
    'Dining',
    'Free breakfast-for-dinner before finals, hosted by Dining Services and WSA.',
    'Usdan Marketplace',
    timestamptz '2026-12-10 22:00:00 America/New_York',
    timestamptz '2026-12-11 01:00:00 America/New_York'
  ),
  (
    '00000000-0000-0000-0001-000000000004',
    '00000000-0000-0000-0000-000000000004',
    'WesFest: First-Gen Mixer',
    'Community',
    'Meet other first-generation students and alumni mentors over lawn games and lunch.',
    'Fauver Field',
    timestamptz '2026-09-20 14:00:00 America/New_York',
    timestamptz '2026-09-20 16:00:00 America/New_York'
  ),
  (
    '00000000-0000-0000-0001-000000000005',
    '00000000-0000-0000-0000-000000000002',
    'Battle of the Bands',
    'Social',
    'Six student bands compete for a slot at Spring Fling.',
    'Eclectic',
    timestamptz '2026-10-04 21:00:00 America/New_York',
    timestamptz '2026-10-04 23:30:00 America/New_York'
  ),
  (
    '00000000-0000-0000-0001-000000000006',
    '00000000-0000-0000-0000-000000000003',
    'Study Abroad Info Night',
    'Academic',
    'Learn about semester and year-long programs, funding, and how credits transfer.',
    'Allbritton 311',
    timestamptz '2026-09-23 17:00:00 America/New_York',
    timestamptz '2026-09-23 18:30:00 America/New_York'
  )
on conflict (id) do update set
  org_id = excluded.org_id,
  title = excluded.title,
  category = excluded.category,
  description = excluded.description,
  location = excluded.location,
  start_at = excluded.start_at,
  end_at = excluded.end_at;
