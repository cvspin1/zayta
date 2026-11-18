-- MISE À JOUR (si tu as déjà exécuté l'ancien setup.sql)
-- Supabase > SQL Editor > New query > colle tout > Run
-- Tu peux l'exécuter plusieurs fois sans problème.

-- 1) Suivi des visiteurs
create table if not exists events (
  id bigint generated always as identity primary key,
  session_id text not null check (char_length(session_id) <= 64),
  type text not null check (type in ('visit','product_view','order_start','whatsapp_click')),
  product_id uuid references products(id) on delete cascade,
  page text,
  device text,
  created_at timestamptz not null default now()
);
create index if not exists events_created_idx on events (created_at);
alter table events enable row level security;
drop policy if exists "tout le monde envoie des evenements" on events;
create policy "tout le monde envoie des evenements" on events for insert to anon, authenticated with check (true);
drop policy if exists "admin voit les evenements" on events;
create policy "admin voit les evenements" on events for select to authenticated using (true);

-- 2) Chiffres du dashboard (réservé à l'admin connecté)
create or replace function admin_stats(days int default 30) returns json
language plpgsql security definer set search_path = public as $$
declare since timestamptz := now() - make_interval(days => days); r json;
begin
  if auth.role() <> 'authenticated' then raise exception 'non autorisé'; end if;
  select json_build_object(
    'visitors', (select count(distinct session_id) from events where created_at > since),
    'today_visitors', (select count(distinct session_id) from events where (created_at at time zone 'Africa/Casablanca')::date = (now() at time zone 'Africa/Casablanca')::date),
    'viewers', (select count(distinct session_id) from events where type = 'product_view' and created_at > since),
    'order_starts', (select count(distinct session_id) from events where type = 'order_start' and created_at > since),
    'whatsapp', (select count(*) from events where type = 'whatsapp_click' and created_at > since),
    'orders', (select count(*) from orders where created_at > since and status <> 'Annulée'),
    'revenue', (select coalesce(sum(total), 0) from orders where created_at > since and status <> 'Annulée'),
    'top_products', (select coalesce(json_agg(t), '[]'::json) from (
        select p.name, count(*)::int as views from events e join products p on p.id = e.product_id
        where e.type = 'product_view' and e.created_at > since group by p.name order by views desc) t),
    'devices', (select coalesce(json_agg(t), '[]'::json) from (
        select device, count(distinct session_id)::int as n from events where created_at > since and device is not null group by device) t),
    'daily', (select coalesce(json_agg(t order by t.d), '[]'::json) from (
        select (created_at at time zone 'Africa/Casablanca')::date as d, count(distinct session_id)::int as v
        from events where created_at > since group by 1) t)
  ) into r;
  return r;
end $$;
revoke all on function admin_stats(int) from public, anon;
grant execute on function admin_stats(int) to authenticated;

-- 3) Commandes en direct dans le dashboard
do $$ begin
  alter publication supabase_realtime add table orders;
exception when duplicate_object then null;
end $$;

-- 4) Photos séparées + Pack Duo
update products set image_url = 'assets/oil.jpg'    where name = 'Huile capillaire nourrissante' and image_url is null;
update products set image_url = 'assets/butter.jpg' where name = 'Beurre capillaire fouetté'     and image_url is null;
insert into products (name, description, price, image_url)
select 'Pack Duo : huile + beurre capillaire',
       'Le duo complet : huile capillaire nourrissante 100 ml + beurre capillaire fouetté 150 g, 100 % naturels. Prix réduit.',
       200, 'assets/duo.jpg'
where not exists (select 1 from products where name like 'Pack Duo%');
