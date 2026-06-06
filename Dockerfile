FROM plexinc/pms-docker:latest

# 1. Install prerequisites, Python libraries, FUSE, and the latest Rclone
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

# 3. Write the Google Sheet token reader script
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
    export PLEX_CLAIM=$(cat /app/token.txt)\n\
    # Inject it directly into the official environment zone\n\
    echo "export PLEX_CLAIM=\"$PLEX_CLAIM\"" >> /etc/profile.d/plex.sh\n\
fi\n\
' > /custom-services.d/10-rclone-gspread && chmod +x /custom-services.d/10-rclone-gspread
