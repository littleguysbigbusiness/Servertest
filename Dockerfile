FROM plexinc/pms-docker:latest

# 1. Install system tools, FUSE, and the latest Rclone binary
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    fuse3 \
    && curl https://rclone.org/install.sh | bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup directory structural requirements
RUN mkdir -p /config/.config/rclone /data/media /app

# 3. Create a clean master boot script
RUN echo '#!/bin/bash\n\
echo "$RCLONE_CONFIG_DATA" > /config/.config/rclone/rclone.conf\n\
\n\
# Mount your Proton Drive to Plex media folder\n\
/usr/bin/rclone mount gdrive: /data/media --allow-other --vfs-cache-mode writes &\n\
\n\
# Force Plex to trust connections so you can claim it via the UI\n\
mkdir -p "/config/Library/Application Support/Plex Media Server"\n\
echo "<?xml version=\"1.0\" encoding=\"utf-8\"?><Preferences allowedNetworks=\"0.0.0.0/0\"/>" > "/config/Library/Application Support/Plex Media Server/Preferences.xml"\n\
\n\
# Wait for storage layer setup to complete, then hand over to Plex initialization\n\
sleep 5\n\
exec /init\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

EXPOSE 32400
ENTRYPOINT ["/app/entrypoint.sh"]
