-- ============================================================================
--  CLUB PARR — Esquema + SEGURIDAD
--  Ejecuta TODO este archivo en: Supabase → SQL Editor → New query → Run
-- ============================================================================

-- ─── TABLAS ─────────────────────────────────────────────────────────────────
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

-- ─── COLUMNAS NUEVAS (galería por evento + evento finalizado) ────────────────
alter table events  add column if not exists finished boolean default false;
alter table gallery add column if not exists event_id bigint references events(id) on delete set null;

-- ─── ACTIVAR ROW LEVEL SECURITY ─────────────────────────────────────────────
alter table events       enable row level security;
alter table products     enable row level security;
alter table gallery      enable row level security;
alter table reservations enable row level security;
alter table settings     enable row level security;

-- ─── BORRAR LAS POLÍTICAS ANTIGUAS (las que dejaban entrar a cualquiera) ─────
drop policy if exists "Public read events"      on events;
drop policy if exists "Anon insert events"      on events;
drop policy if exists "Anon update events"      on events;
drop policy if exists "Anon delete events"      on events;
drop policy if exists "Public read products"    on products;
drop policy if exists "Anon insert products"    on products;
drop policy if exists "Anon update products"    on products;
drop policy if exists "Anon delete products"    on products;
drop policy if exists "Public read gallery"     on gallery;
drop policy if exists "Anon insert gallery"     on gallery;
drop policy if exists "Anon update gallery"     on gallery;
drop policy if exists "Anon delete gallery"     on gallery;
drop policy if exists "Anon insert reservations" on reservations;
drop policy if exists "Anon read reservations"   on reservations;
drop policy if exists "Anon delete reservations" on reservations;
drop policy if exists "Anon update settings"     on settings;

-- ─── POLÍTICAS NUEVAS Y SEGURAS ─────────────────────────────────────────────
-- LECTURA PÚBLICA: la web necesita leer eventos, productos, galería y ajustes.
create policy "read events"   on events   for select using (true);
create policy "read products" on products for select using (true);
create policy "read gallery"  on gallery  for select using (true);
create policy "read settings" on settings for select using (true);

-- ESCRITURA: SOLO usuarios con sesión iniciada (el admin logueado).
-- 'authenticated' = alguien que ha hecho login en el panel con email+contraseña.
create policy "admin write events"   on events   for all to authenticated using (true) with check (true);
create policy "admin write products" on products for all to authenticated using (true) with check (true);
create policy "admin write gallery"  on gallery  for all to authenticated using (true) with check (true);
create policy "admin write settings" on settings for all to authenticated using (true) with check (true);

-- RESERVAS: el público NO puede leerlas ni tocarlas (datos personales de clientes).
-- Solo el admin logueado puede verlas/borrarlas. Las nuevas entran por la función de abajo.
create policy "admin read reservations"   on reservations for select to authenticated using (true);
create policy "admin delete reservations" on reservations for delete to authenticated using (true);

-- ─── FUNCIÓN SEGURA DE RESERVA ──────────────────────────────────────────────
-- El público no escribe en las tablas directamente: llama a esta función, que
-- guarda la reserva y descuenta una plaza de forma atómica y controlada.
create or replace function reserve_event(
  p_event_id    bigint,
  p_event_title text,
  p_name        text,
  p_email       text,
  p_phone       text default null,
  p_note        text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into reservations (event_id, event_title, name, email, phone, note)
  values (p_event_id, p_event_title, p_name, p_email, p_phone, p_note);

  if p_event_id is not null then
    update events set spots = spots - 1
    where id = p_event_id and spots > 0;
  end if;
end;
$$;

grant execute on function reserve_event(bigint, text, text, text, text, text) to anon, authenticated;

-- ─── ALMACENAMIENTO DE IMÁGENES (Storage) ───────────────────────────────────
-- ANTES de ejecutar estas 4 líneas, crea el bucket:
--   Supabase → Storage → New bucket → nombre: media → marca "Public bucket" → Save
create policy "public read media"  on storage.objects for select                using (bucket_id = 'media');
create policy "admin upload media" on storage.objects for insert to authenticated with check (bucket_id = 'media');
create policy "admin update media" on storage.objects for update to authenticated using (bucket_id = 'media');
create policy "admin delete media" on storage.objects for delete to authenticated using (bucket_id = 'media');

-- ============================================================================
--  Después de ejecutar esto:
--   1) Storage → crea el bucket público "media" (si no lo hiciste arriba).
--   2) Authentication → Users → Add user → tu email + contraseña (ese será tu login del panel).
--   3) Borra los eventos que no son tuyos:  delete from events where id in (...);
-- ============================================================================
