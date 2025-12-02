#!/usr/bin/env bash
set -e

SHOW_ALL=false
if [[ "$1" == "--show-all" ]]; then
  SHOW_ALL=true
fi

ROOT="$HOME/baseframework/portal"
WEB="$ROOT/apps/web"
APP_APP="$WEB/app/(app)"
ADMIN="$APP_APP/admin"

GREEN="\\033[0;32m"
RED="\\033[0;31m"
YELLOW="\\033[1;33m"
NC="\\033[0m"

function ok() {
  if $SHOW_ALL; then
    echo -e "${GREEN}✔ $1${NC}"
  fi
}

function fail() {
  echo -e "${RED}✘ $1${NC}"
}

function warn() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

echo "============================================================"
echo "     Phase 2B Verification (v2) — Concise Output"
echo "============================================================"
echo


# -------------------------------------------------------------
# 1. Folder structure
# -------------------------------------------------------------
[ -d "$APP_APP" ] && ok "(app) route group exists" || fail "Missing (app) route group"
[ -d "$WEB/app/(auth)" ] && ok "(auth) route group exists" || fail "Missing (auth) route group"
[ -d "$ADMIN" ] && ok "Admin folder exists" || fail "Missing admin folder"
[ -f "$ADMIN/layout.tsx" ] && ok "Admin layout exists" || fail "Missing admin/layout.tsx"
[ -f "$ADMIN/sidebar.tsx" ] && ok "Admin sidebar exists" || fail "Missing admin/sidebar.tsx"

echo


# -------------------------------------------------------------
# 2. CRUD pages
# -------------------------------------------------------------
check_page() {
  if [ -f "$1/page.tsx" ]; then
    ok "$1 exists"
  else
    fail "Missing: $1/page.tsx"
  fi
}

check_page "$ADMIN/users"
check_page "$ADMIN/roles"
check_page "$ADMIN/permissions"
check_page "$ADMIN/attributes"
check_page "$ADMIN/modules"

echo


# -------------------------------------------------------------
# 3. Supabase config
# -------------------------------------------------------------
if [ -f "$ROOT/supabase/config.toml" ] || [ -f "$ROOT/.supabase/config.toml" ]; then
  ok "Supabase config.toml found (supabase/ or .supabase/)"
else
  fail "Missing Supabase config.toml in supabase/ or .supabase/"
fi


ENV_FILE="$WEB/.env.local"
if [ -f "$ENV_FILE" ]; then
  ok ".env.local exists"

  grep -q NEXT_PUBLIC_SUPABASE_URL "$ENV_FILE" && ok "Supabase URL set" || fail "Missing NEXT_PUBLIC_SUPABASE_URL"
  grep -q NEXT_PUBLIC_SUPABASE_ANON_KEY "$ENV_FILE" && ok "Anon key set" || fail "Missing NEXT_PUBLIC_SUPABASE_ANON_KEY"
else
  fail "Missing .env.local"
fi

echo


# -------------------------------------------------------------
# 4. Supabase server/browser client
# -------------------------------------------------------------
SERVER_FILE="$WEB/lib/supabase/server.ts"
CLIENT_FILE="$WEB/lib/supabase/client.ts"

[ -f "$SERVER_FILE" ] && ok "server.ts exists" || fail "Missing server.ts"
[ -f "$CLIENT_FILE" ] && ok "client.ts exists" || fail "Missing client.ts"

grep -q "createServerClientWrapper" "$SERVER_FILE" && ok "createServerClientWrapper exists" || fail "Missing createServerClientWrapper"
grep -q "@kit/supabase/server-client" "$SERVER_FILE" && ok "Correct server import" || fail "Wrong server import"

grep -q "@kit/supabase/browser-client" "$CLIENT_FILE" && ok "Correct browser import" || fail "Wrong browser import"

echo


# -------------------------------------------------------------
# 5. RPC detection
# -------------------------------------------------------------
grep -R "user_has_permission" "$ROOT/types/supabase.ts" >/dev/null \
  && ok "RPC 'user_has_permission' found" \
  || fail "RPC 'user_has_permission' missing in Supabase types"

echo


# -------------------------------------------------------------
# 6. Invalid imports
# -------------------------------------------------------------
BROKEN=$(grep -R "Can't resolve" "$WEB/app" "$WEB/components" "$WEB/lib" 2>/dev/null || true)
if [ -n "$BROKEN" ]; then
  fail "Broken imports detected:"
  echo "$BROKEN"
else
  ok "No broken imports"
fi

echo


# -------------------------------------------------------------
# 7. Stale alias imports
# -------------------------------------------------------------
STALE=$(grep -R "~/home" "$WEB" || true)
if [[ -n "$STALE" ]]; then
  warn "Stale '~/home' imports found:"
  echo "$STALE"
else
  ok "No stale ~/home imports"
fi

echo


# -------------------------------------------------------------
# 8. Hydration warnings
# -------------------------------------------------------------
HYDRATION=$(grep -R "hydration" "$WEB/.next" 2>/dev/null || true)
if [[ -n "$HYDRATION" ]]; then
  warn "Hydration warnings detected"
else
  ok "No hydration warnings"
fi

echo


# -------------------------------------------------------------
# 9. Admin layout checks
# -------------------------------------------------------------
grep -q "getUser" "$ADMIN/layout.tsx" && ok "User auth check present" || fail "Missing supabase.auth.getUser"
grep -q "user_has_permission" "$ADMIN/layout.tsx" && ok "Permission RPC present" || fail "Missing permission check"
grep -q "redirect" "$ADMIN/layout.tsx" && ok "Redirect logic present" || fail "Missing redirect logic"

echo

echo "============================================================"
echo "       Phase 2B Verification — Complete"
echo "============================================================"
echo
echo "🔹 Default mode: Only failures/warnings shown"
echo "🔹 Use --show-all to display all checks including OK results"
