-- Cadence — schéma Supabase (à exécuter UNE FOIS dans SQL Editor)
-- Tableau de bord Supabase → icône "SQL Editor" (terminal) → coller → Run.

create table public.tasks (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title      text not null,
  type       text not null default 'tache',
  date       date,
  time       text,
  xp         int  not null default 10,
  done       boolean not null default false,
  done_at    bigint,
  created_at bigint
);

create table public.profile (
  user_id       uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  xp            int not null default 0,
  streak        int not null default 0,
  last_done_day text
);

-- Sécurité : chaque utilisateur ne voit et ne modifie que SES données.
alter table public.tasks   enable row level security;
alter table public.profile enable row level security;

create policy "own tasks" on public.tasks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own profile" on public.profile
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
