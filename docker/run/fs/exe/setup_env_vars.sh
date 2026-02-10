#!/bin/bash

# Setup environment variables for Agent Zero
# This script reads environment variables and writes them to usr/secrets.env and usr/settings.json

echo "Setting up environment variables..."

# Ensure usr directory exists
mkdir -p /a0/usr

# Secrets file path
SECRETS_FILE="/a0/usr/secrets.env"
SETTINGS_FILE="/a0/usr/settings.json"

# Function to add or update a key in secrets file
# Usage: add_secret "KEY" "value"
add_secret() {
    local key="$1"
    local value="$2"

    if [ -z "$value" ]; then
        return
    fi

    # Create file if it doesn't exist
    if [ ! -f "$SECRETS_FILE" ]; then
        touch "$SECRETS_FILE"
    fi

    # Check if key already exists
    if grep -q "^${key}=" "$SECRETS_FILE" 2>/dev/null; then
        # Key exists, update it (preserve in-place to avoid breaking sed on some systems)
        # Use a temp file for safety
        temp_file=$(mktemp)
        sed "s/^${key}=.*/${key}=\"${value}\"/" "$SECRETS_FILE" > "$temp_file"
        mv "$temp_file" "$SECRETS_FILE"
    else
        # Key doesn't exist, append it
        echo "${key}=\"${value}\"" >> "$SECRETS_FILE"
    fi

    echo "Set secret: ${key}"
}

# Function to update settings JSON
# Usage: update_setting "key" "value"
update_setting() {
    local key="$1"
    local value="$2"

    if [ ! -f "$SETTINGS_FILE" ]; then
        # Create default settings file if it doesn't exist
        echo '{"version":"local"}' > "$SETTINGS_FILE"
    fi

    # Use python to update JSON (more reliable than sed for JSON)
    python3 -c "
import json
import sys

try:
    with open('$SETTINGS_FILE', 'r') as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

settings['$key'] = $value

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=4)
" 2>/dev/null && echo "Set setting: $key = $value"
}

# Process Telegram Bot environment variables
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    add_secret "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN"
    # Enable telegram bot in settings
    update_setting "telegram_bot_enabled" "true"
fi

if [ -n "$TELEGRAM_BOT_ALLOWED_USERS" ]; then
    add_secret "TELEGRAM_BOT_ALLOWED_USERS" "$TELEGRAM_BOT_ALLOWED_USERS"
fi

# Process API keys
if [ -n "$OPENROUTER_API_KEY" ]; then
    add_secret "API_KEY_OPENROUTER" "$OPENROUTER_API_KEY"
fi

# Process authentication
if [ -n "$AUTH_LOGIN" ]; then
    add_secret "AUTH_LOGIN" "$AUTH_LOGIN"
fi

if [ -n "$AUTH_PASSWORD" ]; then
    add_secret "AUTH_PASSWORD" "$AUTH_PASSWORD"
fi

echo "Environment variables setup complete."
