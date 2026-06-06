FROM alpine:latest

# Install rclone, filebrowser, and required systems
RUN apk add --no-cache rclone filebrowser ca-certificates fuse3

# Create necessary internal folders
RUN mkdir -p /root/.config/rclone /data

# Boot configuration script
CMD echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    rclone mount proton: /data --vfs-cache-mode full --allow-other & \
    filebrowser -r /data --noauth -p $PORT -a 0.0.0.0
