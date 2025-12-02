# Base Framework Portal

Base Framework is a **white‑label, multi‑tenant SaaS foundation** built on **Next.js + Supabase**.  
It is designed to host multiple future products as **modules** with:

- Self‑service onboarding
- Tier‑driven roles & permissions
- Strong security using **Supabase RLS + JWT claims**
- Minimal BAU admin work
- PWA‑first UX

This repo is the **platform skeleton**, not a single app. New business ideas should be implemented as modules that plug into this foundation.

---

## 1. Core Concepts

### Multi‑tenant, self‑service SaaS

- **Tenants** represent organisations (plus a special “Unassigned Tenant” for self‑sign‑ups).
- **Tiers** (`free`, `pro`, `enterprise`) drive monetisation and access.
- **Roles** (`member`, `admin`, `super_admin`) are **system‑defined**, not tenant‑editable.
- Users **self‑register**, pick a tier (or default to `free`), and receive roles/permissions automatically.
- A small **admin console** exists for exceptional overrides and audit only.

### Modules first

Every new feature area should be a **module** that defines:

- Its own data model (tables + RLS)
- Any Edge Functions / API endpoints
- Next.js routes (pages, layouts)
- Admin oversight pages (under `/admin`)
- Permissions & navigation entries

Modules are **globally activatable** (via `modules` + permissions), not customised per tenant.

### Tier‑driven RBAC

- Permissions are globally defined and mapped to **tiers** and **roles**.
- Tiers → permissions → roles → users
- Supabase JWT **claims** include `tenant_id`, `tier`, `roles`, and `permissions` for RLS.

See `docs/system/db-schema-reference.md` for full details of the RBAC model and claims functions.

---

## 2. Tech Stack

### Backend / Platform

- **Supabase** (Postgres + Auth + RLS)
- Supabase functions for:
  - Building JWT claims (`build_claims`)
  - Applying claims to users (`apply_claims_to_user`)
  - Auto‑bootstrapping `user_profile` on signup
- RLS Everywhere: access is enforced in the database, not just in the UI.

### Frontend

- **Next.js 15** (App Router)
- **TypeScript**
- **Tailwind CSS**
- PWA‑first (service worker, offline‑aware UX)
- MakerKit‑style structure with path aliases.

### Admin

- Lives under: `apps/web/app/(app)/admin`
- Provides:
  - Tenant and user overview
  - Role/tier inspection
  - Rare super‑admin overrides

---

## 3. Repository Layout (High‑Level)

At the monorepo root (assumed: `portal/`):

```text
portal/
  apps/
    web/
      app/
        (app)/          # Authenticated app shell
        (auth)/         # Auth flows
        admin/          # Admin area (within (app))
        ...             # Other route groups & pages
      components/       # Shared UI components
      lib/              # Shared libraries (auth, supabase, utils)
      styles/
  docs/
    system/
      db-schema-baseline.sql      # Baseline DB dump
      db-schema-reference.md      # ER + data dictionary + functions/views
      chatgpt-project-instructions.md
      file-tree-baseline.txt      # Baseline file tree snapshot
      file-tree-current.txt       # Generated for validation
  scripts/
    validate-file-tree.sh         # Checks file tree vs baseline
```

> Any paths with parentheses (e.g. `apps/web/app/(app)`) must be quoted in zsh commands, e.g. `"apps/web/app/(app)"`.

### Path aliases

In the web app, use the MakerKit‑style aliases consistently:

- `~/app/*` → `apps/web/app/*`
- `~/components/*` → `apps/web/components/*`
- `~/lib/*` → `apps/web/lib/*`
- `~/modules/*` → `apps/web/modules/*`
- `~/styles/*` → `apps/web/styles/*`
- `@/*` → `apps/web/*`

Avoid `@supabase/auth-helpers-*`; use the existing MakerKit hooks and helpers instead.

---

## 4. Getting Started

### 4.1 Prerequisites

- Node.js (LTS)
- `pnpm` (preferred package manager)
- Supabase CLI
- Docker Desktop (for local Postgres/Supabase if running locally)

### 4.2 Setup

From the monorepo root (`portal/`):

