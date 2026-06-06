FROM plexinc/pms-docker:latest

# 1. Install system tools, Python, FUSE mount dependencies, and the latest Rclone
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

RUN pip3 install --no-cache-dir --break-system-packages gspread google-auth

# 2. Create standard folder paths
RUN mkdir -p /config/.config/rclone /config/.config/gdrive /data/media /app /custom-services.d

# 3. Write the Google Sheet reader script targeting A1
RUN echo 'import gspread\n\
import os\n\
from google.oauth2.service_account import Credentials\n\
\n\
try:\n\
    scopes = ["https://www.googleapis.com/auth/spreadsheets.readonly"]\n\
    creds = Credentials.from_service_account_file("/config/.config/gdrive/sa.json", scopes=scopes)\n\
    client = gspread.authorize(creds)\n\
    sheet = client.open_by_key(os.environ["GOOGLE_SHEET_ID"]).sheet1\n\
    # Look directly at cell A1 (Row 1, Column 1)\n\
    latest_token = sheet.cell(1, 1).value.strip()\n\
    if latest_token:\n\
        print(f"SUCCESS: Found latest token in A1: {latest_token}")\n\
        with open("/app/token.txt", "w") as f:\n\
            f.write(latest_token)\n\
except Exception as e:\n\
    print(f"ERROR reading sheet cell A1: {e}")\n\
' > /app/get_token.py

# 4. Create the initialization service script inside Plex's official startup directory
RUN echo '#!/bin/with-contenv bash\n\
# Write out cloud configurations\n\
echo "$GDRIVE_SA_JSON" > /config/.config/gdrive/sa.json\n\
echo "$RCLONE_CONFIG_DATA" > /config/.config/rclone/rclone.conf\n\
\n\
# Mount Proton Drive to the media directory\n\
/usr/bin/rclone mount gdrive: /data/media --allow-other --vfs-cache-mode writes &\n\
\n\
# Fetch the claim token dynamically from your sheet\n\
python3 /app/get_token.py\n\
if [ -f /app/token.txt ]; then\n\
    mkdir -p /etc/services.d/plex/env\n\
    cat /app/token.txt > /etc/services.d/plex/env/PLEX_CLAIM\n\
    echo "SUCCESS: Injected claim token into Plex core configuration environment."\n\
fi\n\
' > /custom-services.d/10-rclone-gspread && chmod +x /custom-services.d/10-rclone-gspread
