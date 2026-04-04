# OpenClaw Stack

A production-ready, self-hosted AI assistant running on Docker with Tailscale networking and Telegram. Designed for cost efficiency, resilience, and real-world use.

## Why This Stack?

- **💸 Cost-efficient** — OpenRouter as default provider, access 100+ models via one API key at the best price-to-performance ratio
- **🔄 Resilient** — 5-level fallback chain: OpenRouter → Anthropic → OpenAI → MiniMax → Ollama (local). If one provider goes down, the next picks up automatically
- **🧠 Organized** — Specialized sub-agents for coding, research, security, CRM, and more — not one overloaded AI trying to do everything
- **⚡ Optimized** — 56% reduction in per-prompt token overhead through context pruning, memory flush, and image downscaling
- **🔒 Hardened** — Resource limits, healthchecks, log rotation, socket proxy, auth tokens, no secrets in the repo
- **🚀 One command** — `docker compose up -d` and you're running

## What's Inside

| Service | Image | Purpose |
|---------|-------|---------|
| **tailscale** | `tailscale/tailscale` | VPN network layer — secure remote access |
| **openclaw-gateway** | `ghcr.io/openclaw/openclaw` | AI assistant engine — handles chat, tools, memory |
| **openclaw-browser** | `browserless/chrome` | Headless browser — web browsing capability for the AI |
| **openclaw-cli** | `ghcr.io/openclaw/openclaw` | Management CLI (on-demand, not always running) |

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Tailscale Network (shared by all services)         │
│                                                     │
│  ┌──────────────┐  ┌───────────┐  ┌──────────────┐ │
│  │   Gateway     │  │  Browser  │  │   CLI        │ │
│  │  (OpenClaw)   │  │ (Chrome)  │  │  (tools)     │ │
│  │   :18789      │  │  :3000    │  │  on-demand   │ │
│  └──────┬────────┘  └───────────┘  └──────────────┘ │
│         │                                           │
│         ├──→ Telegram API (outbound)                │
│         ├──→ AI Providers (OpenRouter/Anthropic/    │
│         │    OpenAI/Ollama — auto-failover)         │
│         └──→ Browser on localhost:3000              │
└─────────────────────────────────────────────────────┘
```

All services share the Tailscale network stack, so they see each other on `localhost`.

## Model Chain

This stack uses a 5-level fallback chain — if the primary model is unavailable, the next one picks up automatically:

| # | Model | Provider | Cost (in/out per 1M tokens) |
|---|-------|----------|----------------------------|
| 🟢 Primary | Qwen 3.5 72B | OpenRouter | ~$0.30 / $0.90 |
| 1️⃣ Fallback | Claude Sonnet 4 | Anthropic (direct) | $3.00 / $15.00 |
| 2️⃣ Fallback | GPT-4o | OpenAI (direct) | $2.50 / $10.00 |
| 3️⃣ Fallback | MiniMax M2.7 | OpenRouter | $0.30 / $1.20 |
| 4️⃣ Fallback | Qwen 2.5 | Ollama (local) | Free |

> **Only `OPENROUTER_API_KEY` is required to get started.** Anthropic/OpenAI keys are optional for their respective fallbacks. Ollama needs no key — just a running instance on your network.

You can swap any model by editing `AI_MODEL` in `.env` and the fallback list in `openclaw.json.template`.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) + Docker Compose v2
- A [Tailscale](https://tailscale.com/) account + auth key (see below)
- An [OpenRouter API key](https://openrouter.ai/keys) (or any other AI provider)
- A [Telegram bot token](https://core.telegram.org/bots#botfather) from @BotFather

### Tailscale Account

This stack uses [Tailscale](https://tailscale.com/) as a VPN layer for secure remote access. You need a Tailscale account (free for personal use).

1. Sign up at [tailscale.com](https://tailscale.com/)
2. Install Tailscale on your laptop/phone so you can access the server remotely
3. Generate an auth key at [Admin → Settings → Keys](https://login.tailscale.com/admin/settings/keys) (use **Reusable** so the container reconnects after restart)

The `TS_HOSTNAME` in your `.env` sets the machine name in your Tailscale dashboard. This is also the URL you use to access the OpenClaw Control UI from your browser:

```
http://<TS_HOSTNAME>:18789
```

For example, if `TS_HOSTNAME=my-ai-bot`, you access the Control UI at `http://my-ai-bot:18789` from any device on your Tailscale network.

