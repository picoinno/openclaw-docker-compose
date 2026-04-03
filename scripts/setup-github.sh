#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# OpenClaw — GitHub Credentials Setup
# ============================================================
# Wires GitHub PAT tokens into the container's git credential
# store so the agent can push/pull without manual auth.
#
# Tokens are read from environment variables — never hardcoded.
# Run this after first boot or after adding new tokens.
#
# Usage (on the host):
#   docker compose run --rm openclaw-cli bash /home/node/.openclaw/workspace/scripts/setup-github.sh
#
# Or from inside the container:
#   bash scripts/setup-github.sh
#
# Required env vars (set in .env):
#   GITHUB_TOKEN_PICOINNO   — PAT for picoinno personal account
#   GITHUB_TOKEN_PICO_INNO  — PAT for pico-inno org
#
# Optional:
#   GITHUB_TOKEN_MIJN_UI    — PAT for mijn-ui org
#   GITHUB_TOKEN_SANNKOKO   — PAT for sannkoko org
#
# Tokens are stored in ~/.git-credentials (inside the container).
# Mount a persistent volume for /home/node to survive restarts.
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CREDS_FILE="${HOME}/.git-credentials"
GIT_CONFIG="${HOME}/.gitconfig"

touch "$CREDS_FILE"
chmod 600 "$CREDS_FILE"

write_token() {
  local username="$1"
  local token="$2"
  local org="${3:-$username}"

  # Remove existing entry for this user
  if [[ -f "$CREDS_FILE" ]]; then
    grep -v "https://${username}:" "$CREDS_FILE" > "${CREDS_FILE}.tmp" || true
    mv "${CREDS_FILE}.tmp" "$CREDS_FILE"
  fi

  echo "https://${username}:${token}@github.com" >> "$CREDS_FILE"
  echo -e "${GREEN}✓${NC} Token stored for: ${username}"
}

write_gitconfig_url() {
  local username="$1"
  local org="$2"

  # Only add if not already present
  if ! git config --global --get-all "url.https://${username}@github.com/${org}/.insteadOf" &>/dev/null; then
    git config --global "url.https://${username}@github.com/${org}/.insteadOf" "https://github.com/${org}/"
    echo -e "${GREEN}✓${NC} URL rewrite set for: ${org}"
  fi
}

# Ensure git uses credential store
git config --global credential.helper store
git config --global user.name "${GIT_USER_NAME:-OpenClaw Agent}"
git config --global user.email "${GIT_USER_EMAIL:-agent@openclaw.ai}"

CONFIGURED=0

# picoinno (personal)
if [[ -n "${GITHUB_TOKEN_PICOINNO:-}" ]]; then
  write_token "picoinno" "$GITHUB_TOKEN_PICOINNO"
  write_gitconfig_url "picoinno" "picoinno"
  CONFIGURED=$((CONFIGURED + 1))
else
  echo -e "${YELLOW}⚠${NC}  GITHUB_TOKEN_PICOINNO not set — skipping"
fi

# pico-inno (org)
if [[ -n "${GITHUB_TOKEN_PICO_INNO:-}" ]]; then
  write_token "pico-inno" "$GITHUB_TOKEN_PICO_INNO"
  write_gitconfig_url "pico-inno" "pico-inno"
  CONFIGURED=$((CONFIGURED + 1))
else
  echo -e "${YELLOW}⚠${NC}  GITHUB_TOKEN_PICO_INNO not set — skipping"
fi

# mijn-ui (org, optional)
if [[ -n "${GITHUB_TOKEN_MIJN_UI:-}" ]]; then
  write_token "mijn-ui" "$GITHUB_TOKEN_MIJN_UI"
  write_gitconfig_url "mijn-ui" "mijn-ui"
  CONFIGURED=$((CONFIGURED + 1))
fi

# sannkoko (org, optional)
if [[ -n "${GITHUB_TOKEN_SANNKOKO:-}" ]]; then
  write_token "sannkoko" "$GITHUB_TOKEN_SANNKOKO"
  write_gitconfig_url "sannkoko" "sannkoko"
  CONFIGURED=$((CONFIGURED + 1))
fi

echo ""
if [[ $CONFIGURED -gt 0 ]]; then
  echo -e "${GREEN}GitHub credentials configured: ${CONFIGURED} token(s)${NC}"
else
  echo -e "${RED}No tokens configured. Set GITHUB_TOKEN_* vars in .env and re-run.${NC}"
  exit 1
fi
