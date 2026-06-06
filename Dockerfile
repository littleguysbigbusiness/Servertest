FROM alpine:latest

# 1. Install rclone, curl, certificates, and the lightweight Jellyfin components natively
RUN apk add --no-cache rclone curl ca-certificates jellyfin jellyfin-web ffmpeg

# 2. Create the system directories for configurations and cache
RUN mkdir -p /root/.config/rclone /data/jellyfin/config /data/jellyfin/cache

# 3. Boot script: Starts Rclone internally, then launches the media engine
CMD echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    rclone serve webdav proton: --addr 127.0.0.1:8080 & \
    sleep 3 && \
    exec jellyfin \
      --datadir /data/jellyfin \
      --configdir /data/jellyfin/config \
      --cachedir /data/jellyfin/cache \
      --logdir /data/jellyfin/log \
      --bind 0.0.0.0 \
      --port $PORT