> **Note:** If you run multiple OpenClaw instances, give each one a unique `TS_HOSTNAME` so they don't conflict in your Tailscale dashboard.

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/picoinno/openclaw-docker-compose.git
cd openclaw-docker-compose
```

### 2. Configure environment

```bash
cp .env.example .env
nano .env    # Fill in your actual values
```

### 3. Start everything

```bash
docker compose up -d
```

### 4. Apply config (required)

Run this before starting — it writes `openclaw.json` with your chosen model so the gateway doesn't boot with a wrong default:

```bash
./scripts/init-config.sh
```

This reads `AI_MODEL` from your `.env` automatically. You can also pass a model directly:

```bash
./scripts/init-config.sh openrouter/google/gemini-2.5-flash
```

Popular choices:
- `openrouter/qwen/qwen-3.5-72b-instruct` — default, great price/performance
- `openrouter/google/gemini-2.5-flash` — fast and cheap
- `openrouter/minimax/minimax-m2.7` — strong agent model
- `openai/gpt-4o` — OpenAI direct
- `ollama/qwen2.5` — local, free

> **Why?** OpenClaw stores the model in `openclaw.json`, not `.env`. This script bridges the gap so you only edit `.env`.

### 5. Verify

```bash
# Check all containers are running
docker compose ps

# Check gateway health
docker compose logs openclaw-gateway --tail 20

# Check Tailscale connection
docker compose exec tailscale tailscale status
```

### 5. Pair your Telegram account

When you message the bot for the first time (send `/start` or any message), the bot will reply with a **pairing code** like this:

```
🔐 Pairing required

Hi! I don't recognize you yet.
Please share this code with the device owner to get access:

  ABCD-1234

This code expires in 1 hour.
```

The code (e.g. `ABCD-1234`) is what you need for the next step.

**Approve the pairing** — run this on your server:

```bash
docker compose run --rm openclaw-cli pairing approve telegram ABCD-1234
```

Replace `ABCD-1234` with the actual code from the bot message.

Once approved, the user can chat with the bot immediately. Each new user who messages the bot will receive their own pairing code — approve them the same way.

**View all pending pairing requests:**

```bash
docker compose run --rm openclaw-cli devices list
```

This shows all devices/users waiting for approval, along with their request IDs and codes.

**Allow a user directly by Telegram ID (skip pairing):**

If you know a user's Telegram ID and want to pre-approve them without the pairing flow, edit `data/.openclaw/openclaw.json`:

```json
{
  "channels": {
    "telegram": {
      "allowFrom": ["123456789", "987654321"]
    }
  }
}
```

- `allowFrom` is a list of Telegram user IDs (as strings) that are allowed to chat with the bot without pairing
- You can find a user's Telegram ID by using bots like `@userinfobot`
- After editing, restart: `docker compose restart openclaw-gateway`

After pairing is approved, message your bot — it should respond!

## Directory Structure

```
openclaw-docker-compose/
├── docker-compose.yml            # Container orchestration
├── openclaw.json.template        # Optimized gateway config template
├── .env                          # Your secrets (gitignored)
├── .env.example                  # Template for .env
├── data/                         # Runtime data (gitignored)
│   ├── .openclaw/                # Gateway config, sessions, credentials
│   └── workspace/                # AI workspace (persona, memory, skills)
│       ├── SOUL.md               # Agent personality & behavior
│       ├── IDENTITY.md           # Agent name, avatar, vibe
│       ├── USER.md               # About the human — fill this in
│       ├── AGENTS.md             # Startup instructions & rules
│       ├── HEARTBEAT.md          # Background check schedule
│       ├── TOOLS.md              # Environment-specific notes
│       ├── MEMORY.md             # Long-term memory (curated)
│       ├── agents/               # Subagent persona files
│       │   ├── koda.md           # Coding subagent
│       │   ├── docu.md           # Documentation subagent
│       │   └── sentry.md         # Security subagent
│       └── memory/               # Daily notes + archive
│           └── archive/
├── tailscale/                    # Tailscale state (gitignored)
├── docs/
│   └── setup-guide.md            # Detailed setup instructions
└── scripts/
    ├── setup.sh                  # First-time setup wizard
    ├── init-config.sh            # Apply config template + set AI model
    ├── switch-provider.sh        # Change AI provider interactively
    └── backup.sh                 # Backup data directory
