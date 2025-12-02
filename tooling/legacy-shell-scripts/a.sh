#!/bin/bash
set -e

echo "============================================="
echo " STEP 0 — Checking project root"
echo "============================================="

if [ ! -d "apps/web/app" ]; then
  echo "❌ ERROR: This script must be run from project root (the folder containing apps/web/app)"
  exit 1
fi

APP_ROOT="apps/web/app"
GROUP_DIR="apps/web/app/(app)"

echo ""
echo "Project root validated ✔"
echo ""

echo "============================================="
echo " STEP 1 — Pre-validation of folder structure"
echo "============================================="

echo ""
echo "Current directories (depth 3):"
find "$APP_ROOT" -maxdepth 3 -type d | sort
echo ""

# Check if (app) route group exists
if [ -d "$GROUP_DIR" ]; then
  echo "Found existing (app) route group ✔"
else
  echo "No (app) folder found — creating it now..."
  mkdir -p "$GROUP_DIR"
fi

echo ""
echo "============================================="
echo " STEP 2 — Identify folders that MUST move under (app)"
echo "============================================="

AUTH_FOLDERS=(
  "settings"
  "home"
  "update-password"
)

ADMIN_FOLDER="admin"

echo "Public folders that must stay in root:"
echo " → auth/"
echo " → legal/"
echo " → public/"
echo " → sitemap.xml"
echo ""

echo "Folders to move into (app):"
for fld in "${AUTH_FOLDERS[@]}"; do
  if [ -d "$APP_ROOT/$fld" ]; then
    echo " → $fld"
  else
    echo " → $fld (already moved or missing)"
  fi
done

if [ -d "$APP_ROOT/$ADMIN_FOLDER" ]; then
  echo " → admin (but admin contains its own layout, so only relocate folder)"
else
  echo " → admin (already moved or missing)"
fi

echo ""
echo "============================================="
echo " STEP 3 — Confirm action"
echo "============================================="

read -p "Proceed with reorganization? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "❌ Cancelled by user"
  exit 1
fi

echo ""
echo "============================================="
echo " STEP 4 — Moving folders"
echo "============================================="

# Move authenticated folders
for fld in "${AUTH_FOLDERS[@]}"; do
  if [ -d "$APP_ROOT/$fld" ]; then
    echo "Moving $fld → (app)/$fld"
    mv "$APP_ROOT/$fld" "$GROUP_DIR/$fld"
  fi
done

# Move admin
if [ -d "$APP_ROOT/$ADMIN_FOLDER" ]; then
  echo "Moving admin → (app)/admin"
  mv "$APP_ROOT/$ADMIN_FOLDER" "$GROUP_DIR/$ADMIN_FOLDER"
fi

echo ""
echo "============================================="
echo " STEP 5 — Post-validation"
echo "============================================="

echo ""
echo "Updated directory tree:"
find "$APP_ROOT" -maxdepth 3 -type d | sort
echo ""

echo "Checking that required directories now exist:"
for fld in "${AUTH_FOLDERS[@]}" "admin"; do
  if [ -d "$GROUP_DIR/$fld" ]; then
    echo "✔ $fld correctly located under (app)"
  else
    echo "❌ $fld is missing under (app)"
  fi
done

echo ""
echo "============================================="
echo " DONE — Route structure reorganized safely!"
echo "============================================="
