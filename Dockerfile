FROM alpine:latest

# 1. Install rclone, curl, certificates, and the lightweight Jellyfin components natively
RUN apk add --no-cache rclone curl ca-certificates jellyfin jellyfin-web ffmpeg

# 2. Create the system directories for configurations and cache
RUN mkdir -p /root/.config/rclone /data/jellyfin/config /data/jellyfin/cache

# 3. Boot script: Maps network ports using environment variables instead of broken terminal flags
CMD echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    rclone serve webdav proton: --addr 127.0.0.1:8080 & \
    sleep 3 && \
    export JELLYFIN_HttpServer__BindAddresses=0.0.0.0 && \
    export JELLYFIN_HttpServer__PublishedPort=$PORT && \
    exec jellyfin \
      --datadir /data/jellyfin \
      --configdir /data/jellyfin/config \
      --cachedir /data/jellyfin/cache \
      --logdir /data/jellyfin/log
