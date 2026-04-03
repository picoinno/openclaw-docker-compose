#!/usr/bin/env bash
# ============================================================
# OpenClaw — Initialize Config with Model from .env
# ============================================================
# Run this ONCE after first boot to apply the optimized config
# template and set the AI model.
#
# Usage:
#   ./scripts/init-config.sh                    # Uses AI_MODEL from .env
#   ./scripts/init-config.sh openai/gpt-4o      # Pass model directly
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="${PROJECT_DIR}/data/.openclaw/openclaw.json"
TEMPLATE_FILE="${PROJECT_DIR}/openclaw.json.template"
ENV_FILE="${PROJECT_DIR}/.env"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Get model ---
MODEL="${1:-}"

if [[ -z "$MODEL" ]] && [[ -f "$ENV_FILE" ]]; then
  MODEL=$(grep "^AI_MODEL=" "$ENV_FILE" 2>/dev/null | cut -d= -f2)
fi

if [[ -z "$MODEL" ]]; then
  echo -e "${YELLOW}No AI_MODEL found in .env and no argument provided.${NC}"
  echo ""
  echo "Common models:"
  echo "  anthropic/claude-sonnet-4-6         (recommended, fast)"
  echo "  anthropic/claude-opus-4-6           (smartest, expensive)"
  echo "  openai/gpt-4o"
  echo "  openai/gpt-4o-mini                  (fast, cheap)"
  echo "  openrouter/google/gemini-2.5-pro"
  echo "  ollama/llama3                        (local, free)"
  echo ""
  read -rp "Enter model (provider/model-name): " MODEL
fi

if [[ -z "$MODEL" ]]; then
  echo -e "${RED}No model specified. Exiting.${NC}"
  exit 1
fi

# --- Wait for gateway to create config (or apply template) ---
if [[ ! -f "$CONFIG_FILE" ]]; then
  if [[ -f "$TEMPLATE_FILE" ]]; then
    echo -e "${YELLOW}openclaw.json not found. Applying template...${NC}"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    sed "s|__AI_MODEL__|${MODEL}|g" "$TEMPLATE_FILE" > "$CONFIG_FILE"
    echo -e "${GREEN}✓${NC} Config created from template with model: ${MODEL}"
  else
    echo -e "${YELLOW}openclaw.json not found. Starting gateway to generate it...${NC}"
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
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${RED}openclaw.json not found after 60s. Check gateway logs.${NC}"
  exit 1
fi

# --- Apply template if it exists and config is bare (no optimization keys) ---
if [[ -f "$TEMPLATE_FILE" ]] && ! grep -q "contextPruning" "$CONFIG_FILE" 2>/dev/null; then
  echo -e "${YELLOW}Applying optimized config template...${NC}"
  sed "s|__AI_MODEL__|${MODEL}|g" "$TEMPLATE_FILE" > "$CONFIG_FILE"
  echo -e "${GREEN}✓${NC} Optimized config applied"
else
  # Just update the model in existing config
  if command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('${CONFIG_FILE}') as f:
    cfg = json.load(f)
if 'agents' not in cfg:
    cfg['agents'] = {}
if 'defaults' not in cfg['agents']:
    cfg['agents']['defaults'] = {}
m = cfg['agents']['defaults'].get('model', {})
if isinstance(m, dict):
    m['primary'] = '${MODEL}'
    cfg['agents']['defaults']['model'] = m
else:
    cfg['agents']['defaults']['model'] = {'primary': '${MODEL}'}
with open('${CONFIG_FILE}', 'w') as f:
    json.dump(cfg, f, indent=2)
"
    echo -e "${GREEN}✓${NC} Model set to: ${MODEL}"
  else
    echo -e "${RED}python3 not found — update openclaw.json manually.${NC}"
    exit 1
  fi
fi

# --- Restart gateway ---
echo ""
read -rp "Restart gateway now? (Y/n): " DO_RESTART
if [[ "$DO_RESTART" != "n" && "$DO_RESTART" != "N" ]]; then
  cd "$PROJECT_DIR"
  docker compose restart openclaw-gateway
  echo -e "${GREEN}✓${NC} Gateway restarted with model: ${MODEL}"
fi
