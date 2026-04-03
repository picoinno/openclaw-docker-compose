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
# Usage:
#   docker compose run --rm openclaw-cli bash \
#     /home/node/.openclaw/workspace/scripts/setup-github.sh
#
# Required env vars (set in .env):
#   GITHUB_USERNAME_1 + GITHUB_TOKEN_1  — first account/org
#   GITHUB_USERNAME_2 + GITHUB_TOKEN_2  — second account/org (optional)
#   ... add more pairs as needed
#
# Tokens are stored in ~/.git-credentials inside the container.
# Mount a persistent volume for /home/node to survive restarts.
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CREDS_FILE="${HOME}/.git-credentials"
touch "$CREDS_FILE"
chmod 600 "$CREDS_FILE"

# Ensure git uses credential store
git config --global credential.helper store
git config --global user.name "${GIT_USER_NAME:-OpenClaw Agent}"
git config --global user.email "${GIT_USER_EMAIL:-agent@openclaw.ai}"

CONFIGURED=0

# Loop over GITHUB_USERNAME_N / GITHUB_TOKEN_N pairs
for i in $(seq 1 10); do
  username_var="GITHUB_USERNAME_${i}"
  token_var="GITHUB_TOKEN_${i}"

  username="${!username_var:-}"
  token="${!token_var:-}"

  # Stop when no more pairs
  [[ -z "$username" && -z "$token" ]] && break

  if [[ -z "$username" || -z "$token" ]]; then
    echo -e "${YELLOW}⚠${NC}  Pair ${i}: missing username or token — skipping"
    continue
  fi

  # Remove existing entry for this user
  grep -v "https://${username}:" "$CREDS_FILE" > "${CREDS_FILE}.tmp" 2>/dev/null || true
  mv "${CREDS_FILE}.tmp" "$CREDS_FILE"

  # Write new entry
  echo "https://${username}:${token}@github.com" >> "$CREDS_FILE"

  # Set URL rewrite so git auto-uses the right token
  git config --global \
    "url.https://${username}@github.com/${username}/.insteadOf" \
    "https://github.com/${username}/"

  echo -e "${GREEN}✓${NC} Token configured for: ${username}"
  CONFIGURED=$((CONFIGURED + 1))
done

echo ""
if [[ $CONFIGURED -gt 0 ]]; then
  echo -e "${GREEN}Done. ${CONFIGURED} GitHub account(s) configured.${NC}"
  echo ""
  echo "Next: update data/workspace/GITHUB.md with your account details"
  echo "so the agent knows what it has access to."
else
  echo -e "${RED}No tokens configured.${NC}"
  echo "Add GITHUB_USERNAME_1 + GITHUB_TOKEN_1 to .env and re-run."
  exit 1
fi
