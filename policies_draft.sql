-- DRAFT ONLY. NOT APPLIED. Apply after approval and after login is linked to Supabase Auth.
-- Each policy assumes auth.uid() maps to profiles.auth_user_id and profiles.role.

create or replace function current_role_name() returns text
language sql stable security definer as $$
  select role from profiles where auth_user_id = auth.uid()
$$;

-- Admin: full access
create policy admin_all_profiles on profiles for all using (current_role_name() = 'admin') with check (current_role_name() = 'admin');
create policy admin_all_shops on shops for all using (current_role_name() = 'admin') with check (current_role_name() = 'admin');
create policy admin_all_orders on orders for all using (current_role_name() = 'admin') with check (current_role_name() = 'admin');
create policy admin_all_payments on payments for all using (current_role_name() = 'admin') with check (current_role_name() = 'admin');
create policy admin_all_claims on token_claims for all using (current_role_name() = 'admin') with check (current_role_name() = 'admin');
create policy admin_all_reset on reset_requests for all using (current_role_name() = 'admin') with check (current_role_name() = 'admin');

-- Public read: products and packs
alter table products enable row level security;
alter table packs enable row level security;
create policy public_read_products on products for select using (true);
create policy public_read_packs on packs for select using (true);

-- Shopkeeper: own shop, own orders, own payments, own claims
create policy shop_own_shop on shops for select using (shopkeeper_id = (select id from profiles where auth_user_id = auth.uid()));
create policy shop_own_orders on orders for select using (shop_id in (select id from shops where shopkeeper_id = (select id from profiles where auth_user_id = auth.uid())));

-- Order booker: assigned outlets and own attendance
create policy booker_assigned_shops on shops for select using (id in (select shop_id from outlet_assignments where profile_id = (select id from profiles where auth_user_id = auth.uid())));

-- Employer and user: shopkeeper orders (approved) and dispatch work
create policy employer_orders on orders for select using (current_role_name() in ('employer','user') and status in ('approved','dispatched','shipping','delivered'));
