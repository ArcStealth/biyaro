-- =====================================================================
-- Biyaro alpha - Supabase schema.  Paste into: Supabase > SQL Editor > Run
-- =====================================================================

-- ---------- profiles ----------
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  username    text not null check (username ~ '^[A-Za-z0-9_]{3,20}$'),
  bike_name   text check (char_length(bike_name) <= 40),
  avatar_url  text,
  created_at  timestamptz not null default now()
);
create unique index profiles_username_lower on public.profiles (lower(username));

alter table public.profiles enable row level security;
create policy "signed-in users can read profiles"
  on public.profiles for select to authenticated using (true);
create policy "users update only their own profile"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- profile row is created automatically at sign-up (username comes from app metadata)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'username', ''), 'rider_' || substr(new.id::text, 1, 6))
  );
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- trips ----------
create table public.trips (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  started_at    timestamptz not null,
  duration_s    double precision not null check (duration_s between 1 and 172800),
  distance_m    double precision not null check (distance_m between 0 and 2000000),
  stopped_s     double precision not null default 0 check (stopped_s >= 0),
  top_speed_ms  double precision not null default 0 check (top_speed_ms between 0 and 110),
  left_turns    int not null default 0 check (left_turns >= 0),
  right_turns   int not null default 0 check (right_turns >= 0),
  brake_events  int not null default 0 check (brake_events >= 0),
  lane_changes  int not null default 0 check (lane_changes >= 0),
  max_decel     double precision not null default 0 check (max_decel between 0 and 30),
  max_accel     double precision not null default 0 check (max_accel between 0 and 30),
  peak_g        double precision not null default 0 check (peak_g between 0 and 25),
  route         jsonb not null default '[]'::jsonb,
  created_at    timestamptz not null default now()
);
create index trips_user_started on public.trips (user_id, started_at desc);

alter table public.trips enable row level security;
-- routes are PRIVATE: a rider can only see their own trips
create policy "read own trips"   on public.trips for select to authenticated using (user_id = auth.uid());
create policy "insert own trips" on public.trips for insert to authenticated with check (user_id = auth.uid());
create policy "delete own trips" on public.trips for delete to authenticated using (user_id = auth.uid());

-- ---------- leaderboard (aggregates only, never routes) ----------
create or replace function public.get_leaderboard()
returns table (
  user_id uuid, username text, avatar_url text, bike_name text,
  total_km numeric, top_speed_kmh numeric, trip_count bigint
)
language sql security definer set search_path = public stable as $$
  select p.id, p.username, p.avatar_url, p.bike_name,
         round((coalesce(sum(t.distance_m), 0) / 1000.0)::numeric, 1),
         round((coalesce(max(t.top_speed_ms), 0) * 3.6)::numeric, 0),
         count(t.id)
  from public.profiles p
  join public.trips t on t.user_id = p.id
  group by p.id
  order by 5 desc
  limit 200;
$$;
revoke all on function public.get_leaderboard() from public;
grant execute on function public.get_leaderboard() to authenticated;

-- used by the sign-up screen before creating the account
create or replace function public.username_available(p_username text)
returns boolean language sql security definer set search_path = public stable as $$
  select not exists (select 1 from public.profiles where lower(username) = lower(p_username));
$$;
grant execute on function public.username_available(text) to anon, authenticated;

-- ---------- avatar storage ----------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "avatars are public"
  on storage.objects for select using (bucket_id = 'avatars');
create policy "users upload own avatar"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users update own avatar"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users delete own avatar"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- table privileges ----------
-- Newer Supabase projects may not auto-grant access to new tables, so grant it
-- explicitly. Row Level Security above still decides which rows each rider sees.
grant usage on schema public to anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, delete on public.trips to authenticated;
