# RuneScape Dragonwilds Save Game Backup Script

An automated Bash script designed to connect to a remote **RuneScape Dragonwilds** dedicated server via FTP, securely download the world save file, add a timestamp, and enforce a custom retention policy (auto-deleting old backups). If a backup fails, the script can optionally alert you via Telegram.

---

> [!CAUTION]
> **Disclaimer & Limitation of Liability**  
> This script is provided **"as is"**, without warranty of any kind, express or implied. The author(s) and contributor(s) accept **no responsibility or liability** for any loss, corruption, or damage to game save files, server data, systems, or hardware resulting from the use or misuse of this script. Use it entirely at your own risk. Always verify and manually double-check your backups.

---

## Features

- **Automated FTP Download:** Handles filenames with spaces or special characters safely.
- **Verification:** Ensures the downloaded file exists and is not zero bytes before keeping it.
- **Retention Management:** Automatically cleans up older backups, keeping only the specified number of recent files.
- **Configurable Telegram Alerts:** Send instant error alerts directly to a Telegram chat using the Telegram Bot API (can be toggled on/off).
- **Safety Checks:** Guarantees proper configuration and path sanitization before execution.

---

## Prerequisites

This script has been tested on **Debian 13**, but it will run on almost any Linux system. 

Ensure the following tools are installed on your host system:

* **lftp** – For robust FTP client connections.
* **curl** – For sending Telegram API notifications (required if Telegram alerts are enabled).

### Installing Dependencies

**Debian / Ubuntu:**
```bash
sudo apt update
sudo apt install lftp curl
```

**Fedora / RHEL / CentOS:**
```bash
sudo dnf install lftp curl
```

**Arch Linux:**
```bash
sudo pacman -S lftp curl
```

---

## Configuration & Usage

Open the backup script (`backup.sh`) in your text editor and modify the parameters in the **Configuration** section near the top of the file:

```bash
# -----------------------------
# Configuration
# -----------------------------

# FTP server credentials
FTP_HOST="GAME_SERVER_IP"                              # IP address or domain of your game server
FTP_USER="FTP_USER_NAME"                              # FTP username
FTP_PASSWORD="FTP_PASSWORD"                          # FTP password

# Remote location
REMOTE_PATH="/gameserver/RSDragonwilds/Saved/SaveGames/" # Remote directory path ending in a slash
REMOTE_FILE="WORLD_NAME.sav"                            # Name of the save file on the server

# Local backup directory
LOCAL_PATH="gamebackups/Runescape-Dragonwilds/"          # Local folder path to store backups

# Retention Policy
BACKUPS_TO_KEEP=20                                       # Number of recent backups to retain

# Telegram Notifications
USE_TELEGRAM="true"                                     # Set to "true" to enable, "false" to disable
TELEGRAM_BOT_TOKEN="REPLACE_WITH_BOT_TOKEN"             # Telegram Bot Token from @BotFather
TELEGRAM_CHAT_ID="REPLACE_WITH_CHAT_ID"                 # Target Chat ID for alerts
```

---

## How to Set Up a Telegram Bot (Optional)

If `USE_TELEGRAM="true"` is set, you can receive failure notifications directly on your phone or desktop:

1. **Create a Bot:**
   - Open Telegram and search for [@BotFather](https://t.me/BotFather).
   - Send `/newbot` and follow the prompts to choose a name and username.
   - Copy the provided **HTTP API Token** and paste it into `TELEGRAM_BOT_TOKEN`.
   - Read official instructions at the [Telegram Bot Father Guide](https://core.telegram.org/bots/features#botfather).

2. **Get Your Chat ID:**
   - Send a message to your new bot or add it to a group.
   - Use a helper bot like [@userinfobot](https://t.me/userinfobot) or open `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates` in your browser to locate your `chat_id`.
   - Paste this value into `TELEGRAM_CHAT_ID`.

For more details, check out the [Telegram Bots Getting Started Guide](https://core.telegram.org/bots#launching-your-telegram-bot).

---

## Running the Script

1. Make the script executable:
   ```bash
   chmod +x RS_dragonwilds_backup.sh
   ```

2. Execute it manually:
   ```bash
   ./RS_dragonwilds_backup.sh
   ```

3. *(Optional)* Schedule regular backups via `cron`:
   ```bash
   crontab -e
   ```
   Add a line like this to run every day at midnight:
   ```cron
   0 0 * * * /path/to/RS_dragonwilds_backup.sh >/dev/null 2>&1
   ```

---

## License

This project is open-source and licensed under the [MIT License](LICENSE).
