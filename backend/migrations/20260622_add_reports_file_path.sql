-- Phase 1: add report object-path support without changing existing public URL behavior.
-- Do not make the reports bucket private in this phase.

alter table public.reports
  add column if not exists file_path text;

-- Backfill legacy rows that currently store only a public Supabase Storage URL.
-- Existing URL shape:
-- https://<project>.supabase.co/storage/v1/object/public/reports/<file_path>
update public.reports
set file_path = split_part(file_url, '/storage/v1/object/public/reports/', 2)
where file_path is null
  and file_url is not null
  and file_url like '%/storage/v1/object/public/reports/%';

-- Optional verification before any future NOT NULL change:
-- select count(*) as reports_missing_file_path
-- from public.reports
-- where file_path is null;

-- Future phase only, after all rows are backfilled and the deployed backend writes file_path:
-- alter table public.reports
--   alter column file_path set not null;
