#!/bin/bash

# Setup environment variables for Agent Zero
# This script reads environment variables and writes them to usr/secrets.env and usr/settings.json
# The app works fine without any environment variables - this is optional configuration

# Setup logging - show errors by default, show details if VERBOSE_SETUP=true
if [ -n "$VERBOSE_SETUP" ]; then
    echo "[setup_env_vars] Starting environment variable setup..."
    exec 2>&1  # Show all output
else
    exec 2>&1  # Show errors but redirect stdout to /dev/null later
    exec >/dev/null
fi

echo "[setup_env_vars] Setting up environment variables..."

# Ensure usr directory exists
mkdir -p /a0/usr 2>/dev/null

if [ ! -d "/a0/usr" ]; then
    echo "[setup_env_vars] ERROR: Cannot create /a0/usr directory"
    exit 0
fi

# Secrets file path - in /a0/usr/secrets.env
SECRETS_FILE="/a0/usr/secrets.env"
# Settings file path - in /a0/usr/settings.json
SETTINGS_FILE="/a0/usr/settings.json"

# Track if any changes were made
CHANGES_MADE=false

# Function to add or update a key in secrets file
# Usage: add_secret "KEY" "value"
add_secret() {
    local key="$1"
    local value="$2"

    # Skip if value is empty
    [ -z "$value" ] && return 0

    # Create file if it doesn't exist
    [ ! -f "$SECRETS_FILE" ] && touch "$SECRETS_FILE" 2>/dev/null

    # Check if key already exists
    if grep -q "^${key}=" "$SECRETS_FILE" 2>/dev/null; then
        # Key exists, update it
        temp_file=$(mktemp 2>/dev/null) || return 1
        sed "s/^${key}=.*/${key}=\"${value}\"/" "$SECRETS_FILE" > "$temp_file" 2>/dev/null && mv "$temp_file" "$SECRETS_FILE" 2>/dev/null
    else
        # Key doesn't exist, append it
        echo "${key}=\"${value}\"" >> "$SECRETS_FILE" 2>/dev/null
    fi

    CHANGES_MADE=true
    echo "[setup_env_vars] Set: $key"
}

# Function to update settings JSON
# Usage: update_setting "key" "value"
update_setting() {
    local key="$1"
    local value="$2"

    # Skip if value is empty
    [ -z "$value" ] && return 0

    # Create default settings file if it doesn't exist
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo '{"version":"local"}' > "$SETTINGS_FILE" 2>/dev/null || return 1
    fi

    # Try to update JSON, but don't fail if it doesn't work
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json
try:
    with open('$SETTINGS_FILE', 'r') as f:
        settings = json.load(f)
except:
    settings = {}
settings['$key'] = $value
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=4)
" 2>/dev/null && CHANGES_MADE=true && echo "[setup_env_vars] Set setting: $key = $value"
    fi
}

# Debug: Show environment variables (only in verbose mode)
if [ -n "$VERBOSE_SETUP" ]; then
    echo "[setup_env_vars] Environment variables found:"
    [ -n "$TELEGRAM_BOT_TOKEN" ] && echo "  TELEGRAM_BOT_TOKEN: ***set***"
    [ -n "$TELEGRAM_BOT_ALLOWED_USERS" ] && echo "  TELEGRAM_BOT_ALLOWED_USERS: $TELEGRAM_BOT_ALLOWED_USERS"
    [ -n "$OPENROUTER_API_KEY" ] && echo "  OPENROUTER_API_KEY: ***set***"
    [ -n "$API_KEY_OPENAI" ] && echo "  API_KEY_OPENAI: ***set***"
    [ -n "$AUTH_LOGIN" ] && echo "  AUTH_LOGIN: $AUTH_LOGIN"
fi

# Process environment variables (all optional)
# The app works perfectly fine without any of these

# Telegram Bot (optional)
[ -n "$TELEGRAM_BOT_TOKEN" ] && add_secret "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN"
[ -n "$TELEGRAM_BOT_TOKEN" ] && update_setting "telegram_bot_enabled" "true"
[ -n "$TELEGRAM_BOT_ALLOWED_USERS" ] && add_secret "TELEGRAM_BOT_ALLOWED_USERS" "$TELEGRAM_BOT_ALLOWED_USERS"

# LLM API Keys (optional - can be configured in UI later)
[ -n "$OPENROUTER_API_KEY" ] && add_secret "API_KEY_OPENROUTER" "$OPENROUTER_API_KEY"
[ -n "$API_KEY_OPENAI" ] && add_secret "API_KEY_OPENAI" "$API_KEY_OPENAI"

# Authentication (optional - can be configured in UI later)
[ -n "$AUTH_LOGIN" ] && add_secret "AUTH_LOGIN" "$AUTH_LOGIN"
[ -n "$AUTH_PASSWORD" ] && add_secret "AUTH_PASSWORD" "$AUTH_PASSWORD"

if [ "$CHANGES_MADE" = true ]; then
    echo "[setup_env_vars] Configuration complete."
else
    echo "[setup_env_vars] No environment variables to configure (this is normal - configure in UI instead)."
fi

exit 0
