#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
TYPES_FILE="$ROOT/types/supabase.ts"

SHOW_ALL=0
if [[ "$1" == "--show-all" ]]; then
  SHOW_ALL=1
fi

RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
RESET="\033[0m"

print_ok() {
  if [[ $SHOW_ALL -eq 1 ]]; then
    echo -e "  ${GREEN}✔${RESET} $1"
  fi
}

print_fail() {
  echo -e "  ${RED}✘${RESET} $1"
}

print_warn() {
  echo -e "  ${YELLOW}⚠${RESET} $1"
}

echo "============================================================"
echo "      Phase 3 RBAC Verification — MakerKit (v5)"
echo "============================================================"
echo

###############################################
# 1) Check Supabase link
###############################################
SUPA_CONFIG="$ROOT/.supabase/config.toml"

echo "1) Checking Supabase link..."
if [[ -f "$SUPA_CONFIG" ]]; then
  print_ok "Supabase config found"
else
  print_fail "Missing .supabase/config.toml — project not linked"
fi
echo

###############################################
# 2) Check environment variables
###############################################
echo "2) Checking environment vars..."

ENV_FILE="$ROOT/apps/web/.env.local"
if [[ ! -f "$ENV_FILE" ]]; then
  print_fail ".env.local not found at apps/web/.env.local"
else
  print_ok ".env.local found"
fi

SERVICE_ROLE="$(grep -E '^SUPABASE_SERVICE_ROLE_KEY=' "$ENV_FILE" | cut -d '=' -f2-)"

if [[ -z "$SERVICE_ROLE" ]]; then
  print_fail "SUPABASE_SERVICE_ROLE_KEY missing"
else
  print_ok "SUPABASE_SERVICE_ROLE_KEY present"
fi

echo

###############################################
# 3) Check RBAC tables inside supabase.ts
###############################################
echo "3) Checking RBAC tables..."

missing_tables=()

check_table() {
  local t="$1"
  if grep -q "Tables: {" -n "$TYPES_FILE" && grep -q " $t:" "$TYPES_FILE"; then
    print_ok "Found table: $t"
  else
    print_fail "Missing table: $t"
    missing_tables+=("$t")
  fi
}

check_table "roles"
check_table "permissions"
check_table "role_permissions"
check_table "user_roles"

if [[ ${#missing_tables[@]} -gt 0 ]]; then
  echo
  print_warn "RBAC Table Diagnostics:"
  echo "  Missing: ${missing_tables[*]}"
  echo "  Causes:"
  echo "    • Types file outdated"
  echo "    • SQL did not apply"
  echo "    • Wrong Supabase project"
  echo
fi

###############################################
# 4) Check RPC functions
###############################################
echo "4) Checking RPC functions..."
missing_rpc=()

check_rpc() {
  local r="$1"
  if grep -q "Functions: {" -n "$TYPES_FILE" && grep -q "$r:" "$TYPES_FILE"; then
    print_ok "Found RPC: $r"
  else
    print_fail "Missing RPC: $r"
    missing_rpc+=("$r")
  fi
}

check_rpc "user_has_permission"
check_rpc "get_user_permissions"
check_rpc "get_role_permissions"

if [[ ${#missing_rpc[@]} -gt 0 ]]; then
  echo
  print_warn "RPC Diagnostics:"
  echo "  Missing: ${missing_rpc[*]}"
  echo "  Causes:"
  echo "    • SQL did not apply"
  echo "    • Types did not regenerate"
  echo
fi

###############################################
# 5) Check admin pages exist
###############################################
echo "5) Checking admin pages..."

ADMIN_DIR="$ROOT/apps/web/app/(app)/admin"

check_page() {
  local name="$1"
  if [[ -f "$ADMIN_DIR/$name/page.tsx" ]]; then
    print_ok "$name page OK"
  else
    print_fail "Missing page: $name/page.tsx"
  fi
}

check_page "users"
check_page "roles"
check_page "permissions"
check_page "attributes"
check_page "modules"

echo

###############################################
# 6) Check broken imports (static surface scan)
###############################################
echo "6) Checking for broken imports..."

broken=$(grep -R "Cannot find module" apps/web/.next 2>/dev/null | wc -l | tr -d ' ')

if [[ "$broken" -gt 0 ]]; then
  print_fail "Broken imports detected:"
  grep -R "Cannot find module" apps/web/.next | head -6
else
  print_ok "No broken imports"
fi
echo

###############################################
# 7) Hydration warnings
###############################################
echo "7) Checking hydration warnings..."

hydro=$(grep -R "hydration" apps/web/.next 2>/dev/null | wc -l | tr -d ' ')

if [[ "$hydro" -gt 0 ]]; then
  print_warn "Hydration warnings detected"
else
  print_ok "No hydration warnings"
fi
echo

###############################################
# 8) RLS policies
###############################################
echo "8) Checking RLS policies (static-only check)..."

if grep -q "enable_rls" "$ROOT/supabase/migrations"/* 2>/dev/null; then
  print_ok "RLS appears configured"
else
  print_fail "No RLS policy SQL found"
fi

echo
echo "============================================================"
echo "       Phase 3 Verification (v5) — COMPLETE"
echo "============================================================"
echo "Use --show-all to display all successes"
