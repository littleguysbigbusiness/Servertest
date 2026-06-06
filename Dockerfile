FROM alpine:latest

# 1. Install rclone, curl, certificates, and tools to unpack Debian packages
RUN apk add --no-cache rclone curl ca-certificates gcompat libstdc++ binutils

# 2. Download official Plex Debian package and manually extract the server files
RUN curl -L "https://downloads.plex.tv/plex-media-server-new/1.43.1.10611-1e34174b1/debian/plexmediaserver_1.43.1.10611-1e34174b1_amd64.deb" -o plex.deb && \
    ar x plex.deb && \
    tar -xf data.tar.xz && \
    mkdir -p /usr/lib/plexmediaserver && \
    mv usr/lib/plexmediaserver/* /usr/lib/plexmediaserver/ && \
    rm -rf plex.deb control.tar.gz data.tar.xz debian-binary usr lib

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
