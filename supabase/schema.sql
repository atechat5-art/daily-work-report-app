-- Run this in Supabase SQL Editor before using the production app.
create type public.user_role as enum ('employee', 'admin');
create type public.report_status as enum ('draft', 'submitted', 'approved', 'revision_requested');
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role public.user_role not null default 'employee',
  created_at timestamptz not null default now()
);
create table public.daily_reports (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  report_date date not null default current_date, completed_work text, in_progress text, issues text, actions text, tomorrow_plan text,
  attachments jsonb not null default '[]'::jsonb, status public.report_status not null default 'draft', manager_comment text,
  submitted_at timestamptz, reviewed_at timestamptz, reviewed_by uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(user_id, report_date)
);
create table public.projects (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null, progress integer not null default 0 check(progress between 0 and 100), details text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security; alter table public.daily_reports enable row level security; alter table public.projects enable row level security;
create policy "profiles read" on public.profiles for select to authenticated using (true);
create policy "own profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "reports read" on public.daily_reports for select to authenticated using (user_id = auth.uid() or (select role from public.profiles where id=auth.uid()) = 'admin');
create policy "own reports insert" on public.daily_reports for insert to authenticated with check (user_id = auth.uid());
create policy "own reports edit" on public.daily_reports for update to authenticated using (user_id = auth.uid() or (select role from public.profiles where id=auth.uid()) = 'admin') with check (user_id = auth.uid() or (select role from public.profiles where id=auth.uid()) = 'admin');
create policy "projects read" on public.projects for select to authenticated using (true);
create policy "projects write" on public.projects for insert to authenticated with check (owner_id = auth.uid());
create policy "project owner edit" on public.projects for update to authenticated using (owner_id = auth.uid() or (select role from public.profiles where id=auth.uid()) = 'admin');
insert into storage.buckets(id,name,public) values ('report-files','report-files',true) on conflict do nothing;
create policy "file upload own folder" on storage.objects for insert to authenticated with check (bucket_id='report-files' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "file public view" on storage.objects for select to public using (bucket_id='report-files');
-- Create each user profile after signup; change role to admin manually for managers.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$ begin insert into public.profiles(id,full_name) values(new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1))); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
