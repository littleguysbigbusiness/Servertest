FROM plexinc/pms-docker:latest

# 1. Install prerequisites and the absolute latest Rclone binary (for Proton support)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    && curl https://rclone.org/install.sh | bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup config paths
RUN mkdir -p /config/.config/rclone /app

# 3. Create the boot script using rclone serve instead of mount
RUN echo '#!/bin/bash\n\
echo "$RCLONE_CONFIG_DATA" > /config/.config/rclone/rclone.conf\n\
\n\
# Serve your Proton Drive via local WebDAV protocol (bypasses FUSE rules)\n\
/usr/bin/rclone serve webdav gdrive: --addr 127.0.0.1:8080 --user plex --pass plexpass &\n\
\n\
# Force Plex to trust connections so you can bypass claim token racing\n\
mkdir -p "/config/Library/Application Support/Plex Media Server"\n\
echo "<?xml version=\"1.0\" encoding=\"utf-8\"?><Preferences allowedNetworks=\"0.0.0.0/0\"/>" > "/config/Library/Application Support/Plex Media Server/Preferences.xml"\n\
\n\
sleep 5\n\
exec /init\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

EXPOSE 32400
ENTRYPOINT ["/app/entrypoint.sh"]
