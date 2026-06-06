FROM alpine:latest

# 1. Install rclone, curl, tar (to unpack the file), and fuse3
RUN apk add --no-cache rclone curl tar ca-certificates fuse3

# 2. Download and install Filebrowser directly (Linux 64-bit version)
RUN curl -fsSL https://github.com/filebrowser/filebrowser/releases/latest/download/linux-amd64-filebrowser.tar.gz -o filebrowser.tar.gz && \
    tar -xzf filebrowser.tar.gz && \
    mv filebrowser /usr/local/bin/filebrowser && \
    rm filebrowser.tar.gz

# 3. Create necessary internal folders
RUN mkdir -p /root/.config/rclone /data

# 4. Boot configuration script
CMD echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    rclone serve http proton: --addr 127.0.0.1:8080 & \
    filebrowser -r http://127.0.0.1:8080 --noauth -p $PORT -a 0.0.0.0
