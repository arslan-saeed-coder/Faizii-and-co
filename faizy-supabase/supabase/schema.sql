-- FAIZY & CO — Supabase schema. Paste the whole file into Supabase → SQL Editor → Run. Safe to re-run.

-- ============ settings & admins ============
create table if not exists public.settings (
  id int primary key default 1 check (id = 1),
  delivery_charge int not null default 250 check (delivery_charge >= 0),   -- placeholder until you confirm
  whatsapp text not null default '923241995778'
);
insert into public.settings default values on conflict do nothing;

create table if not exists public.admins (user_id uuid primary key references auth.users on delete cascade);

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid())
$$;
create or replace function public.am_i_admin() returns boolean
language sql stable security definer set search_path = public as $$ select public.is_admin() $$;

-- ============ products ============
create or replace function public.valid_urls(u text[]) returns boolean
language sql immutable as $$
  select coalesce(bool_and(x ~ '^https://[^\s''"<>]+$'), true) and coalesce(cardinality(u), 0) <= 8 from unnest(u) x
$$;

create table if not exists public.products (
  id text primary key default ('p-' || substr(md5(random()::text || clock_timestamp()::text), 1, 8)),
  name text not null check (length(name) between 1 and 120),
  category text not null check (category in ('tshirts','watches','lockets','combos')),
  description text not null default '' check (length(description) <= 1000),
  price int not null check (price >= 0),
  stock int not null default 0 check (stock >= 0),
  sizes text[] not null default '{}' check (cardinality(sizes) <= 10),
  images text[] not null default '{}' check (public.valid_urls(images)),
  featured boolean not null default false,
  active boolean not null default true,
  color text not null default '#15181d' check (color ~ '^#[0-9a-fA-F]{6}$'),
  art text not null default 'tee' check (art in ('tee','watch','locket','chain','combo')),
  created_at timestamptz not null default now()
);

-- ============ orders ============
create table if not exists public.orders (
  ref text primary key,
  created_at timestamptz not null default now(),
  name text not null, phone text not null, city text not null, address text not null,
  notes text not null default '',
  items jsonb not null,
  subtotal int not null, delivery int not null, total int not null,
  status text not null default 'pending' check (status in ('pending','confirmed','shipped','delivered','cancelled'))
);
create index if not exists orders_created_idx on public.orders (created_at desc);

-- ============ row level security ============
alter table public.settings enable row level security;
alter table public.admins   enable row level security;
alter table public.products enable row level security;
alter table public.orders   enable row level security;
revoke all on public.admins from anon, authenticated;

drop policy if exists "settings read" on public.settings;
create policy "settings read" on public.settings for select using (true);
drop policy if exists "settings admin update" on public.settings;
create policy "settings admin update" on public.settings for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "products read" on public.products;
create policy "products read" on public.products for select using (active or public.is_admin());
drop policy if exists "products admin insert" on public.products;
create policy "products admin insert" on public.products for insert to authenticated with check (public.is_admin());
drop policy if exists "products admin update" on public.products;
create policy "products admin update" on public.products for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "products admin delete" on public.products;
create policy "products admin delete" on public.products for delete to authenticated using (public.is_admin());

-- orders: only admins can read/change; customers can only place orders through place_order() below
drop policy if exists "orders admin read" on public.orders;
create policy "orders admin read" on public.orders for select to authenticated using (public.is_admin());

