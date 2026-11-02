# FAIZY & CO — Supabase version

```
frontend/   storefront (index.html, js/, css/) + admin panel (admin/)
supabase/   schema.sql (tables, security rules, order functions, photo bucket), seed.sql, make_admin.sql
```
No server and no functions to deploy: everything runs inside your Supabase database, and the website is plain static files.

## How it works
- **Products** are read from the database. Products you untick "Visible" on are hidden by the database rules (only the admin can see them).
- **Orders** go through one database function, `place_order()`. In a single transaction it validates the form, re-reads prices from the database (the browser can't change them), locks the products, checks stock, reduces stock and saves the order as `pending`. If anything fails, nothing is saved. Then WhatsApp opens with the order message; the customer must press **Send**.
- **Admin** (`/admin/`) logs in with a Supabase email + password. Only users listed in the `admins` table can see orders or change products. Cancelling an order puts the stock back.
- **Delivery charge and WhatsApp number** live in the `settings` table (Table Editor → settings). Change them there; no code edit needed.

## Setup (about 15 minutes)
1. **Create a project** at supabase.com (New project). Save the database password somewhere safe.
2. **Create the database.** SQL Editor → New query → paste all of `supabase/schema.sql` → Run. Then do the same with `supabase/seed.sql` (sample products — optional).
3. **Create your admin login.** Authentication → Users → Add user → email + strong password, tick *Auto Confirm User*. Then open `supabase/make_admin.sql`, put that same email in it, paste into the SQL Editor and Run.
4. **Close public sign-ups.** Authentication → Sign In / Providers (or Settings) → turn off "Allow new users to sign up". Only you need an account.
5. **Connect the website.** Project Settings → API: copy the **Project URL** and the **anon / publishable** key into `frontend/js/supabase-config.js`. Never use the `service_role` key anywhere in `frontend/`.
6. **Try it locally.** `cd frontend && python3 -m http.server 8000` → http://localhost:8000 and http://localhost:8000/admin/
7. **Go online.** Upload the `frontend` folder to any static host (Vercel, Netlify, Cloudflare Pages, GitHub Pages). No build command; the folder is the site. Admin is at `yourdomain/admin/`.

## Before you launch
- Replace the sample products and photos (admin panel → Add product / Edit; photos can be uploaded or pasted as `https://` links).
- Fill the footer placeholders (`[owner to add]`), social links in `js/config.js`, hero and banner photos.
- Confirm the real delivery charge in the `settings` table (default 250 is a placeholder).

## Known limits
- Anyone can call `place_order()`. It rejects invalid data and allows at most 5 orders per phone number per hour, but someone using many numbers could place fake `pending` orders that hold stock. Cancel them in admin (stock returns).
- Orders contain customers' names, phones and addresses; only admin users can read them. Keep the admin password strong and don't add other people to `admins` unless you trust them.
- Supabase's free plan has limits and may pause inactive projects. Check the current rules on their pricing page and keep backups (Table Editor → export).
- Pinned library: `@supabase/supabase-js@2.117.3` (loaded from jsDelivr).

## What was tested
The SQL ran on a real PostgreSQL 16 with Supabase's `auth`/`storage` parts mocked (`supabase/tests/`): validation, stock, rollback, price tampering, per-phone limit, hidden products, admin-only access, cancel restoring stock. The website code ran in a simulated browser with the real supabase-js against a stubbed API. It has **not** been run against your live Supabase project, and the photo-storage rules were only loaded, not exercised.
