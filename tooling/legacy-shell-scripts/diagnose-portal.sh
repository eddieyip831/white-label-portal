#!/bin/bash

LOGFILE="a.log"

echo "Running MakerKit Portal Diagnostics..." > "$LOGFILE"
echo "Timestamp: $(date)" >> "$LOGFILE"
echo "----------------------------------------" >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "1) Listing ~/baseframework/portal" >> "$LOGFILE"
echo "----------------------------------------" >> "$LOGFILE"
ls -la ~/baseframework/portal >> "$LOGFILE" 2>&1

echo "" >> "$LOGFILE"
echo "2) Listing ~/baseframework/portal/apps" >> "$LOGFILE"
echo "----------------------------------------" >> "$LOGFILE"
ls -la ~/baseframework/portal/apps >> "$LOGFILE" 2>&1

echo "" >> "$LOGFILE"
echo "3) Tailwind detection in pnpm workspace" >> "$LOGFILE"
echo "----------------------------------------" >> "$LOGFILE"
cd ~/baseframework/portal 2>>"$LOGFILE"
pnpm list -r --filter tailwindcss >> "$LOGFILE" 2>&1

echo "" >> "$LOGFILE"
echo "Diagnostics complete. See a.log." >> "$LOGFILE"
