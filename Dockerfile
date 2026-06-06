FROM plexinc/pms-docker:latest

# 1. Install Rclone, Python, and dependencies via Ubuntu's package manager (Plex base image uses Ubuntu)
RUN apt-get update && apt-get install -y --no-install-recommends \
    rclone \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Python packages for Google Sheets automation
RUN pip3 install --no-cache-dir gspread google-auth

# 3. Create necessary data and configuration directories
RUN mkdir -p /root/.config/rclone /root/.config/gdrive /app

# 4. Create the automation script that reads your Google Sheet
RUN echo 'import gspread\n\
import os\n\
from google.oauth2.service_account import Credentials\n\
\n\
try:\n\
    scopes = ["https://www.googleapis.com/auth/spreadsheets.readonly"]\n\
    creds = Credentials.from_service_account_file("/root/.config/gdrive/sa.json", scopes=scopes)\n\
    client = gspread.authorize(creds)\n\
    \n\
    # Opens your sheet by its unique URL ID variable\n\
    sheet = client.open_by_key(os.environ["GOOGLE_SHEET_ID"]).sheet1\n\
    \n\
    # Grabs the very last row of data\n\
    all_values = sheet.get_all_values()\n\
    if all_values:\n\
        latest_token = all_values[-1][0].strip() # Assumes token is in Column A\n\
        print(f"SUCCESS: Found latest token: {latest_token}")\n\
        with open("/app/token.txt", "w") as f:\n\
            f.write(latest_token)\n\
except Exception as e:\n\
    print(f"ERROR reading sheet: {e}")\n\
' > /app/get_token.py

# 5. Route Traffic to Plex's default internal port
EXPOSE 32400

# 6. Override the startup sequence: Saves secrets, updates the claim token variable, and hands off to Plex
CMD echo "$GDRIVE_SA_JSON" > /root/.config/gdrive/sa.json && \
    echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    rclone serve webdav gdrive: --addr 127.0.0.1:8080 & \
    python3 /app/get_token.py && \
    if [ -f /app/token.txt ]; then export PLEX_CLAIM=$(cat /app/token.txt); fi && \
    sleep 2 && \
    exec /init
