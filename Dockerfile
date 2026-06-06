FROM alpine:latest

# 1. Install rclone, curl, certificates, Jellyfin backend, and processing tools
RUN apk add --no-cache rclone curl ca-certificates jellyfin ffmpeg

# 2. Download and unpack the official pre-compiled Web Client build directly
RUN mkdir -p /usr/share/jellyfin-web && \
    curl -L "https://github.com/jellyfin/jellyfin-web/archive/refs/tags/v10.10.5.tar.gz" -o web.tar.gz && \
    tar -xzf web.tar.gz -C /usr/share/jellyfin-web --strip-components=1 && \
    rm web.tar.gz

# 3. Establish internal data directories
RUN mkdir -p /root/.config/rclone /data/jellyfin/config /data/jellyfin/cache

# 4. Launch script: Runs the clean cloud stream and hooks the web player directory
CMD echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    pkill rclone || true && \
    rclone serve webdav proton: --addr 127.0.0.1:8080 & \
    sleep 3 && \
    export JELLYFIN_HttpServer__BindAddresses=0.0.0.0 && \
    export JELLYFIN_HttpServer__PublishedPort=$PORT && \
    exec jellyfin \
      --datadir /data/jellyfin \
      --configdir /data/jellyfin/config \
      --cachedir /data/jellyfin/cache \
      --logdir /data/jellyfin/log \
      --webdir /usr/share/jellyfin-web
