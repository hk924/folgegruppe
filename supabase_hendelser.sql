-- Kjør denne i Supabase, under SQL Editor, én gang.
-- Den lager tabellen appen skriver bruksdata til, og funksjonen som leser den ut
-- som oppsummering. Rådataene er ikke lesbare med anon-nøkkelen, heller ikke for oss.

create table if not exists hendelser (
  id bigserial primary key,
  ts timestamptz not null default now(),
  person text,            -- medlems-id, null om ingen er valgt på telefonen
  navn text,              -- fornavn, for lesbarhet
  hus text,               -- husstandens navn, altså barnet
  handling text not null, -- "apnet", "tab", "pm", "bane", "drop", "take" ...
  detalj text,            -- kort og enum-aktig, aldri fritekst fra bruker
  bygg text               -- byggmerket, viser hvem som kjører gammel kode
);

create index if not exists hendelser_ts on hendelser (ts desc);
create index if not exists hendelser_navn_ts on hendelser (navn, ts desc);

alter table hendelser enable row level security;

drop policy if exists "anon kan skrive" on hendelser;
create policy "anon kan skrive" on hendelser
  for insert with check (true);
-- Ingen select-policy med vilje. Gruppa kan ikke lese hverandres aktivitet,
-- og en anon-nøkkel som kommer på avveie gir ingen historikk.

-- Eneste vei inn til tallene: en funksjon som bare returnerer oppsummeringer.
create or replace function bruk_oppsummering(dager int default 7)
returns json
language sql
security definer
set search_path = public
as $$
  with vindu as (
    select * from hendelser where ts > now() - make_interval(days => dager)
  )
  select json_build_object(
    'dager', dager,
    -- sist sett regnes over hele historikken, for det er de fraværende vi er ute etter
    'personer', coalesce((
      select json_agg(x order by x->>'sist' desc nulls last) from (
        select json_build_object(
          'navn', h.navn,
          'hus', h.hus,
          'apninger', count(*) filter (
            where h.handling = 'apnet' and h.ts > now() - make_interval(days => dager)),
          'handlinger', count(*) filter (where h.ts > now() - make_interval(days => dager)),
          'sist', max(h.ts)
        ) as x
        from hendelser h
        where h.navn is not null
        group by h.navn, h.hus
      ) q
    ), '[]'::json),
    'handlinger', coalesce((
      select json_agg(y order by (y->>'antall')::int desc) from (
        select json_build_object('handling', handling, 'antall', count(*)) as y
        from vindu group by handling
      ) r
    ), '[]'::json),
    'perDag', coalesce((
      select json_agg(z order by z->>'dag') from (
        select json_build_object(
          'dag', d::date,
          'apninger', (select count(*) from hendelser h2
                       where h2.handling = 'apnet' and h2.ts::date = d::date)
        ) as z
        from generate_series(current_date - 13, current_date, interval '1 day') d
      ) s
    ), '[]'::json),
    'bygg', coalesce((
      select json_agg(w order by w->>'bygg' desc) from (
        select json_build_object('bygg', coalesce(bygg, 'ukjent'),
                                 'personer', count(distinct navn)) as w
        from vindu group by bygg
      ) t
    ), '[]'::json)
  );
$$;

revoke all on function bruk_oppsummering(int) from public;
grant execute on function bruk_oppsummering(int) to anon;

-- Rydd av og til, for eksempel én gang i halvåret:
-- delete from hendelser where ts < now() - interval '90 days';
