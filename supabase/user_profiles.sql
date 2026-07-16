create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  age int,
  gender text,
  avatar_url text,
  has_completed_simulation boolean not null default false,
  status text not null default 'safe',
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "read own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "insert own profile" on public.profiles
  for insert with check (auth.uid() = id);
create policy "update own profile" on public.profiles
  for update using (auth.uid() = id);

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "anyone can view avatars" on storage.objects
  for select using (bucket_id = 'avatars');
create policy "authenticated can upload avatars" on storage.objects
  for insert to authenticated with check (bucket_id = 'avatars');