```

## Workspace

The `data/workspace/` directory is the agent's brain. It ships with starter files:

| File | Purpose | Edit? |
|------|---------|-------|
| `SOUL.md` | Personality, behavior, values | ✅ Customize |
| `IDENTITY.md` | Name, emoji, vibe | ✅ Customize |
| `USER.md` | About you — name, timezone, context | ✅ Fill in |
| `AGENTS.md` | Startup rules, red lines, workspace rules | Optional |
| `HEARTBEAT.md` | What to check on background ticks | Optional |
| `TOOLS.md` | Your local setup (SSH hosts, device names, etc.) | ✅ Add entries |
| `MEMORY.md` | Long-term memory — curated by the agent | Auto-managed |

**Projects rule:** never put git repos inside `workspace/`. The agent uses
`/home/node/projects/` for code. The workspace is for memory and config only.
Keeping repos out of the workspace prevents accidental context bloat.

### Subagents

The stack ships with a full team of specialized agents in `data/workspace/agents/`:

| Agent | Role |
|-------|------|
| 💻 **Koda** | Coding, debugging, code review |
| 📝 **Docu** | Documentation, writing, organizing |
| 🛡️ **Sentry** | Security audits, hardening |
| 🔮 **Nexus** | Deep research, reasoning, analysis |
| 🤝 **CRM** | Prospects, pipeline, client management |
| 💰 **Finance** | Accounting, billing, budgets |
| 👥 **HR** | Employee records, compliance |
| 📢 **Marketing** | Campaigns, content, social media |
| 📋 **PM** | Planning, tracking, milestones |

Each agent has its own persona file with specialized instructions. The main agent delegates tasks automatically. Add more by creating files in `agents/` and listing them in `AGENTS.md`.

## Token Optimization

This stack ships with an optimized `openclaw.json.template` that enables:

| Setting | Value | Effect |
|---------|-------|--------|
| `contextPruning` | cache-ttl 5m | Drops old tool results from context |
| `imageMaxDimensionPx` | 800 | Downscales images before sending to model |
| `compaction` | safeguard + memoryFlush | Auto-compacts long sessions, saves memory |
| `session.reset` | daily at 4am | Fresh session every morning |
| `session.maintenance` | 30d prune / 200mb cap | Keeps disk usage in check |
| `messages.queue` | collect, 2s debounce | Batches rapid messages |
| `heartbeat` | 55m, lightContext | Keeps context cache warm cheaply |

Run `./scripts/init-config.sh` after first boot to apply the template.

## GitHub Access (optional)

If you want the agent to push/pull GitHub repos, add your PAT tokens to `.env`:

```env
GITHUB_TOKEN_1=github_pat_xxxxxxxxx
GITHUB_TOKEN_2=github_pat_xxxxxxxxx
```

Then wire them into the container after first boot:

```bash
docker compose run --rm openclaw-cli bash /home/node/.openclaw/workspace/scripts/setup-github.sh
```

This writes tokens into `~/.git-credentials` inside the container — no credentials ever touch GitHub or your repo.

> **Tokens stay in `.env` (gitignored). Never commit them.**

## Management

### View logs

```bash
docker compose logs -f                         # All services
docker compose logs -f openclaw-gateway        # Gateway only
```

### Restart

```bash
docker compose restart                         # All services
docker compose restart openclaw-gateway        # Gateway only
```

### Stop / Start

```bash
docker compose down       # Stop all
docker compose up -d      # Start all
```

### Run CLI commands

```bash
docker compose run --rm openclaw-cli status
docker compose run --rm openclaw-cli devices list
```

### Update images

```bash
docker compose pull       # Pull latest images
docker compose up -d      # Recreate with new images
```

### Switch AI Provider

```bash
./scripts/switch-provider.sh
```

Interactively switch between Anthropic, OpenAI, OpenRouter, Ollama, Gemini, Groq, or Mistral. Updates `.env` and `openclaw.json` automatically.

Or switch manually:
1. Edit `.env` — update the API key
2. Edit `data/.openclaw/openclaw.json` — change `agents.defaults.model` (e.g. `openai/gpt-4o`)
3. `docker compose restart openclaw-gateway`

### Backup

```bash
./scripts/backup.sh                           # Default: ./backups/
./scripts/backup.sh /mnt/external/backups     # Custom location
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENROUTER_API_KEY` | Yes* | OpenRouter API key — access 100+ models (*or any other provider key) |
| `OPENCLAW_TOKEN` | Yes | Gateway auth token (for Control UI) |
| `TELEGRAM_BOT_TOKEN` | Yes | Telegram bot token from @BotFather |
| `TS_AUTHKEY` | Yes | Tailscale auth key for VPN connectivity |
| `TS_HOSTNAME` | No | Tailscale machine name (default: `openclaw-agent`). Used as the URL to access Control UI: `http://<hostname>:18789` |
| `ANTHROPIC_API_KEY` | No | Anthropic key — enables Claude fallback |
| `OPENAI_API_KEY` | No | OpenAI key — enables GPT fallback |
| `OLLAMA_BASE_URL` | No | Ollama endpoint — enables local model fallback (no key needed) |

