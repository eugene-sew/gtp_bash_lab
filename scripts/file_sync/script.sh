#!/usr/bin/env bash
#
# Interactive Two‑way Folder Sync Script
#
# This script synchronizes two directories with conflict resolution using rsync.
# Usage:
#   ./interactive-twoway-sync.sh

# -----------------------------------------------------------------------------
# User Input for Configuration
# -----------------------------------------------------------------------------
echo "Welcome to the Two-Way Folder Sync Utility!"

read -p "Enter the path to the LOCAL directory: " LOCAL_DIR
while [[ ! -d "$LOCAL_DIR" ]]; do
  echo "Invalid path. Please enter a valid LOCAL directory path."
  read -p "Enter the path to the LOCAL directory: " LOCAL_DIR
done

read -p "Enter the path to the REMOTE directory: " REMOTE_DIR
while [[ ! -d "$REMOTE_DIR" ]]; do
  echo "Invalid path. Please enter a valid REMOTE directory path."
  read -p "Enter the path to the REMOTE directory: " REMOTE_DIR
done

read -p "Do you want to enable logging? (yes/no): " ENABLE_LOG
if [[ "$ENABLE_LOG" =~ ^(yes|y|Y)$ ]]; then
  read -p "Enter the path for the log file (default: /var/log/twoway-sync.log): " LOG_FILE
  LOG_FILE=${LOG_FILE:-/var/log/twoway-sync.log}
  exec 3>>"$LOG_FILE"
  log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&3; }
  log "=== Two-Way Sync Initialized ==="
else
  log() { :; }
fi

read -p "Do you want to handle conflicts automatically by renaming files? (yes/no): " AUTO_RESOLVE
AUTO_RESOLVE=${AUTO_RESOLVE:-no}

# Temporary working dirs
TMP_LOCAL="/tmp/.twoway-sync-local"
TMP_REMOTE="/tmp/.twoway-sync-remote"

# -----------------------------------------------------------------------------
# Initialize
# -----------------------------------------------------------------------------
log "Local Directory: $LOCAL_DIR"
log "Remote Directory: $REMOTE_DIR"

# Ensure temp dirs exist (clean slate)
rm -rf "$TMP_LOCAL" "$TMP_REMOTE"
mkdir -p "$TMP_LOCAL" "$TMP_REMOTE"

# -----------------------------------------------------------------------------
# Step 1: Mirror both sides into temporaries
# -----------------------------------------------------------------------------
log "Mirroring local → tmp_local"
rsync -a --delete --itemize-changes "$LOCAL_DIR/" "$TMP_LOCAL/" | while read -r line; do log "LOCAL→TMP: $line"; done

log "Mirroring remote → tmp_remote"
rsync -a --delete --itemize-changes "$REMOTE_DIR/" "$TMP_REMOTE/" | while read -r line; do log "REMOTE→TMP: $line"; done

# -----------------------------------------------------------------------------
# Step 2: Detect and resolve conflicts
# -----------------------------------------------------------------------------
log "Detecting conflicts"
conflicts=()
while IFS= read -r -d '' file; do
  rel="${file#$TMP_LOCAL/}"
  if [[ -f "$TMP_REMOTE/$rel" ]]; then
    t1=$(stat -c '%Y' "$TMP_LOCAL/$rel")
    t2=$(stat -c '%Y' "$TMP_REMOTE/$rel")
    if (( t1 > t2 )); then
      conflicts+=("$rel")
    fi
  fi
done < <(find "$TMP_LOCAL" -type f -print0)

if (( ${#conflicts[@]} > 0 )); then
  echo "Conflicts detected:"
  for rel in "${conflicts[@]}"; do
    echo "  - $rel"
    if [[ "$AUTO_RESOLVE" =~ ^(yes|y|Y)$ ]]; then
      mv "$LOCAL_DIR/$rel" "$LOCAL_DIR/$rel.local_conflict" 2>/dev/null
      mv "$REMOTE_DIR/$rel" "$REMOTE_DIR/$rel.remote_conflict" 2>/dev/null
      log "Conflict resolved: $rel → Renamed to .local_conflict/.remote_conflict"
    else
      echo "  (Manual conflict resolution required for $rel)"
    fi
  done
else
  log "No conflicts detected."
fi

# -----------------------------------------------------------------------------
# Step 3: Sync changes
# -----------------------------------------------------------------------------
log "Syncing tmp_local → remote"
rsync -a --delete "$TMP_LOCAL/" "$REMOTE_DIR/" | while read -r line; do log "TMP_LOCAL→REMOTE: $line"; done

log "Syncing tmp_remote → local"
rsync -a --delete "$TMP_REMOTE/" "$LOCAL_DIR/" | while read -r line; do log "TMP_REMOTE→LOCAL: $line"; done

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
rm -rf "$TMP_LOCAL" "$TMP_REMOTE"
log "=== Two-Way Sync Complete ==="
echo "Synchronization complete! Check the log for details, if enabled."
exec 3>&-
