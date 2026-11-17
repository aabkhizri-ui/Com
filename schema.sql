-- Aab-e-Khizri: Supabase schema (v1)
-- Run this in Supabase SQL Editor. Row Level Security policies come in the next step.

create extension if not exists "pgcrypto";

-- ROLES AND PROFILES
create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique,               -- links to auth.users when Supabase Auth is used
  role text not null check (role in ('admin','user','employer','order_booker','shopkeeper')),
  login_id text unique,                   -- ID for admin, user, employer, order booker
  phone text unique,                      -- mobile number for shopkeeper
  name text not null,
  designation text,
  created_by uuid references profiles(id),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- SHOPS (registered by order booker or shopkeeper, approved by admin)
create table if not exists shops (
  id uuid primary key default gen_random_uuid(),
  shopkeeper_id uuid references profiles(id),
  registered_by uuid references profiles(id),
  shopkeeper_name text not null,
  shop_name text not null,
  shop_phone text not null,
  shop_address text not null,
  latitude double precision not null,
  longitude double precision not null,
  image_path text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  approved_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- OUTLET ASSIGNMENTS (admin or user assigns shops to order booker)
create table if not exists outlet_assignments (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id),
  shop_id uuid not null references shops(id),
  assigned_by uuid references profiles(id),
  unique (profile_id, shop_id)
);

-- PRODUCTS AND PACKS
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  image_path text,
  active boolean not null default true,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists packs (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,              -- '6+2' or '12+4'
  paid_qty int not null,
  free_qty int not null,
  price numeric(12,2) not null,
  tokens_per_pack int not null default 0,
  active boolean not null default true
);

create table if not exists bulk_rates (
  id uuid primary key default gen_random_uuid(),
  min_qty int not null,
  price_per_bottle numeric(12,2) not null,
  active boolean not null default true
);

-- PROMO AND OFFERS (admin switches on or off)
create table if not exists promos (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  active boolean not null default false,
  created_at timestamptz not null default now()
);

-- ORDERS
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  invoice_no text unique not null,
  shop_id uuid references shops(id),
  placed_by uuid references profiles(id),
  placed_role text not null check (placed_role in ('shopkeeper','order_booker','admin','user')),
  status text not null default 'pending_approval' check (status in (
    'payment_pending','pending_approval','approved','dispatched','shipping','delivered','cancelled'
  )),
  total_amount numeric(12,2) not null default 0,
  paid_amount numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  product_id uuid references products(id),
  pack_id uuid references packs(id),
  bulk_rate_id uuid references bulk_rates(id),
  quantity int not null,
  unit_price numeric(12,2) not null,
  line_total numeric(12,2) not null
);

-- ADVANCE PAYMENTS (screenshot required for shopkeeper, OCR check, admin quick alert)
create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  amount numeric(12,2) not null,
  reference_no text unique not null,
  screenshot_path text,
  paid_by uuid references profiles(id),
  ocr_amount numeric(12,2),
  ocr_reference text,
  ocr_match boolean,
  status text not null default 'pending' check (status in ('pending','verified','rejected')),
  verified_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- DISPATCH (employer creates from selected invoices)
create table if not exists dispatches (
  id uuid primary key default gen_random_uuid(),
  dispatch_no text unique not null,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists dispatch_orders (
  dispatch_id uuid references dispatches(id) on delete cascade,
  order_id uuid references orders(id) on delete cascade,
  primary key (dispatch_id, order_id)
);

-- TOKEN (NOOR COINS) CLAIMS: delivery + payment clear + photo + review, then auto-check and admin approval
create table if not exists token_claims (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id),
  submitted_by uuid references profiles(id),
  photo_path text not null,
  review_text text,
  rating int check (rating between 1 and 5),
  invoice_match boolean,                  -- system check: invoice number in photo matches order
  status text not null default 'pending_admin' check (status in ('auto_rejected','pending_admin','approved','rejected')),
  coins_awarded int not null default 0,
  decided_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- NOOR COINS LEDGER (1 coin = Rs 1)
create table if not exists noor_coin_ledger (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid references shops(id),
  amount int not null,
  source_claim_id uuid references token_claims(id),
  created_at timestamptz not null default now()
);

-- KHIZR REWARDS (non-discount reward program, admin controls)
create table if not exists khizr_rewards (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  required_bottles int not null,
  benefit text not null,
  active boolean not null default false
);

-- ATTENDANCE AND KPIs (order booker)
create table if not exists attendance (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id),
  kind text not null check (kind in ('check_in','check_out','leave')),
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now()
);

-- SETTINGS (account number, etc.)
create table if not exists settings (
  key text primary key,
  value text not null,
  updated_by uuid references profiles(id),
  updated_at timestamptz not null default now()
);

-- NOTIFICATIONS (admin and shopkeeper alerts)
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  to_profile uuid references profiles(id),
  message text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;
alter table shops enable row level security;
alter table orders enable row level security;
alter table payments enable row level security;
alter table token_claims enable row level security;
-- Policies for each role are added in the next step.
