# File Tree Baseline — apps/web

> Baseline generated after route reorganisation on 2025-12-01.  
> This describes both **current reality** and how routes are **intended to be structured** going forward.  
> The app is **white-label**: public content (About, Blog, etc.) and branding are expected to be replaced per tenant over time.

## 1. High-level layout

```text
apps/web/app
├─ layout.tsx                # Root layout — wraps ALL routes
├─ (app)/                    # Authenticated application area
│  ├─ layout.tsx             # AppShell (header + app nav)
│  ├─ home/                  # /home — authenticated landing page
│  ├─ settings/              # /settings — authenticated settings pages
│  ├─ update-password/       # /update-password — in-app password change
│  └─ admin/                 # /admin — admin console (guarded)
│     ├─ layout.tsx          # AdminShell (sidebar)
│     ├─ users/              # Admin user management
│     └─ tenant-members/     # Admin tenant user management
├─ (auth)/                   # Route group for auth flows (MakerKit)
├─ auth/                     # /auth/* public auth pages
│  ├─ register/
│  ├─ forgot-password/
│  └─ reset-password/
├─ public/                   # Public marketing/static pages (white-label)
├─ legal/
│  ├─ privacy/               # /legal/privacy
│  └─ terms/                 # /legal/terms
├─ api/                      # API routes
│  ├─ health/                # /api/health
│  ├─ admin/                 # Legacy / internal admin api
│  └─ admin-api/             # Admin REST endpoints backing the UI
│     ├─ users/
│     ├─ roles/
│     ├─ permissions/
│     ├─ attributes/
│     ├─ modules/
│     └─ assign-roles/
├─ sitemap.xml/              # Dynamic sitemap route
└─ version/                  # /version — build info etc.
```

## 2. Route group conventions

- `(app)` — **authenticated** application shell  
  - Contains `/home`, `/settings`, `/update-password`, `/admin/*`.  
  - Uses `(app)/layout.tsx` which renders the **app header** and injects app-level props (claims, tiers, tenant, etc.).

- `(auth)` — **authentication** route group (used by MakerKit).

- Root `/app/layout.tsx`  
  - Global providers, `<html>/<body>`, theme, Toaster, QueryClientProvider, Supabase providers, etc.  
  - Does **not** directly render sidebars; those are done in child layouts.

## 3. Admin layout

Within `(app)/admin`:

- `(app)/admin/layout.tsx` wraps all admin pages in an `AdminShell` that:
  - Ensures the user has the correct role via `requireRole('admin')` (or similar).
  - Renders the **admin sidebar** with links: Users, Roles, Permissions, Attributes, Modules.
  - Renders `<main>` for the inner admin content.

Expected behaviour:

- Admin sidebar only appears on `/admin/*` routes.  
- Public routes and non-admin app routes should **never** show the admin sidebar.

## 4. Public vs Authenticated areas

- **Public pages** (`/`, `/auth/*`, `/legal/*`, `/public/*`):
  - Use the **public header** only.
  - **No sidebar** is shown.

- **Authenticated app pages** (`/home`, `/settings`, etc.):
  - Use `(app)/layout.tsx` → **AppShell**:
    - Top header with app logo/name + main navigation (Functions A/B/C by tier).
    - Optional app-level sidebar in the future (tier-driven).

- **Admin pages** (`/admin/*`):
  - Use **AppShell header** **plus** `AdminShell` sidebar.
  - Access is guarded by claims/roles.

## 5. How to detect drift

To compare the current file tree with this baseline, use the validation script:

```bash
bash scripts/validate-file-tree.sh
```

- It writes `docs/system/file-tree-current.txt`.
- If `docs/system/file-tree-baseline.txt` exists, it will `diff` against it.
- If it does not exist yet, you can initialise it with:

```bash
cp docs/system/file-tree-current.txt docs/system/file-tree-baseline.txt
```

From then on, any structural change will show up as a diff.
