# Portal Framework — Site Structure & Layout Specification

_(White-Label, Multi-Tenant, Tier-Based Navigation)_

This document defines the authoritative sitemap, layout hierarchy, navigation rules, and RBAC logic for the Portal Framework SaaS.

It ensures the project remains consistent, scalable, and modular.

---

# 💡 White-Label Principles

The platform is fully **white-label**, meaning:

- Branding (logo, colors, typography) can be replaced per tenant.
- About, Blog, FAQ, Terms, and Privacy pages may be customized or overridden.
- Navigation and feature suites are configuration-driven.
- Modules can be added or removed without code changes.

---

# 1. Layout Architecture

(unchanged; same as previous version)

---

# 2. Navigation Structure (Updated)

This section replaces the previous navigation rules.

## 2.1 Public Header Menu

Displayed on all unauthenticated pages:

```
Home | Pricing | About | Blog | FAQ | Login | Signup
```

## 2.2 Authenticated Header (Tier-Based Suite Only)

Users should **never** see all suites.  
They only see **the suite matching their tier**, containing all modules available to them.

### Free Tier

```
Home | About | Blog | Free Suite ▾ | User Menu
```

### Pro Tier

```
Home | About | Blog | Pro Suite ▾ | User Menu
```

### Enterprise Tier

```
Home | About | Blog | Enterprise Suite ▾ | User Menu
```

### Admin / Super-Admin (inherits Enterprise)

```
Home | About | Blog | Enterprise Suite ▾ | Admin ▾ | User Menu
```

> Admin always sees their own suite plus the Admin dropdown.

---

# 2.3 Suite Composition

Each suite is a logical grouping of modules.

### Free Suite

- Function A

### Pro Suite

- Function A
- Function B

### Enterprise Suite

- Function A
- Function B
- Function C

---

# 2.4 Suite Configuration (Centralized)

Suites and modules must be defined in a configuration file:

`config/modules.json`

```
{
  "suites": {
    "free": {
      "title": "Free Suite",
      "tier": "Free",
      "modules": ["functionA"]
    },
    "pro": {
      "title": "Pro Suite",
      "tier": "Pro",
      "modules": ["functionA", "functionB"]
    },
    "enterprise": {
      "title": "Enterprise Suite",
      "tier": "Enterprise",
      "modules": ["functionA", "functionB", "functionC"]
    }
  },
  "modules": {
    "functionA": { "title": "Function A", "path": "/function-a" },
    "functionB": { "title": "Function B", "path": "/function-b" },
    "functionC": { "title": "Function C", "path": "/function-c" }
  }
}
```

This ensures:

- Navigation updates require **no code changes**
- Suites auto-expand when new modules are added
- White-label tenants can override labels

---

# 3. Footer Structure

(as previously defined)

---

# 4. Permission Model

(same as previous version; no change needed)

---

# 5. Blog Architecture (Future Module)

(as previously defined)

---

# 6. Developer Notes

Important guidelines:

- Suites must be loaded via configuration, not hard-coded.
- Only show the suite matching the authenticated user’s tier.
- Admin must always see their suite + Admin.
- Suites and module mapping must be updated in `/docs/site-structure.md` whenever new features are added.
- Navigation hierarchy is designed to scale to dozens of modules cleanly.

---

# 9. Admin Requirements Checklist

This checklist describes the minimum admin capabilities required for the white-label SaaS platform.

## 9.1 Tenants & Members

- [ ] Admin can view a list of all tenants (`/admin/tenants`).
- [ ] Admin can see each tenant’s tier (Free / Pro / Enterprise).
- [ ] Admin can see whether a tenant has an enterprise contract.
- [ ] Admin can create/update/deactivate tenants.
- [ ] Admin can view tenant members (`/admin/tenant-members` or via tenant detail).
- [ ] Admin can search members by email, tenant, role, and status.
- [ ] Admin can add a user to a tenant (create tenant member).
- [ ] Admin can change a member’s tenant role (owner/admin/member).
- [ ] Admin can deactivate/suspend a tenant member.

## 9.2 Tiers, Functions, Permissions

- [ ] System defines static tiers: Free, Pro, Enterprise.
- [ ] System defines functions (Function A, B, C) identified by slug.
- [ ] Admin can see a matrix of Tiers × Functions (`/admin/permissions`).
- [ ] Admin can enable/disable functions per tier (writes to `tier_functions`).
- [ ] The app header only shows the suite (Free/Pro/Enterprise) that matches the user’s tier.
- [ ] The suite dropdown shows all functions assigned to that tier.

## 9.3 Roles (No UI)

- [ ] Roles are defined in Supabase / seed data (e.g., user, admin, super-admin).
- [ ] Admin UI does NOT allow changing core role definitions.
- [ ] Admin-only pages are properly protected by role checks.

## 9.4 Blog / CMS (Future)

- [ ] Blog routes exist (`/blog` listing, `/blog/[slug]` detail).
- [ ] Backing store for posts (Supabase table or external CMS) is defined.
- [ ] Integration with social media / BAU publishing is planned but not required for MVP.

**End of Document**
