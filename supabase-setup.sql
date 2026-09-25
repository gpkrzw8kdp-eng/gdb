-- Abi Orga Ideen – Datenbank-Setup für Supabase
-- Einmal komplett im Supabase SQL Editor ausführen.
-- Vorher unten den Zugangscode ('abi-orga-2027') durch einen eigenen ersetzen!

-- 1) Tabelle für die Ideen
create table if not exists public.ideen (
  id           bigint generated always as identity primary key,
  erstellt_am  timestamptz not null default now(),
  name         text not null check (char_length(name) between 1 and 80),
  klasse       text not null check (char_length(klasse) between 1 and 10),
  kategorie    text not null check (kategorie in ('Abi-Motto', 'Finanzierung', 'Abiball', 'Abizeitung', 'Abi Merch', 'Projekte')),
  idee         text not null check (char_length(idee) between 1 and 2000),
  erledigt     boolean not null default false
);

alter table public.ideen enable row level security;

-- Jeder (auch ohne Login) darf Ideen einreichen …
drop policy if exists "Jeder darf Ideen einreichen" on public.ideen;
create policy "Jeder darf Ideen einreichen"
  on public.ideen for insert
  to anon
  with check (true);

-- … aber niemand darf die Tabelle direkt lesen (keine SELECT-Policy).
-- Lesen geht nur über die Funktion ideen_abrufen() mit Zugangscode.

-- 2) Zugangscode für die Übersichtsseite
create table if not exists public.einstellungen (
  schluessel text primary key,
  wert       text not null
);
alter table public.einstellungen enable row level security;  -- keine Policies → über die API nicht erreichbar

insert into public.einstellungen (schluessel, wert)
values ('zugangscode', 'abi-orga-2027')            -- <── HIER eigenen Code eintragen
on conflict (schluessel) do update set wert = excluded.wert;

-- 3) Funktion, über die die Übersichtsseite die Ideen lädt
create or replace function public.ideen_abrufen(code text)
returns setof public.ideen
language plpgsql
security definer
set search_path = public
stable
as $$
begin
  if not exists (
    select 1 from public.einstellungen
    where schluessel = 'zugangscode' and wert = code
  ) then
    raise exception 'Falscher Zugangscode' using errcode = '28000';
  end if;

  return query
    select * from public.ideen
    order by erstellt_am desc;
end;
$$;

revoke all on function public.ideen_abrufen(text) from public;
grant execute on function public.ideen_abrufen(text) to anon, authenticated;

-- 4) Ideen abhaken (erledigt) und löschen – ebenfalls nur mit Zugangscode
alter table public.ideen add column if not exists erledigt boolean not null default false;

create or replace function public.idee_erledigt_setzen(code text, idee_id bigint, wert boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.einstellungen
    where schluessel = 'zugangscode' and wert = code
  ) then
    raise exception 'Falscher Zugangscode' using errcode = '28000';
  end if;

  update public.ideen set erledigt = wert where id = idee_id;
end;
$$;

create or replace function public.idee_loeschen(code text, idee_id bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.einstellungen
    where schluessel = 'zugangscode' and wert = code
  ) then
    raise exception 'Falscher Zugangscode' using errcode = '28000';
  end if;

  delete from public.ideen where id = idee_id;
end;
$$;

revoke all on function public.idee_erledigt_setzen(text, bigint, boolean) from public;
revoke all on function public.idee_loeschen(text, bigint) from public;
grant execute on function public.idee_erledigt_setzen(text, bigint, boolean) to anon, authenticated;
grant execute on function public.idee_loeschen(text, bigint) to anon, authenticated;

-- Zugangscode später ändern:
-- update public.einstellungen set wert = 'neuer-code' where schluessel = 'zugangscode';

-- Falls die Datenbank schon ohne 'Abi-Motto' angelegt wurde, nur das hier ausführen:
-- alter table public.ideen drop constraint ideen_kategorie_check;
-- alter table public.ideen add constraint ideen_kategorie_check
--   check (kategorie in ('Abi-Motto', 'Finanzierung', 'Abiball', 'Abizeitung', 'Abi Merch', 'Projekte'));