## Security Notes

- **No inbound ports needed** — all connections are outbound (Telegram API, AI API)
- **Tailscale** handles encrypted remote access to the gateway
- **Docker socket** is mounted for agent sandboxing — be aware of the trust implications
- **`.env` is gitignored** — never commit secrets
- **`data/` is gitignored** — contains sessions, credentials, and workspace files

## Data & Privacy

- AI conversations go to your AI provider(s) via **API** — not used for training ([Anthropic](https://docs.anthropic.com/en/docs/resources/data-usage), [OpenAI](https://platform.openai.com/docs/models#how-we-use-your-data), [OpenRouter](https://openrouter.ai/privacy))
- With Ollama fallback, conversations can stay fully local on your hardware
- All config and session data stays on your machine
- OpenClaw is open source with no telemetry

## Troubleshooting

### Containers won't start
```bash
docker compose logs tailscale    # Check Tailscale auth
docker compose logs openclaw-gateway  # Check gateway errors
```

### Bot not responding on Telegram
1. Check the bot token: `curl https://api.telegram.org/bot<TOKEN>/getMe`
2. Check gateway logs for Telegram connection errors
3. Make sure the bot isn't being used by another instance

### Tailscale not connecting
1. Verify your auth key is valid and not expired
2. Check: `docker compose exec tailscale tailscale status`
3. Try a fresh auth key from the Tailscale admin panel

### Permission errors
```bash
# Data dirs need to be owned by uid 1000 (container user)
sudo chown -R 1000:1000 data/
```

## License

[MIT](LICENSE)
