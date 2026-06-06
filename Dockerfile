FROM plexinc/pms-docker:latest

# 1. Install Rclone, Python, and system prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
    rclone \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 2. Install automation libraries
RUN pip3 install --no-cache-dir --break-system-packages gspread google-auth

# 3. Establish storage locations across both root and config spaces
RUN mkdir -p /root/.config/rclone /root/.config/gdrive /config/.config/rclone /app

# 4. Create the automated Google Sheet reader
RUN echo 'import gspread\n\
import os\n\
from google.oauth2.service_account import Credentials\n\
\n\
try:\n\
    scopes = ["https://www.googleapis.com/auth/spreadsheets.readonly"]\n\
    creds = Credentials.from_service_account_file("/root/.config/gdrive/sa.json", scopes=scopes)\n\
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

# 5. Open Plex routing interface port
EXPOSE 32400

# 6. Service boot sequence: Sanitizes and saves secrets, mounts drive, pulls the token, and launches Plex
CMD python3 -c 'import os, json; data=os.environ.get("GDRIVE_SA_JSON","{}"); print(json.dumps(json.loads(data)))' > /root/.config/gdrive/sa.json 2>/dev/null || echo "$GDRIVE_SA_JSON" > /root/.config/gdrive/sa.json && \
    echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    cp /root/.config/rclone/rclone.conf /config/.config/rclone/rclone.conf && \
    rclone serve webdav gdrive: --addr 127.0.0.1:8080 & \
    python3 /app/get_token.py && \
    if [ -f /app/token.txt ]; then export PLEX_CLAIM=$(cat /app/token.txt); fi && \
    sleep 2 && \
    exec /init
