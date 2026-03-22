#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# OpenClaw — Switch AI Provider
# ============================================================
# Interactive script to change your AI provider and model.
# Updates .env and openclaw.json, then restarts the gateway.
#
# Usage: ./scripts/switch-provider.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${PROJECT_DIR}/.env"
CONFIG_FILE="${PROJECT_DIR}/data/.openclaw/openclaw.json"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check .env exists
if [[ ! -f "$ENV_FILE" ]]; then
  echo -e "${RED}No .env file found. Run setup first.${NC}"
  exit 1
fi

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}  OpenClaw — Switch AI Provider${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# Step 1: Pick provider
echo -e "${CYAN}Which AI provider?${NC}"
echo ""
echo "  1) Anthropic (Claude)"
echo "  2) OpenAI (GPT)"
echo "  3) OpenRouter (100+ models)"
echo "  4) Ollama (local, free)"
echo "  5) Google Gemini"
echo "  6) Groq (fast inference)"
echo "  7) Mistral"
echo ""
read -rp "Enter number (1-7): " PROVIDER_CHOICE

case "$PROVIDER_CHOICE" in
  1)
    PROVIDER="anthropic"
    ENV_KEY="ANTHROPIC_API_KEY"
    echo ""
    echo -e "${CYAN}Pick a model:${NC}"
    echo "  1) claude-sonnet-4-20250514 (recommended)"
    echo "  2) claude-opus-4-6 (smartest, expensive)"
    echo "  3) claude-haiku-3-20250623 (fast, cheap)"
    read -rp "Enter number: " MODEL_CHOICE
    case "$MODEL_CHOICE" in
      1) MODEL="anthropic/claude-sonnet-4-20250514" ;;
      2) MODEL="anthropic/claude-opus-4-6" ;;
      3) MODEL="anthropic/claude-haiku-3-20250623" ;;
      *) MODEL="anthropic/claude-sonnet-4-20250514" ;;
    esac
    ;;
  2)
    PROVIDER="openai"
    ENV_KEY="OPENAI_API_KEY"
    echo ""
    echo -e "${CYAN}Pick a model:${NC}"
    echo "  1) gpt-4o (recommended)"
    echo "  2) gpt-4o-mini (fast, cheap)"
    echo "  3) o1 (reasoning)"
    read -rp "Enter number: " MODEL_CHOICE
    case "$MODEL_CHOICE" in
      1) MODEL="openai/gpt-4o" ;;
      2) MODEL="openai/gpt-4o-mini" ;;
      3) MODEL="openai/o1" ;;
      *) MODEL="openai/gpt-4o" ;;
    esac
    ;;
  3)
    PROVIDER="openrouter"
    ENV_KEY="OPENROUTER_API_KEY"
    echo ""
    read -rp "Enter model name (e.g. anthropic/claude-3.5-sonnet): " CUSTOM_MODEL
    MODEL="openrouter/${CUSTOM_MODEL}"
    ;;
  4)
    PROVIDER="ollama"
    ENV_KEY=""
    echo ""
    echo -e "${CYAN}Pick a model:${NC}"
    echo "  1) llama3 (recommended)"
    echo "  2) mistral"
    echo "  3) gemma2"
    echo "  4) custom"
    read -rp "Enter number: " MODEL_CHOICE
    case "$MODEL_CHOICE" in
      1) MODEL="ollama/llama3" ;;
      2) MODEL="ollama/mistral" ;;
      3) MODEL="ollama/gemma2" ;;
      4) read -rp "Enter model name: " CUSTOM; MODEL="ollama/${CUSTOM}" ;;
      *) MODEL="ollama/llama3" ;;
    esac

    echo ""
    read -rp "Ollama URL [http://host.docker.internal:11434/v1]: " OLLAMA_URL
    OLLAMA_URL="${OLLAMA_URL:-http://host.docker.internal:11434/v1}"

    # Update OPENAI_BASE_URL for Ollama
    if grep -q "^OPENAI_BASE_URL=" "$ENV_FILE"; then
      sed -i "s|^OPENAI_BASE_URL=.*|OPENAI_BASE_URL=${OLLAMA_URL}|" "$ENV_FILE"
    else
      echo "OPENAI_BASE_URL=${OLLAMA_URL}" >> "$ENV_FILE"
    fi
    ;;
  5)
    PROVIDER="google"
    ENV_KEY="GEMINI_API_KEY"
    echo ""
    echo -e "${CYAN}Pick a model:${NC}"
    echo "  1) gemini-2.0-flash (recommended)"
    echo "  2) gemini-1.5-pro"
    read -rp "Enter number: " MODEL_CHOICE
    case "$MODEL_CHOICE" in
      1) MODEL="google/gemini-2.0-flash" ;;
      2) MODEL="google/gemini-1.5-pro" ;;
      *) MODEL="google/gemini-2.0-flash" ;;
    esac
    ;;
  6)
    PROVIDER="groq"
    ENV_KEY="GROQ_API_KEY"
    MODEL="groq/llama-3.3-70b-versatile"
    echo ""
    echo -e "Using model: ${GREEN}${MODEL}${NC}"
    ;;
  7)
    PROVIDER="mistral"
    ENV_KEY="MISTRAL_API_KEY"
    echo ""
    echo -e "${CYAN}Pick a model:${NC}"
    echo "  1) mistral-large-latest (recommended)"
    echo "  2) mistral-small-latest (fast)"
    read -rp "Enter number: " MODEL_CHOICE
    case "$MODEL_CHOICE" in
      1) MODEL="mistral/mistral-large-latest" ;;
      2) MODEL="mistral/mistral-small-latest" ;;
      *) MODEL="mistral/mistral-large-latest" ;;
    esac
    ;;
  *)
    echo -e "${RED}Invalid choice.${NC}"
    exit 1
    ;;
