FROM plexinc/pms-docker:latest

# 1. Install system prerequisites and the latest Rclone binary
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    && curl https://rclone.org/install.sh | bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup structural configuration paths
RUN mkdir -p /config/.config/rclone /app /etc/cont-init.d

# 3. Build the background storage server script
RUN echo '#!/bin/with-contenv bash\n\
echo "$RCLONE_CONFIG_DATA" > /config/.config/rclone/rclone.conf\n\
\n\
# Launch background stream processor with optimal caching configuration\n\
/usr/bin/rclone serve webdav gdrive: --addr 127.0.0.1:8080 --user plex --pass plexpass --vfs-cache-mode writes &\n\
' > /etc/cont-init.d/10-rclone-setup && chmod +x /etc/cont-init.d/10-rclone-setup
