#!/usr/bin/env bash
set -e

ENV_FILE="apps/web/.env.local"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ .env.local not found at $ENV_FILE"
  exit 1
fi

SUPABASE_URL=$(grep "^SUPABASE_URL=" "$ENV_FILE" | cut -d'=' -f2)
SERVICE_ROLE=$(grep "^SUPABASE_SERVICE_ROLE_KEY=" "$ENV_FILE" | cut -d'=' -f2)
PROJECT_REF=$(echo "$SUPABASE_URL" | sed 's#https://##; s#.supabase.co##')

echo "============================================================"
echo "    Phase 3 RBAC — Direct SQL Verification (Supabase)"
echo "============================================================"
echo "Project: $PROJECT_REF"
echo

# ---------------------------------------
# Helper function
# ---------------------------------------
check_table() {
  local table="$1"
  local result=$(curl -s \
      -H "apikey: $SERVICE_ROLE" \
      -H "Authorization: Bearer $SERVICE_ROLE" \
      "$SUPABASE_URL/rest/v1/$table?limit=1")

  if echo "$result" | grep -qiE "error|not found|does not exist"; then
    echo "❌ Table missing: $table"
  else
    echo "✔ Table exists: $table"
  fi
}

check_rpc() {
  local rpc="$1"
  local result=$(curl -s \
      -H "apikey: $SERVICE_ROLE" \
      -H "Authorization: Bearer $SERVICE_ROLE" \
      "$SUPABASE_URL/rest/v1/rpc/$rpc" \
      -H "Content-Type: application/json" \
      -d '{"user_id":"test","permission_name":"test"}')

  if echo "$result" | grep -qiE "error|not found|rpc"; then
    echo "❌ RPC missing: $rpc"
  else
    echo "✔ RPC exists: $rpc"
  fi
}

# ---------------------------------------
# Table Checks
# ---------------------------------------
echo "➡ Checking RBAC tables..."
check_table "roles"
check_table "permissions"
check_table "role_permissions"
check_table "user_roles"
echo

# ---------------------------------------
# RPC Checks
# ---------------------------------------
echo "➡ Checking RPC functions..."
check_rpc "user_has_permission"
check_rpc "get_user_permissions"
check_rpc "get_role_permissions"
echo

# ---------------------------------------
# RLS and Policies
# ---------------------------------------
echo "➡ Checking RLS..."
RLS=$(curl -s \
  -H "apikey: $SERVICE_ROLE" \
  -H "Authorization: Bearer $SERVICE_ROLE" \
  "$SUPABASE_URL/rest/v1/roles" -I | grep "x-rls" || true)

if echo "$RLS" | grep -qi "true"; then
  echo "✔ RLS enabled"
else
  echo "❌ RLS disabled — must be enabled for RBAC"
fi

echo
echo "============================================================"
echo "           Phase 3 SQL RBAC Verification Complete"
echo "============================================================"