-- ============ place_order(): validates, locks stock, saves order — all in one transaction ============
create or replace function public.place_order(p jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_name text := btrim(coalesce(p->>'name', ''));
  v_phone text := btrim(coalesce(p->>'phone', ''));
  v_city text := btrim(coalesce(p->>'city', ''));
  v_addr text := btrim(coalesce(p->>'address', ''));
  v_notes text := left(btrim(coalesce(p->>'notes', '')), 500);
  v_items jsonb := p->'items';
  it jsonb; pr public.products;
  v_id text; v_size text; v_qty int;
  v_lines jsonb := '[]'::jsonb; v_sub int := 0; v_delivery int; v_ref text;
begin
  if length(v_name) < 2 or length(v_name) > 100 then raise exception 'Please enter your full name.'; end if;
  if regexp_replace(v_phone, '[\s-]', '', 'g') !~ '^(\+?92|0)?3[0-9]{9}$' then raise exception 'Enter a valid Pakistani mobile number.'; end if;
  if v_city = '' or length(v_city) > 80 then raise exception 'Please enter your city.'; end if;
  if length(v_addr) < 8 or length(v_addr) > 400 then raise exception 'Please enter your complete delivery address.'; end if;
  if jsonb_typeof(v_items) is distinct from 'array' or jsonb_array_length(v_items) not between 1 and 30 then
    raise exception 'Your cart is empty.';
  end if;
  if (select count(*) from public.orders
        where right(regexp_replace(phone, '\D', '', 'g'), 10) = right(regexp_replace(v_phone, '\D', '', 'g'), 10)
          and created_at > now() - interval '1 hour') >= 5 then
    raise exception 'Too many orders from this number. Please try again later.';
  end if;

  -- lock every product in the cart in a fixed order (prevents overselling and deadlocks)
  perform 1 from public.products
    where id in (select e->>'id' from jsonb_array_elements(v_items) e) order by id for update;

  for it in select * from jsonb_array_elements(v_items) loop
    v_id := it->>'id'; v_size := btrim(coalesce(it->>'size', ''));
    if jsonb_typeof(it->'qty') is distinct from 'number' or (it->>'qty') !~ '^[0-9]{1,2}$' then raise exception 'Invalid item in your cart.'; end if;
    v_qty := (it->>'qty')::int;
    if v_qty < 1 or v_qty > 20 then raise exception 'Invalid item in your cart.'; end if;
    select * into pr from public.products where id = v_id and active;
    if not found then raise exception 'A product in your cart is no longer available.'; end if;
    if cardinality(pr.sizes) > 0 and not (v_size = any (pr.sizes)) then raise exception 'Please choose a size for %.', pr.name; end if;
    if pr.stock < v_qty then raise exception 'Sorry, only % left of %.', pr.stock, pr.name; end if;
    update public.products set stock = stock - v_qty where id = pr.id;
    v_lines := v_lines || jsonb_build_array(jsonb_build_object(
      'id', pr.id, 'name', pr.name, 'size', case when cardinality(pr.sizes) > 0 then v_size else '' end,
      'qty', v_qty, 'price', pr.price, 'sub', pr.price * v_qty));
    v_sub := v_sub + pr.price * v_qty;
  end loop;

  select delivery_charge into v_delivery from public.settings where id = 1;
  v_ref := 'FC-' || upper(to_hex(extract(epoch from clock_timestamp())::bigint)) || upper(substr(md5(random()::text), 1, 4));
  insert into public.orders(ref, name, phone, city, address, notes, items, subtotal, delivery, total)
    values (v_ref, v_name, v_phone, v_city, v_addr, v_notes, v_lines, v_sub, v_delivery, v_sub + v_delivery);
  return jsonb_build_object('ref', v_ref, 'lines', v_lines, 'subtotal', v_sub, 'delivery', v_delivery, 'total', v_sub + v_delivery);
end $$;

-- ============ set_order_status(): admin only; cancelling puts stock back ============
create or replace function public.set_order_status(p_ref text, p_status text) returns void
language plpgsql security definer set search_path = public as $$
declare o public.orders;
begin
  if not public.is_admin() then raise exception 'Not allowed.' using errcode = '42501'; end if;
  if p_status not in ('pending','confirmed','shipped','delivered','cancelled') then raise exception 'Invalid status.'; end if;
  select * into o from public.orders where ref = p_ref for update;
  if not found then raise exception 'Order not found.'; end if;
  if o.status = 'cancelled' and p_status <> 'cancelled' then raise exception 'Cancelled orders can''t be reopened.'; end if;
  if p_status = 'cancelled' and o.status <> 'cancelled' then
    update public.products pr set stock = pr.stock + x.q
      from (select l->>'id' as id, sum((l->>'qty')::int) as q from jsonb_array_elements(o.items) l group by 1) x
      where pr.id = x.id;
  end if;
  update public.orders set status = p_status where ref = p_ref;
end $$;

revoke all on function public.place_order(jsonb), public.set_order_status(text, text), public.am_i_admin() from public, anon, authenticated;
grant execute on function public.place_order(jsonb) to anon, authenticated;
grant execute on function public.set_order_status(text, text) to authenticated;
grant execute on function public.am_i_admin() to anon, authenticated;

-- ============ product photos (public bucket, admin-only uploads) ============
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 3000000, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;
drop policy if exists "product images read" on storage.objects;
create policy "product images read" on storage.objects for select using (bucket_id = 'product-images');
drop policy if exists "product images admin insert" on storage.objects;
create policy "product images admin insert" on storage.objects for insert to authenticated with check (bucket_id = 'product-images' and public.is_admin());
drop policy if exists "product images admin update" on storage.objects;
create policy "product images admin update" on storage.objects for update to authenticated using (bucket_id = 'product-images' and public.is_admin());
drop policy if exists "product images admin delete" on storage.objects;
create policy "product images admin delete" on storage.objects for delete to authenticated using (bucket_id = 'product-images' and public.is_admin());
