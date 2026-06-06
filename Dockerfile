FROM alpine:latest

# 1. Install rclone, curl, and required system tools for Plex
RUN apk add --no-cache rclone curl ca-certificates openrc dummy-vdo

# 2. Download and extract official Plex Media Server binaries
RUN curl -L "https://plex.tv/downloads/latest/1?channel=8&build=linux-x86_64&distro=debian" -o plex.tar.bz2 && \
    mkdir -p /usr/lib/plexmediaserver && \
    tar -xjf plex.tar.bz2 -C /usr/lib/plexmediaserver --strip-components=1 && \
    rm plex.tar.bz2

# 3. Create config and media directories
RUN mkdir -p /root/.config/rclone /data/plex_support

# 4. Boot script: Loads variables dynamically to claim the server
CMD echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    rclone serve webdav proton: --addr 127.0.0.1:8080 & \
    sleep 3 && \
    export PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6 && \
    export PLEX_MEDIA_SERVER_HOME=/usr/lib/plexmediaserver && \
    export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/data/plex_support && \
    export PLEX_CLAIM="$PLEX_CLAIM_TOKEN" && \
    exec /usr/lib/plexmediaserver/Plex\ Media\ Server
