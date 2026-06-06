FROM alpine:latest

# 1. Install rclone, curl, certificates, and native media server components
RUN apk add --no-cache rclone curl ca-certificates jellyfin jellyfin-web ffmpeg

# 2. Create standard data storage directories
RUN mkdir -p /root/.config/rclone /data/jellyfin/config /data/jellyfin/cache

# 3. Boot script: Explicitly declares the web client path using the --webdir flag
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
