-- Kjør denne i Supabase, under SQL Editor, én gang.

create table if not exists app_kv (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

alter table app_kv enable row level security;

create policy "public read" on app_kv
  for select using (true);

create policy "public insert" on app_kv
  for insert with check (true);

create policy "public update" on app_kv
  for update using (true);

-- Gjør at endringer sendes ut live til alle som har appen åpen
alter publication supabase_realtime add table app_kv;
