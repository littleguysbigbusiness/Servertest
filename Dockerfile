FROM lscr.io/linuxserver/plex:latest

# Install rclone and fuse3 for cloud drive mapping
RUN apt-get update && apt-get install -y rclone fuse3 && rm -rf /var/lib/apt/lists/*

# Set the internal working directory
WORKDIR /app

# Copy your configuration and startup scripts into the container
COPY rclone.conf /app/rclone.conf
COPY entrypoint.sh /app/entrypoint.sh

# Grant execution permissions to the startup script
RUN chmod +x /app/entrypoint.sh

# Override the default startup to use our custom bridge script
ENTRYPOINT ["/app/entrypoint.sh"]
