FROM plexinc/pms-docker:latest

# 1. Install system prerequisites and the absolute latest Rclone binary
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    && curl https://rclone.org/install.sh | bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup structural paths inside the container zone
RUN mkdir -p /config/.config/rclone /app /etc/cont-init.d

# 3. Create a reliable background initialization hook script
RUN echo '#!/bin/with-contenv bash\n\
# Write cloud configuration variables\n\
echo "$RCLONE_CONFIG_DATA" > /config/.config/rclone/rclone.conf\n\
\n\
# Fire up the background WebDAV server to stream Proton Drive files\n\
/usr/bin/rclone serve webdav gdrive: --addr 127.0.0.1:8080 --user plex --pass plexpass &\n\
\n\
# Force network permissions directly into the underlying preference file\n\
mkdir -p "/config/Library/Application Support/Plex Media Server"\n\
echo "<?xml version=\"1.0\" encoding=\"utf-8\"?><Preferences allowedNetworks=\"0.0.0.0/0\"/>" > "/config/Library/Application Support/Plex Media Server/Preferences.xml"\n\
' > /etc/cont-init.d/10-rclone-setup && chmod +x /etc/cont-init.d/10-rclone-setup
