-- Catálogo administrable desde la PWA de Yosef Origen.
create table if not exists public.store_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.store_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint store_categories_name_not_blank check (length(trim(name)) > 0)
);

create table if not exists public.store_products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sku text unique,
  price numeric(10, 2) not null default 0 check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  description text not null default '',
  category_id uuid references public.store_categories(id) on delete set null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint store_products_name_not_blank check (length(trim(name)) > 0)
);

create table if not exists public.store_product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.store_products(id) on delete cascade,
  name text not null,
  sku text unique,
  price numeric(10, 2) check (price is null or price >= 0),
  stock integer not null default 0 check (stock >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint store_product_variants_name_not_blank check (length(trim(name)) > 0)
);

-- Los costos quedan en tablas privadas para que nunca se expongan al catálogo público.
create table if not exists public.store_product_costs (
  product_id uuid primary key references public.store_products(id) on delete cascade,
  cost numeric(10, 2) not null default 0 check (cost >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.store_product_variant_costs (
  variant_id uuid primary key references public.store_product_variants(id) on delete cascade,
  cost numeric(10, 2) not null check (cost >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.store_product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.store_products(id) on delete cascade,
  storage_path text not null unique,
  alt_text text not null default '',
  position integer not null default 0 check (position >= 0),
  created_at timestamptz not null default now()
);

create index if not exists store_products_category_idx
  on public.store_products (category_id);
create index if not exists store_products_active_name_idx
  on public.store_products (is_active, name);
create index if not exists store_product_variants_product_idx
  on public.store_product_variants (product_id);
create index if not exists store_product_images_product_position_idx
  on public.store_product_images (product_id, position);

alter table public.store_admins enable row level security;
alter table public.store_categories enable row level security;
alter table public.store_products enable row level security;
alter table public.store_product_variants enable row level security;
alter table public.store_product_images enable row level security;
alter table public.store_product_costs enable row level security;
alter table public.store_product_variant_costs enable row level security;

revoke all on public.store_admins from anon, authenticated;
revoke all on public.store_categories from anon, authenticated;
revoke all on public.store_products from anon, authenticated;
revoke all on public.store_product_variants from anon, authenticated;
revoke all on public.store_product_images from anon, authenticated;
revoke all on public.store_product_costs from anon, authenticated;
revoke all on public.store_product_variant_costs from anon, authenticated;

-- El permiso SQL permite evaluar las políticas; RLS no devuelve filas a visitantes.
grant select on public.store_admins to anon, authenticated;
grant select on public.store_categories, public.store_products,
  public.store_product_variants, public.store_product_images to anon, authenticated;
grant insert, update, delete on public.store_categories, public.store_products,
  public.store_product_variants, public.store_product_images to authenticated;
grant select, insert, update, delete on public.store_product_costs,
  public.store_product_variant_costs to authenticated;

create policy "Cada administrador consulta su propia cuenta"
  on public.store_admins for select to authenticated
  using (user_id = (select auth.uid()));

create policy "El público consulta categorías activas"
  on public.store_categories for select to anon, authenticated
  using (is_active or exists (
    select 1 from public.store_admins a where a.user_id = (select auth.uid())
  ));
create policy "Administradores gestionan categorías"
  on public.store_categories for all to authenticated
  using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

create policy "El público consulta artículos activos"
  on public.store_products for select to anon, authenticated
  using (is_active or exists (
    select 1 from public.store_admins a where a.user_id = (select auth.uid())
  ));
create policy "Administradores gestionan artículos"
  on public.store_products for all to authenticated
  using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

create policy "El público consulta variantes de artículos activos"
  on public.store_product_variants for select to anon, authenticated
  using (
    (is_active and exists (
      select 1 from public.store_products p
      where p.id = product_id and p.is_active
    )) or exists (
      select 1 from public.store_admins a where a.user_id = (select auth.uid())
    )
  );
create policy "Administradores gestionan variantes"
  on public.store_product_variants for all to authenticated
  using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

create policy "El público consulta fotos de artículos activos"
  on public.store_product_images for select to anon, authenticated
  using (exists (
    select 1 from public.store_products p
    where p.id = product_id and p.is_active
  ) or exists (
    select 1 from public.store_admins a where a.user_id = (select auth.uid())
  ));
create policy "Administradores gestionan fotos"
  on public.store_product_images for all to authenticated
  using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

create policy "Solo administradores consultan costos de artículos"
  on public.store_product_costs for select to authenticated
  using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));
create policy "Solo administradores insertan costos de artículos"
  on public.store_product_costs for insert to authenticated
  with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));
create policy "Solo administradores actualizan costos de artículos"
  on public.store_product_costs for update to authenticated
  using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));
create policy "Solo administradores borran costos de artículos"
  on public.store_product_costs for delete to authenticated
  using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

create policy "Solo administradores consultan costos de variantes"
  on public.store_product_variant_costs for select to authenticated
  using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));
create policy "Solo administradores insertan costos de variantes"
  on public.store_product_variant_costs for insert to authenticated
  with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));
create policy "Solo administradores actualizan costos de variantes"
  on public.store_product_variant_costs for update to authenticated
  using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));
create policy "Solo administradores borran costos de variantes"
  on public.store_product_variant_costs for delete to authenticated
  using (exists (select 1 from public.store_admins a where a.user_id = (select auth.uid())));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'yosef-product-images',
  'yosef-product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/avif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Administradores suben fotos de artículos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'yosef-product-images'
    and exists (select 1 from public.store_admins a where a.user_id = (select auth.uid()))
  );
create policy "Administradores actualizan fotos de artículos"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'yosef-product-images'
    and exists (select 1 from public.store_admins a where a.user_id = (select auth.uid()))
  )
  with check (
    bucket_id = 'yosef-product-images'
    and exists (select 1 from public.store_admins a where a.user_id = (select auth.uid()))
  );
create policy "Administradores borran fotos de artículos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'yosef-product-images'
    and exists (select 1 from public.store_admins a where a.user_id = (select auth.uid()))
  );
