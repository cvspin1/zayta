-- Supabase > SQL Editor > New query > colle tout > Run

create table products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price numeric not null check (price >= 0),
  image_url text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table orders (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete set null,
  product_name text,
  quantity int not null default 1 check (quantity between 1 and 20),
  total numeric,
  customer_name text not null,
  phone text not null,
  city text not null,
  address text not null,
  status text not null default 'Nouvelle',
  created_at timestamptz not null default now()
);

-- Le prix et le nom du produit sont fixés côté serveur (le client ne peut pas les modifier)
create function set_order_totals() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  select name, price * new.quantity into new.product_name, new.total from products where id = new.product_id;
  if new.product_name is null then raise exception 'produit introuvable'; end if;
  if auth.role() <> 'authenticated' then new.status := 'Nouvelle'; end if;
  return new;
end $$;
create trigger orders_totals before insert on orders for each row execute function set_order_totals();

alter table products enable row level security;
alter table orders enable row level security;

create policy "public voit les produits actifs" on products for select using (active or auth.role() = 'authenticated');
create policy "admin gère les produits" on products for all to authenticated using (true) with check (true);
create policy "tout le monde peut commander" on orders for insert to anon, authenticated with check (true);
create policy "admin voit les commandes" on orders for select to authenticated using (true);
create policy "admin modifie les commandes" on orders for update to authenticated using (true) with check (true);
create policy "admin supprime les commandes" on orders for delete to authenticated using (true);

-- Photos des produits
insert into storage.buckets (id, name, public) values ('products', 'products', true);
create policy "admin envoie des photos" on storage.objects for insert to authenticated with check (bucket_id = 'products');
create policy "admin modifie des photos" on storage.objects for update to authenticated using (bucket_id = 'products');
create policy "admin supprime des photos" on storage.objects for delete to authenticated using (bucket_id = 'products');

-- Produits de départ (change les prix dans le dashboard)
insert into products (name, description, price, image_url) values
('Huile capillaire nourrissante', '100 % naturelle, 100 ml. Quelques gouttes sur le cuir chevelu et les pointes.', 100, 'assets/oil.jpg'),
('Beurre capillaire fouetté', '100 % naturel, 150 g. À lisser sur les longueurs pour des cheveux doux et brillants.', 120, 'assets/butter.jpg');

-- ===== Suivi des visiteurs, statistiques et commandes en direct =====
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

-- Pack Duo
insert into products (name, description, price, image_url) values
('Pack Duo : huile + beurre capillaire', 'Le duo complet : huile capillaire nourrissante 100 ml + beurre capillaire fouetté 150 g, 100 % naturels. Prix réduit.', 200, 'assets/duo.jpg');
