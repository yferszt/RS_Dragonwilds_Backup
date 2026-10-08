#!/usr/bin/env bash

# ============================================================
# Version 1.0
# Description:
# This script connects via FTP to a remote RuneScape Dragonwilds
# server and backs up save files to your local system.
# If enabled, it sends failure notifications via Telegram.
#
# Tested:
# Debian 13 (works on most Linux distributions)
#
# Requires:
# lftp, curl
#
# Disclaimer:
# Provided "as is" without warranty of any kind. The author(s)
# accept no responsibility or liability for data loss or damages.
# ============================================================

# -----------------------------
# Configuration
# -----------------------------

# FTP server credentials
FTP_HOST="GAME_SERVER_IP"
FTP_USER="FTP_USER_NAME"
FTP_PASSWORD="FTP_PASSWORD"

# Remote location
REMOTE_PATH="REPLACE_WITH_PATH_TO_SAVE_FILES_LOCATION" # e.g., "/gameserver/RSDragonwilds/Saved/SaveGames/"
REMOTE_FILE="REPLACE_WITH_SAVE_FILE_NAME.sav"           # e.g., "WORLD_NAME.sav"

# Local backup directory
LOCAL_PATH="REPLACE_ME" # e.g., "gamebackups/Runescape-Dragonwilds/"

# Number of backups to keep
BACKUPS_TO_KEEP=20

# Telegram configuration
USE_TELEGRAM="true"                                     # Set to "true" to enable, "false" to disable
TELEGRAM_BOT_TOKEN="REPLACE_WITH_BOT_TOKEN"
TELEGRAM_CHAT_ID="REPLACE_WITH_CHAT_ID"

# -----------------------------
# End of configuration
# -----------------------------


# ============================================================
# VALIDATE CONFIGURATION
# ============================================================

if [[ "${FTP_HOST}" == "GAME_SERVER_IP" || \
      "${LOCAL_PATH}" == "REPLACE_ME" || \
      "${REMOTE_PATH}" == *"REPLACE_WITH"* || \
      "${REMOTE_FILE}" == *"REPLACE_WITH"* ]]; then
    echo "ERROR: Please configure the script parameters before running."
    exit 1
fi


# ============================================================
# FUNCTIONS
# ============================================================

send_telegram()
{
    local MESSAGE="$1"

    # Skip if disabled via configuration
    if [[ "${USE_TELEGRAM,,}" != "true" ]]; then
        return 0
    fi

    # Skip if placeholder values were left unconfigured
    if [[ "${TELEGRAM_BOT_TOKEN}" == "REPLACE_WITH_BOT_TOKEN" || \
          "${TELEGRAM_CHAT_ID}" == "REPLACE_WITH_CHAT_ID" ]]; then
        echo "Telegram is enabled but not properly configured. Skipping alert."
        return 0
    fi

    curl -fsS \
        --max-time 15 \
        -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${MESSAGE}" \
        >/dev/null || true
}


backup_failed()
{
    local EXIT_CODE=$?

    echo
    echo "=============================================="
    echo "ERROR: BACKUP FAILED"
    echo "=============================================="
    echo "Exit code: ${EXIT_CODE}"
    echo

    send_telegram "❌ Dragonwilds backup FAILED

Server: ${FTP_HOST}
Remote path: ${REMOTE_PATH}
File: ${REMOTE_FILE}
Time: $(date '+%Y-%m-%d %H:%M:%S')
Exit code: ${EXIT_CODE}"

    exit "${EXIT_CODE}"
}


trap backup_failed ERR


# ============================================================
# PREPARE
# ============================================================

# Strip trailing slashes from LOCAL_PATH and leading slashes from REMOTE_FILE
LOCAL_PATH="${LOCAL_PATH%/}"
REMOTE_FILE="${REMOTE_FILE#/}"

mkdir -p "${LOCAL_PATH}"

