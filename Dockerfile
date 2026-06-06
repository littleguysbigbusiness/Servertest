FROM plexinc/pms-docker:latest

# 1. Install system tools, Python, FUSE mount dependencies, and the latest Rclone binary
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    python3 \
    python3-pip \
    fuse3 \
    && curl https://rclone.org/install.sh | bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Install automation libraries
RUN pip3 install --no-cache-dir --break-system-packages gspread google-auth

# 3. Establish storage locations inside Plex's config zone and media path
RUN mkdir -p /config/.config/rclone /config/.config/gdrive /data/media /app

# 4. Write the Google Sheet reader script
RUN echo 'import gspread\n\
import os\n\
from google.oauth2.service_account import Credentials\n\
\n\
try:\n\
    scopes = ["https://www.googleapis.com/auth/spreadsheets.readonly"]\n\
    creds = Credentials.from_service_account_file("/config/.config/gdrive/sa.json", scopes=scopes)\n\
    client = gspread.authorize(creds)\n\
    sheet = client.open_by_key(os.environ["GOOGLE_SHEET_ID"]).sheet1\n\
    all_values = sheet.get_all_values()\n\
    if all_values:\n\
        latest_token = all_values[-1][0].strip()\n\
        print(f"SUCCESS: Found latest token: {latest_token}")\n\
        with open("/app/token.txt", "w") as f:\n\
            f.write(latest_token)\n\
except Exception as e:\n\
    print(f"ERROR reading sheet: {e}")\n\
' > /app/get_token.py

# 5. Create the master boot script
RUN echo '#!/bin/bash\n\
echo "$GDRIVE_SA_JSON" > /config/.config/gdrive/sa.json\n\
echo "$RCLONE_CONFIG_DATA" > /config/.config/rclone/rclone.conf\n\
\n\
# Mount Proton Drive directly to Plex media folder\n\
/usr/bin/rclone mount gdrive: /data/media --allow-other --vfs-cache-mode writes &\n\
\n\
# Grab the token from Google Sheets and export it to Plex\n\
python3 /app/get_token.py\n\
if [ -f /app/token.txt ]; then\n\
    export PLEX_CLAIM=$(cat /app/token.txt)\n\
fi\n\
\n\
# Wait a moment for the mount to stabilize, then hand over to Plex\n\
sleep 5\n\
exec /init\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

EXPOSE 32400
ENTRYPOINT ["/app/entrypoint.sh"]
