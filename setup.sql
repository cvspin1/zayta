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
insert into products (name, description, price) values
('Huile capillaire nourrissante', '100 % naturelle, 100 ml. Quelques gouttes sur le cuir chevelu et les pointes.', 100),
('Beurre capillaire fouetté', '100 % naturel, 150 g. À lisser sur les longueurs pour des cheveux doux et brillants.', 120);
