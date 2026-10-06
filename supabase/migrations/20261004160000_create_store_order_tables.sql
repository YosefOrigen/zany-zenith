-- Tablas iniciales para guardar pedidos y consultar su seguimiento.
-- El sitio público no recibe permisos directos sobre estas tablas;
-- las compras y consultas se atenderán desde funciones seguras del servidor.

create table if not exists public.store_orders (
  id uuid primary key default gen_random_uuid(),
  tracking_token uuid not null unique default gen_random_uuid(),
  customer_name text not null,
  customer_phone text not null,
  delivery_address text not null,
  customer_notes text,
  payment_method text not null default 'cash_on_delivery'
    check (payment_method = 'cash_on_delivery'),
  status text not null default 'pending'
    check (status in ('pending', 'preparing', 'shipped', 'delivered', 'cancelled')),
  total numeric(10, 2) not null check (total >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.store_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.store_orders(id) on delete cascade,
  product_id text not null,
  product_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.store_order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.store_orders(id) on delete cascade,
  status text not null
    check (status in ('pending', 'preparing', 'shipped', 'delivered', 'cancelled')),
  note text,
  created_at timestamptz not null default now()
);

create index if not exists store_orders_created_at_idx
  on public.store_orders (created_at desc);
create index if not exists store_orders_tracking_token_idx
  on public.store_orders (tracking_token);
create index if not exists store_order_items_order_id_idx
  on public.store_order_items (order_id);
create index if not exists store_order_status_history_order_id_idx
  on public.store_order_status_history (order_id, created_at);

alter table public.store_orders enable row level security;
alter table public.store_order_items enable row level security;
alter table public.store_order_status_history enable row level security;

revoke all on public.store_orders from anon, authenticated;
revoke all on public.store_order_items from anon, authenticated;
revoke all on public.store_order_status_history from anon, authenticated;
