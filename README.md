# Aab-e-Khizri (v1 build)

## Files
- app.html: role select, five logins (Admin, User, Employer, Order Booker, Shopkeeper), forgot password, change password, role home screens with menu tabs. Demo mode, no database yet.
- admin_panel_v1.html: earlier admin panel page (login, main bar, sidebar, account number demo).
- logo.png: your logo, used unchanged on all screens.
- schema.sql: Supabase tables (run in SQL Editor).

## Demo accounts (remove before going live)
- Admin: admin001 / admin123
- User: user001 / user123
- Employer: emp001 / emp123
- Order Booker: booker001 / book123
- Shopkeeper: 03001234567 / shop123

## Forgot password
No SMS. User submits a new password from the Forgot Password screen; the request goes to Admin > Approval. Admin approves (password changes) or rejects.

## Login letters (login screen)
Admin = A, User = U, Employer = E. Order Booker and Shopkeeper have no letter.

## Policies
- policies_review.html: open in browser, approve or reject each role's rules.
- policies_draft.sql: DRAFT ONLY, not applied. Needs Supabase Auth login link first.

## Not done yet
- Supabase connection (Auth, forgot password by email/SMS, real data).
- Row Level Security policies per role.
- Screens inside each tab (orders, approvals, dispatch, printing, attendance, KPIs, tokens, shop registration, product images).
- Print slips, offline mode (PWA), token claim flow.

## Going live
1. Create Supabase project, run schema.sql.
2. Share Project URL and anon key.
3. Remove demo accounts.


## Direct links (hash routes)
- index.html#admin: Admin login
- index.html#user: User login
- index.html#employer: Employer login
- index.html#booker: Order Booker login
- index.html#shopkeeper: Shopkeeper login
All links open inside the same site and share the same app.
