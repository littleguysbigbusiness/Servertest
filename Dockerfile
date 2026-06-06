FROM alpine:latest

# 1. Install rclone, curl, tar, and ca-certificates
RUN apk add --no-cache rclone curl tar ca-certificates

# 2. Download and install Filebrowser directly
RUN curl -fsSL https://github.com/filebrowser/filebrowser/releases/latest/download/linux-amd64-filebrowser.tar.gz -o filebrowser.tar.gz && \
    tar -xzf filebrowser.tar.gz && \
    mv filebrowser /usr/local/bin/filebrowser && \
    rm filebrowser.tar.gz

# 3. Create rclone's internal config folder
RUN mkdir -p /root/.config/rclone

# 4. Boot script: Serves Proton via WebDAV locally, and points Filebrowser right at it
CMD echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    rclone serve webdav proton: --addr 127.0.0.1:8080 & \
    sleep 3 && \
    filebrowser -r http://127.0.0.1:8080 --noauth -p $PORT -a 0.0.0.0
