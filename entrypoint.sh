#!/bin/sh

# 1. Ensure the mount and config directories exist
mkdir -p /mnt/protondrive
mkdir -p /config /transcode

# 2. Mount Proton Drive using Rclone in the background
# We use aggressive VFS caching to help Plex read the encrypted stream data
rclone mount proton: /mnt/protondrive \
    --config /app/rclone.conf \
    --vfs-cache-mode full \
    --vfs-cache-max-age 24h \
    --allow-other \
    --daemon

# Give the network mount 5 seconds to warm up and handshake
sleep 5

# 3. Start Plex Media Server in the foreground
echo "Starting Plex Media Server..."
exec /init
