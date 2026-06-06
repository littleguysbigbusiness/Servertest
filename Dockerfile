FROM alpine:latest

# 1. Install Plex, Rclone, Python, Google dependencies, and standard libraries
RUN apk add --no-cache rclone curl ca-certificates openssh plexmediaserver python3 py3-pip && \
    pip3 install --break-system-packages gspread google-auth

# 2. Configure SSH for fallback troubleshooting
RUN ssh-keygen -A && \
    echo 'root:mysecurepassword' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 3. Create necessary application folders
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
    # Opens your sheet by its URL ID\n\
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

# 5. Route traffic
EXPOSE 32400 22

# 6. Startup script: Saves credentials, runs the Python finder, exports token, boots Plex
CMD echo "$GDRIVE_SA_JSON" > /root/.config/gdrive/sa.json && \
    echo "$RCLONE_CONFIG_DATA" > /root/.config/rclone/rclone.conf && \
    /usr/sbin/sshd -D & \
    rclone serve webdav gdrive: --addr 127.0.0.1:8080 & \
    python3 /app/get_token.py && \
    if [ -f /app/token.txt ]; then export PLEX_CLAIM=$(cat /app/token.txt); fi && \
    sleep 3 && \
    exec /usr/lib/plexmediaserver/Plex\ Media\ Server --port 32400
