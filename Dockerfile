FROM plexinc/pms-docker:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    && curl https://rclone.org/install.sh | bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /config/.config/rclone /app /etc/cont-init.d

RUN cat > /etc/cont-init.d/10-rclone-setup << 'EOF'
#!/usr/bin/with-contenv bash
set -e

if [ -z "${RCLONE_CONFIG_DATA}" ]; then
  echo "[10-rclone-setup] WARNING: RCLONE_CONFIG_DATA is not set; skipping rclone config write."
else
  printf '%s' "${RCLONE_CONFIG_DATA}" > /config/.config/rclone/rclone.conf
fi

exec /usr/bin/rclone serve webdav gdrive: \
  --config /config/.config/rclone/rclone.conf \
  --addr 127.0.0.1:8080 \
  --user plex \
  --pass plexpass \
  --vfs-cache-mode writes &
EOF

RUN chmod +x /etc/cont-init.d/10-rclone-setup
docker run -d \
  --network=host \
  -e PLEX_CLAIM=claim-claim-koM6FGZDn9S1C_9ycCtz \
  -e ADVERTISE_IP=http://YOUR_SERVER_IP:32400/ \
  -e RCLONE_CONFIG_DATA="$(cat ~/.config/rclone/rclone.conf)" \
  -v /path/to/config:/config \
  your-image-name
