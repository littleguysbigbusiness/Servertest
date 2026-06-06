FROM alpine:latest

# 1. Install rclone, curl (to download files), and fuse3
RUN apk add --no-cache rclone curl ca-certificates fuse3

# 2. Download and install Filebrowser directly from their official script
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | sh

# 3. Create necessary internal folders
RUN mkdir -p /root/.config/rclone /data

# 4. Boot configuration script
CMD echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    rclone mount proton: /data --vfs-cache-mode full --allow-other & \
    filebrowser -r /data --noauth -p $PORT -a 0.0.0.0
