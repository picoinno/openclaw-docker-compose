#!/usr/bin/env bash
# ============================================================
# OpenClaw — Initialize Config with Model from .env
# ============================================================
# Run this ONCE after first boot to set the AI model in openclaw.json.
# Reads AI_MODEL from .env (or pass as argument).
#
# Usage:
#   ./scripts/init-config.sh                    # Uses AI_MODEL from .env
#   ./scripts/init-config.sh openai/gpt-4o      # Pass model directly
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="${PROJECT_DIR}/data/.openclaw/openclaw.json"
ENV_FILE="${PROJECT_DIR}/.env"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get model from argument, .env, or ask
MODEL="${1:-}"

if [[ -z "$MODEL" ]] && [[ -f "$ENV_FILE" ]]; then
  MODEL=$(grep "^AI_MODEL=" "$ENV_FILE" 2>/dev/null | cut -d= -f2)
fi

if [[ -z "$MODEL" ]]; then
  echo -e "${YELLOW}No AI_MODEL found in .env and no argument provided.${NC}"
  echo ""
  echo "Common models:"
  echo "  anthropic/claude-sonnet-4-20250514"
  echo "  anthropic/claude-opus-4-6"
  echo "  openai/gpt-4o"
  echo "  openai/gpt-4o-mini"
  echo "  openrouter/anthropic/claude-3.5-sonnet"
  echo "  ollama/llama3"
  echo ""
  read -rp "Enter model (provider/model-name): " MODEL
fi

if [[ -z "$MODEL" ]]; then
  echo -e "${RED}No model specified. Exiting.${NC}"
  exit 1
fi

# Wait for openclaw.json to exist (created on first boot)
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${YELLOW}openclaw.json not found yet. Starting gateway to generate it...${NC}"
  cd "$PROJECT_DIR"
  docker compose up -d openclaw-gateway
  echo "Waiting for config to be created..."
  for i in $(seq 1 30); do
    [[ -f "$CONFIG_FILE" ]] && break
    sleep 2
    echo -n "."
  done
  echo ""
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${RED}openclaw.json still not found after 60s. Check gateway logs.${NC}"
  exit 1
fi

# Update model in openclaw.json
if command -v python3 &>/dev/null; then
  python3 -c "
import json
with open('${CONFIG_FILE}') as f:
    cfg = json.load(f)
if 'agents' not in cfg:
    cfg['agents'] = {}
if 'defaults' not in cfg['agents']:
    cfg['agents']['defaults'] = {}
cfg['agents']['defaults']['model'] = '${MODEL}'
with open('${CONFIG_FILE}', 'w') as f:
    json.dump(cfg, f, indent=2)
"
  echo -e "${GREEN}✓${NC} Model set to: ${MODEL}"
else
  # Fallback: use sed
  if grep -q '"model"' "$CONFIG_FILE"; then
    sed -i "s|\"model\": *\"[^\"]*\"|\"model\": \"${MODEL}\"|" "$CONFIG_FILE"
    echo -e "${GREEN}✓${NC} Model set to: ${MODEL}"
  else
    echo -e "${RED}Could not update config. Please edit manually:${NC}"
    echo "  File: ${CONFIG_FILE}"
    echo "  Set: agents.defaults.model = \"${MODEL}\""
    exit 1
  fi
fi

# Restart gateway to apply
echo ""
read -rp "Restart gateway now? (Y/n): " DO_RESTART
if [[ "$DO_RESTART" != "n" && "$DO_RESTART" != "N" ]]; then
  cd "$PROJECT_DIR"
  docker compose restart openclaw-gateway
  echo -e "${GREEN}✓${NC} Gateway restarted with model: ${MODEL}"
fi
