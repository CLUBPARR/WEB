create table if not exists events (
  id bigint generated always as identity primary key,
  date text not null,
  month text not null,
  day text default 'SAB',
  time text not null,
  title text not null,
  sub text,
  descripcion text,
  spots int default 15,
  total int default 20,
  price numeric default 10,
  tag text default 'ART.',
  active boolean default true,
  img text,
  created_at timestamptz default now()
);
create table if not exists products (
  id bigint generated always as identity primary key,
  name text not null,
  price numeric default 0,
  type text default 'Ropa',
  descripcion text,
  bg text default '#1A1A1A',
  imgs jsonb default '[]',
  sizes jsonb default '["XS","S","M","L","XL","XXL"]',
  active boolean default true,
  created_at timestamptz default now()
);
create table if not exists gallery (
  id bigint generated always as identity primary key,
  label text not null,
  date text,
  img text,
  created_at timestamptz default now()
);
create table if not exists reservations (
  id bigint generated always as identity primary key,
  event_id bigint references events(id) on delete set null,
  event_title text,
  name text not null,
  email text not null,
  phone text,
  note text,
  created_at timestamptz default now()
);
create table if not exists settings (
  id int primary key default 1,
  club_name text default 'Club Parr',
  city text default 'Madrid, ES',
  email text default 'hola@clubparr.com',
  instagram text default '@clubparr',
  whatsapp text default '+34 600 000 000',
  manifesto text default 'Un oasis en el ruido.',
  accent_color text default '#3D7A28'
);
insert into settings (id) values (1) on conflict (id) do nothing;
alter table events enable row level security;
alter table products enable row level security;
alter table gallery enable row level security;
alter table reservations enable row level security;
alter table settings enable row level security;
create policy "Public read events" on events for select using (true);
create policy "Public read products" on products for select using (true);
create policy "Public read gallery" on gallery for select using (true);
create policy "Public read settings" on settings for select using (true);
create policy "Anon insert events" on events for insert with check (true);
create policy "Anon update events" on events for update using (true);
create policy "Anon delete events" on events for delete using (true);
create policy "Anon insert products" on products for insert with check (true);
create policy "Anon update products" on products for update using (true);
create policy "Anon delete products" on products for delete using (true);
create policy "Anon insert gallery" on gallery for insert with check (true);
create policy "Anon update gallery" on gallery for update using (true);
create policy "Anon delete gallery" on gallery for delete using (true);
create policy "Anon insert reservations" on reservations for insert with check (true);
create policy "Anon read reservations" on reservations for select using (true);
create policy "Anon delete reservations" on reservations for delete using (true);
create policy "Anon update settings" on settings for update using (true);