TIMESTAMP=$(date '+%Y.%m.%d-%H:%M')

BACKUP_FILE="${REMOTE_FILE}-${TIMESTAMP}.bak"
LOCAL_FILE="${LOCAL_PATH}/${BACKUP_FILE}"


echo
echo "=============================================="
echo "Dragonwilds Save Game Backup"
echo "=============================================="
echo
echo "FTP server:"
echo "  ${FTP_HOST}"
echo
echo "Remote path:"
echo "  ${REMOTE_PATH}"
echo
echo "Remote file:"
echo "  ${REMOTE_FILE}"
echo
echo "Local file:"
echo "  ${LOCAL_FILE}"
echo
echo "=============================================="
echo


# ============================================================
# DOWNLOAD
# ============================================================

echo "Starting download..."

# Escape spaces and backslashes for the lftp parser
LFTP_REMOTE_FILE="${REMOTE_FILE//\\/\\\\}"
LFTP_REMOTE_FILE="${LFTP_REMOTE_FILE// /\\ }"

LFTP_LOCAL_FILE="${LOCAL_FILE//\\/\\\\}"
LFTP_LOCAL_FILE="${LFTP_LOCAL_FILE// /\\ }"


lftp \
    -u "${FTP_USER},${FTP_PASSWORD}" \
    "ftp://${FTP_HOST}" <<EOF

set ftp:passive-mode true
set net:timeout 30
set net:max-retries 3
set net:reconnect-interval-base 5

cd ${REMOTE_PATH}

get ${LFTP_REMOTE_FILE} -o ${LFTP_LOCAL_FILE}

bye
EOF


# ============================================================
# VERIFY DOWNLOAD
# ============================================================

echo
echo "Verifying downloaded file..."


if [[ ! -f "${LOCAL_FILE}" ]]; then
    echo "ERROR: Downloaded file does not exist."
    exit 1
fi


if [[ ! -s "${LOCAL_FILE}" ]]; then
    echo "ERROR: Downloaded file is empty."

    rm -f -- "${LOCAL_FILE}"

    exit 1
fi


FILE_SIZE=$(du -h "${LOCAL_FILE}" | cut -f1)


echo
echo "Download successful."
echo "File: ${LOCAL_FILE}"
echo "Size: ${FILE_SIZE}"


# ============================================================
# REMOVE OLD BACKUPS
# ============================================================

echo
echo "Checking old backups..."


mapfile -t BACKUP_FILES < <(
    find "${LOCAL_PATH}" \
        -maxdepth 1 \
        -type f \
        -name "${REMOTE_FILE}-*.bak" \
        -printf '%T@ %p\n' |
    sort -rn |
    cut -d' ' -f2-
)


BACKUP_COUNT=${#BACKUP_FILES[@]}


echo "Backups found: ${BACKUP_COUNT}"
echo "Backups to keep: ${BACKUPS_TO_KEEP}"


if [[ -n "${LOCAL_PATH}" && -d "${LOCAL_PATH}" ]] && (( BACKUPS_TO_KEEP > 0 )); then

    if (( BACKUP_COUNT > BACKUPS_TO_KEEP )); then

        echo
        echo "Removing old backups..."

        for (( i=BACKUPS_TO_KEEP; i<BACKUP_COUNT; i++ )); do

            OLD_BACKUP="${BACKUP_FILES[$i]}"

            echo "Deleting:"
            echo "  ${OLD_BACKUP}"

            rm -f -- "${OLD_BACKUP}"

        done

    fi

fi


# ============================================================
# SUCCESS
# ============================================================

echo
echo "=============================================="
echo "BACKUP SUCCESSFUL"
echo "=============================================="
echo
echo "Backup:"
echo "  ${LOCAL_FILE}"
echo
echo "Size:"
echo "  ${FILE_SIZE}"
echo
echo "Backups retained:"
echo "  ${BACKUPS_TO_KEEP}"
echo
