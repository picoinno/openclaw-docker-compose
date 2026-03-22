# OpenClaw Stack

A self-hosted AI assistant running on Docker with Tailscale networking, connected via Telegram.

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
│         ├──→ Anthropic API (outbound)               │
│         └──→ Browser on localhost:3000              │
└─────────────────────────────────────────────────────┘
```

All services share the Tailscale network stack, so they see each other on `localhost`.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) + Docker Compose v2
- A [Tailscale](https://tailscale.com/) account + auth key (see below)
- An [Anthropic API key](https://console.anthropic.com/settings/keys) (or OpenAI)
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

### 4. Verify

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
├── docker-compose.yml       # Container orchestration
├── .env                     # Your secrets (gitignored)
├── .env.example             # Template for .env
├── data/                    # Runtime data (gitignored)
│   ├── .openclaw/           # Gateway config, sessions, credentials
│   └── workspace/           # AI workspace (SOUL.md, memory, skills)
├── tailscale/               # Tailscale state (gitignored)
├── docs/
│   └── setup-guide.md       # Detailed setup instructions
└── scripts/
    ├── setup.sh             # First-time setup wizard
    ├── switch-provider.sh   # Change AI provider interactively
    └── backup.sh            # Backup data directory
```

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
| `TS_AUTHKEY` | Yes | Tailscale auth key for VPN connectivity |
| `TS_HOSTNAME` | No | Tailscale machine name (default: `openclaw-agent`). Used as the URL to access Control UI: `http://<hostname>:18789` |
| `OPENCLAW_TOKEN` | Yes | Gateway auth token (for Control UI) |
| `ANTHROPIC_API_KEY` | Yes* | Anthropic API key (*or any other AI provider key) |
| `TELEGRAM_BOT_TOKEN` | Yes | Telegram bot token from @BotFather |

## Security Notes

- **No inbound ports needed** — all connections are outbound (Telegram API, AI API)
- **Tailscale** handles encrypted remote access to the gateway
- **Docker socket** is mounted for agent sandboxing — be aware of the trust implications
- **`.env` is gitignored** — never commit secrets
- **`data/` is gitignored** — contains sessions, credentials, and workspace files

## Data & Privacy

- AI conversations go to your AI provider (Anthropic/OpenAI) via **API** — [not used for training](https://docs.anthropic.com/en/docs/resources/data-usage)
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
