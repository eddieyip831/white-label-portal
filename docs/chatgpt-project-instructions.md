# ChatGPT Project Instructions (Short Version, <8000 chars)

## 1. Project identity & goals

- You are helping build a **white‑label SaaS portal** based on **MakerKit + Next.js 15 + Supabase**.
- The app is **multi‑tenant**, **self‑service**, and role/tier‑based:
  - **Tenants** represent organisations (plus a special “Unassigned Tenant” for self‑sign‑ups).
  - **Tiers** (plans): `free`, `pro`, `enterprise`.
  - **Roles**: `member`, `admin`, `super_admin` (defined in Supabase; rarely changed via UI).
  - **Functions & function groups** drive navigation / permissions (A/B/C groups for now).
- Long‑term priority: clean architecture, minimal BAU admin, and safe migrations (no “quick hacks”).

When unsure, favour **long‑term maintainability** over shortcuts.

---

## 2. Repo & route structure (what you can assume)

Monorepo root: `portal/`

Web app:

- Root app: `apps/web/app/`
- **Route groups**
  - `(app)` → authenticated app shell (header + optional sidebar)
  - `(auth)` → auth flows
- Typical structure (simplified):
  - `apps/web/app/layout.tsx` → **global root layout** (html/body, RootProviders, global CSS).
  - `apps/web/app/(app)/layout.tsx` → **authenticated shell** (AppShell, header, etc.).
  - `apps/web/app/(app)/home/` → logged‑in landing page.
  - `apps/web/app/(app)/admin/` → admin area (sidebar, CRUD).
  - `apps/web/app/auth/*` → login/register/forgot/reset.
  - `apps/web/app/legal/*` → privacy/terms.
  - `apps/web/app/public/*` → public marketing pages (e.g. About, Blog, etc. later).

**Never** introduce new top‑level route groups without a reason; follow this pattern.

---

## 3. Path aliases & imports (critical)

Use the **MakerKit aliases** consistently:

- `~/app/*` → `apps/web/app/*`
- `~/components/*` → `apps/web/components/*`
- `~/lib/*` → `apps/web/lib/*`
- `~/modules/*` → `apps/web/modules/*`
- `~/styles/*` → `apps/web/styles/*`
- `@/*` → `apps/web/*` (secondary alias)

**Do NOT** use:

- `@supabase/auth-helpers-react`
- `@supabase/auth-helpers-nextjs`

Instead, use existing MakerKit helpers and hooks (examples, not exhaustive):

- `@kit/supabase/hooks/use-user`
- `@kit/supabase/hooks/use-session`
- `~/lib/supabase/server`
- `~/lib/auth/claims`
- `~/components/layout/AppShell`
- `~/components/layout/AppHeaderAuth`
- `~/components/personal-account-dropdown-container`

If you see old imports (e.g. `@supabase/auth-helpers-react`), replace them with MakerKit equivalents, not new libraries.

---

## 4. Layout & nav rules

### 4.1 Global layout

- `apps/web/app/layout.tsx`:
  - Must contain `<html>` and `<body>`.
  - Imports global CSS via `import '~/styles/globals.css';`.
  - Wraps the app with `RootProviders` and any global UI (e.g. `Toaster`).

Do **not** move html/body into other files.

### 4.2 Authenticated layout (AppShell)

- `apps/web/app/(app)/layout.tsx`:
  - Server component.
  - Fetches claims/user, then renders `<AppShell>{children}</AppShell>`.
- `AppShell`:
  - Renders **in this order**:
    1. App header (with authenticated navigation, About/Blog links, user menu).
    2. Optional admin sidebar **only** for admin routes.
    3. Main content area.

If you add a sidebar, it must sit **below the header**, not above or outside it.

### 4.3 Public vs authenticated

- Routes under `(app)` require authentication and should **not** be reachable when logged out.
- Public routes:
  - `/`, `/auth/*`, `/legal/*`, `/public/*` (and future marketing pages).
  - Must not show the authenticated sidebar; if a public header is needed, use the existing public header components.

---

## 5. Auth, roles & tiers

- Roles & tiers are enforced on the server using utilities such as:
  - `~/lib/auth/claims`
  - `~/lib/auth/guards` (e.g. `requireRole('admin')`).
- Admin‑only pages **must** use a server‑side guard or claims check. If access fails, redirect or show a 403, not a silent error.
- For navigation:
  - Only show **functions** the current user is allowed to access (based on tier + roles).
  - Free tier → Group A only.
  - Pro tier → Groups A + B.
  - Enterprise → A + B + C (including admin features, if role permits).

Do not hard‑code “every menu for everyone”; always think in terms of **tier & role‑aware menus**.

---

## 6. Admin area conventions

Admin is for **platform operators** (super‑admin/admin), not normal end‑users.

- Route: `apps/web/app/(app)/admin/...`
- Must:
  - Run behind `requireRole('admin' | 'super_admin')` (or equivalent).
  - Use the **admin sidebar** for navigation between:
    - Tenants & tenant members
    - Users
    - (Future) tiers, functions, attributes, modules, etc.
- CRUD screens should:
  - Rely on typed Supabase client with generated `database.types.ts`.
  - Avoid bypassing central auth/claims logic.

If you add new admin CRUD, follow the existing patterns in `apps/web/app/admin/*` and shared components.

---

## 7. Supabase & database rules

- Types are generated with:

  ```bash
  supabase gen types typescript --project-id <project-id> > apps/web/lib/supabase/database.types.ts
  ```

- Always update queries to match the **current** DB schema (no hot‑patching types).
- We have a role/tier/function structure:
  - `tenants`, `tiers`, `roles`, `functions`, `function_groups`, `tier_functions`, `user_roles`, `user_tiers`, `user_profile`.
- Avoid “quick” schema changes that reintroduce known problems (e.g. duplicated fields like `code`/`slug`/`name` that we already cleaned up).

When proposing SQL, keep it idempotent where possible and call out any destructive operations.

---

## 8. File‑tree & baseline discipline

We maintain a **baseline file‑tree snapshot**:

- Baseline: `docs/system/file-tree-baseline.txt`
- Current snapshot: `docs/system/file-tree-current.txt`
- Validation script: `bash scripts/validate-file-tree.sh`

When suggesting structural changes (moving/renaming folders):

1. First, generate a **plan** and make sure it won’t break Next.js routing.
2. Use `find`‑based scripts and always show **before & after** trees.
3. After changes, re‑run `bash scripts/validate-file-tree.sh` and update `file-tree-baseline.txt` **only when the new structure is stable and intentional**.

Be very careful with shell scripts that refer to paths containing parentheses; use **quoted paths** and/or `find -maxdepth ... -type d` patterns.

---

## 9. How to interact with the user

- The user is comfortable with shell, Node, pnpm, Supabase, and IRL dev‑ops details.
- They prefer:
  - **No “quick hacks”** that will need rework.
  - Scripts that can be copy‑pasted and run in `zsh` on macOS.
  - Clear **pre‑check / post‑check** steps (e.g. listing directories, running SQL verification).
- If something is ambiguous but progress is possible, make a **reasonable assumption**, state it briefly, and continue; avoid stalling on small clarifications.

---

## 10. Things to avoid

- Re‑introducing auth‑helper libs that MakerKit does not use.
- Creating new route groups without checking the existing structure.
- Ignoring the `tsconfig` path aliases.
- Breaking `html/body` placement in `app/layout.tsx`.
- Showing admin sidebar or authenticated header on public pages.

Follow these as hard constraints unless the user explicitly decides to change the architecture.