```zsh
# Install dependencies
pnpm install

# Start Supabase locally (if using local stack)
supabase start

# Apply migrations & seed (adjust as needed)
supabase db reset

# Generate TypeScript types from the database
supabase gen types typescript   --project-id <project-id>   > apps/web/lib/supabase/database.types.ts
```

Set up environment variables (`.env.local`, `.env`) for:

- Supabase URL and anon/service keys
- Any Next.js app settings (e.g. NEXT_PUBLIC_SITE_URL)

Then run the web app:

```zsh
pnpm dev --filter web
```

The app should be available at `http://localhost:3000`.

---

## 5. Database & RLS

The database is managed via Supabase migrations and documented in:

- `docs/system/db-schema-baseline.sql` – baseline schema.
- `docs/system/db-schema-reference.md` – ER diagrams, data dictionary, functions, views.

Key tables:

- Core tenancy: `tenants`, `tiers`, `user_profile`, `tenant_members`
- RBAC: `roles`, `permissions`, `role_permissions`, `user_roles`, `tier_permissions`
- Navigation: `function_groups`, `functions`, `tier_functions`
- Modules: `modules`
- User metadata: `user_attribute_definitions`, `user_attributes`

Key functions:

- `public.build_claims(user_id uuid) → jsonb`
- `public.apply_claims_to_user(user_id uuid) → void`
- `public.get_user_permissions(user_id uuid)`
- `public.user_has_permission(user_id uuid, permission_name text) → boolean`
- `public.on_auth_user_created()` (trigger for `auth.users`)

Views:

- `public.tenant_members_admin` – denormalised view for admin consoles.

UUIDs are generated using:

```sql
id uuid DEFAULT gen_random_uuid() PRIMARY KEY
```

No manual sequences are required for UUIDs.

---

## 6. Development Conventions

- **RLS first, UI second**
  - All queries must respect tenant scoping (`tenant_id = auth.jwt().tenant_id` where applicable).
  - UI should never rely solely on client‑side checks for security.

- **Route groups**
  - `(app)` – authenticated shell (requires logged‑in user).
  - `(auth)` – login/register/forgot/reset flows.
  - Public routes (marketing, legal) live outside `(app)`.

- **Admin area**
  - All routes under `apps/web/app/(app)/admin` must be protected by server‑side guards (e.g. `requireRole('admin' | 'super_admin')`).
  - Use the shared admin layout/sidebar for all admin pages.

- **Modules**
  - New product areas should go under `~/modules/<module-name>` for code, plus matching DB objects and entries in `modules`, `permissions`, `functions`, and `tier_functions`.
  - Avoid tenant‑specific customisation; configuration should be **global**, with tiers driving variation.

- **File tree discipline**
  - Use `bash scripts/validate-file-tree.sh` to compare the current tree against `docs/system/file-tree-baseline.txt`.
  - Only update `file-tree-baseline.txt` when structural changes are intentional and stable.

---

## 7. Documentation

Core system docs live under `docs/system/`:

- `db-schema-reference.md` – **authoritative DB reference** (ER + data dictionary + functions/views).
- `chatgpt-project-instructions.md` – instructions for the ChatGPT architectural assistant.
- `file-tree-baseline.txt` – canonical file structure for validation.

You can render the Mermaid diagrams either:

- In VS Code using **Markdown Preview Mermaid Support**, or
- On GitHub (Mermaid support is built‑in), or
- Via any Markdown+Mermaid‑aware viewer in your browser.

---

## 8. Roadmap (High‑Level)

- Flesh out the **first real module** (e.g. Projects / CRM) using the module conventions.
- Implement PWA features (offline support, install prompts) as defaults.
- Add more admin views for:
  - Tier/role/permission mapping inspection
  - Module activation and feature flags
- Harden RLS policies and add test fixtures for critical tables.

---

## 9. Acknowledgements

This project is originally based on the
[MakerKit Next.js SaaS Starter Kit Lite](https://github.com/makerkit/nextjs-saas-starter-kit-lite)
and has been customised into a white-label multi-tenant portal.

---

## 10. License

TBD – choose and document the license appropriate for this project.
