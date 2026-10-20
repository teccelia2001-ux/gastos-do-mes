-- Banco do app Gastos do Mês (projeto Supabase "Finanças Pessoal").
-- Rodar inteiro, uma vez, em SQL Editor > New query > Run.
-- Pode rodar de novo sem estragar nada: só cria o que ainda não existe.
--
-- Cada pessoa só enxerga e altera os próprios lançamentos (RLS por auth.uid()).

create table if not exists public.gastos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  descricao   text not null check (char_length(descricao) between 1 and 80),
  valor       numeric(12,2) not null check (valor > 0),
  categoria   text not null default 'outros',
  data        date not null,
  mes         text not null check (mes ~ '^\d{4}-\d{2}$'),
  forma       text not null default 'Pix',
  pago        boolean not null default true,
  fixo        boolean not null default false,
  criado_em   timestamptz not null default now()
);

create index if not exists gastos_user_mes on public.gastos (user_id, mes);

-- Renda e orçamento: uma linha por pessoa; "meses" guarda os valores de cada mês
-- no formato {"2026-10": {"renda": 4500, "orcamento": 3000}}.
create table if not exists public.gastos_config (
  user_id          uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  renda_padrao     numeric(12,2),
  orcamento_padrao numeric(12,2),
  meses            jsonb not null default '{}'::jsonb,
  atualizado_em    timestamptz not null default now()
);

alter table public.gastos        enable row level security;
alter table public.gastos_config enable row level security;

drop policy if exists "gastos: dono" on public.gastos;
create policy "gastos: dono" on public.gastos
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "config: dono" on public.gastos_config;
create policy "config: dono" on public.gastos_config
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update, delete on public.gastos        to authenticated;
grant select, insert, update, delete on public.gastos_config to authenticated;
