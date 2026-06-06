#!/bin/sh

# 1. Ensure the directories exist
mkdir -p /mnt/protondrive
mkdir -p /config/Library/Application\ Support/Plex\ Media\ Server/
mkdir -p /transcode

# 2. Mount Proton Drive in the background
rclone mount proton: /mnt/protondrive \
    --config /app/rclone.conf \
    --vfs-cache-mode full \
    --vfs-cache-max-age 24h \
    --allow-other \
    --daemon

sleep 5

# 3. Manually create the Plex Preferences file if it doesn't exist
# This injects the claim token directly into the XML config so Plex reads it on a normal boot
PREFS_FILE="/config/Library/Application Support/Plex Media Server/Preferences.xml"

if [ ! -f "$PREFS_FILE" ] && [ -n "$MY_CUSTOM_CLAIM" ]; then
    echo "Pre-populating Plex Preferences with custom claim token..."
    cat <<EOF > "$PREFS_FILE"
<?xml version="1.0" encoding="utf-8"?>
<Preferences MachineIdentifier="" ProcessedMachineIdentifier="" AnonymousMachineIdentifier="" PlexOnlineToken="" PlexOnlineUsername="" PlexOnlineMail="" PlexOnlineHome="0" MediaFlagsVersion="1" AcceptedEULA="1" FirstRun="0" PlexOnlineTokenForSession="" PlexOnlineTokenStatus="unknown" PlexOnlineTokenClaim="$MY_CUSTOM_CLAIM"/>
EOF
fi

# 4. Start Plex Media Server normally
echo "Starting Plex Media Server..."
exec /init