esac

# Step 2: Get API key (skip for Ollama)
if [[ -n "${ENV_KEY:-}" ]]; then
  echo ""
  read -rsp "${PROVIDER} API key (leave empty to keep current): " NEW_KEY
  echo ""

  if [[ -n "$NEW_KEY" ]]; then
    if grep -q "^${ENV_KEY}=" "$ENV_FILE" || grep -q "^#${ENV_KEY}=" "$ENV_FILE"; then
      # Uncomment if commented, then update
      sed -i "s|^#*${ENV_KEY}=.*|${ENV_KEY}=${NEW_KEY}|" "$ENV_FILE"
    else
      echo "${ENV_KEY}=${NEW_KEY}" >> "$ENV_FILE"
    fi
    echo -e "${GREEN}✓${NC} API key updated in .env"
  else
    echo -e "${YELLOW}Keeping current API key${NC}"
  fi
fi

# Step 3: Update openclaw.json model
if [[ -f "$CONFIG_FILE" ]]; then
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
print('Model updated in openclaw.json')
"
    echo -e "${GREEN}✓${NC} Model set to ${MODEL}"
  else
    echo -e "${YELLOW}python3 not found — update openclaw.json manually:${NC}"
    echo "  Set agents.defaults.model to \"${MODEL}\""
  fi
else
  echo -e "${YELLOW}openclaw.json not found at ${CONFIG_FILE}${NC}"
  echo "  It will be created on first run. Set model via:"
  echo "  docker compose exec openclaw-gateway node dist/index.js config set agents.defaults.model \"${MODEL}\""
fi

# Step 4: Restart
echo ""
read -rp "Restart the gateway now? (Y/n): " DO_RESTART
if [[ "$DO_RESTART" != "n" && "$DO_RESTART" != "N" ]]; then
  cd "$PROJECT_DIR"
  docker compose restart openclaw-gateway
  echo ""
  echo -e "${GREEN}✓${NC} Gateway restarted with ${PROVIDER} / ${MODEL}"
else
  echo ""
  echo -e "${YELLOW}Remember to restart:${NC} docker compose restart openclaw-gateway"
fi

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${GREEN}  Provider switched to: ${PROVIDER}${NC}"
echo -e "${GREEN}  Model: ${MODEL}${NC}"
echo -e "${CYAN}============================================================${NC}"
