#!/usr/bin/env bash
#
# twoway-sync.sh — Two‑way folder sync with conflict handling via rsync
#
# Usage:
#   ./twoway-sync.sh
#
# Configuration (edit these):
LOCAL_DIR="/path/to/local_folder"
REMOTE_DIR="/path/to/remote_folder"
LOG_FILE="/var/log/twoway-sync.log"
# Temporary working dirs
TMP_LOCAL="/tmp/.twoway-sync-local"
TMP_REMOTE="/tmp/.twoway-sync-remote"

# -----------------------------------------------------------------------------
# Initialize
# -----------------------------------------------------------------------------
exec 3>>"$LOG_FILE"                       # FD 3 for logging
log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&3; }

log "=== Starting two‑way sync: $LOCAL_DIR ↔ $REMOTE_DIR ==="

# Ensure temp dirs exist (clean slate)
rm -rf "$TMP_LOCAL" "$TMP_REMOTE"
mkdir -p "$TMP_LOCAL" "$TMP_REMOTE"

# -----------------------------------------------------------------------------
# Step 1: Mirror both sides into temporaries (capturing modifications)
# -----------------------------------------------------------------------------
log "Mirroring local → tmp_local"
rsync -a --delete --itemize-changes "$LOCAL_DIR/" "$TMP_LOCAL/" 2>&1 | while read -r line; do log "LOCAL→TMP: $line"; done

log "Mirroring remote → tmp_remote"
rsync -a --delete --itemize-changes "$REMOTE_DIR/" "$TMP_REMOTE/" 2>&1 | while read -r line; do log "REMOTE→TMP: $line"; done

# -----------------------------------------------------------------------------
# Step 2: Detect and resolve conflicts
# Conflicts: files modified on both sides since last sync.
# -----------------------------------------------------------------------------
log "Detecting conflicts"
conflicts=()
while IFS= read -r -d '' file; do
    rel="${file#$TMP_LOCAL/}"
    if [[ -f "$TMP_REMOTE/$rel" ]]; then
        # Both exist; compare mtimes
        t1=$(stat -c '%Y' "$TMP_LOCAL/$rel")
        t2=$(stat -c '%Y' "$TMP_REMOTE/$rel")
        if (( t1 > t2 )) && [[ "$LOCAL_DIR/$rel" -nt "$REMOTE_DIR/$rel" ]] && [[ "$REMOTE_DIR/$rel" -nt "$LOCAL_DIR/$rel" ]]; then
            conflicts+=("$rel")
        fi
    fi
done < <(find "$TMP_LOCAL" -type f -print0)

if (( ${#conflicts[@]} )); then
    log "Found ${#conflicts[@]} conflict(s):"
    for rel in "${conflicts[@]}"; do
        log "  • $rel"
        # Rename both versions to preserve:
        mv "$LOCAL_DIR/$rel" "$LOCAL_DIR/$rel".local_conflict 2>/dev/null
        mv "$REMOTE_DIR/$rel" "$REMOTE_DIR/$rel".remote_conflict 2>/dev/null
        log "    → Renamed to .local_conflict / .remote_conflict"
    done
else
    log "No conflicts detected."
fi

# -----------------------------------------------------------------------------
# Step 3: Push changes both directions
# -----------------------------------------------------------------------------
log "Syncing tmp_local → remote"
rsync -a --delete --log-file=/dev/stdout "$TMP_LOCAL/" "$REMOTE_DIR/" 2>&1 | while read -r line; do log "TMP_LOCAL→REMOTE: $line"; done

log "Syncing tmp_remote → local"
rsync -a --delete --log-file=/dev/stdout "$TMP_REMOTE/" "$LOCAL_DIR/" 2>&1 | while read -r line; do log "TMP_REMOTE→LOCAL: $line"; done

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
rm -rf "$TMP_LOCAL" "$TMP_REMOTE"
log "=== Two‑way sync complete ==="
exec 3>&-

exit 0
6