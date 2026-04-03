# Detailed Setup Guide

Step-by-step instructions for setting up your OpenClaw stack from scratch.

## Step 1: Prepare Your Server

Any Linux server with Docker works. Minimum specs:

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 vCPU | 4+ cores |
| RAM | 4 GB | 8+ GB |
| Disk | 20 GB | 50+ GB |
| OS | Any Linux with Docker | Ubuntu 22.04+ / Debian 12+ |

### Install Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in for group change to take effect
```

Verify:
```bash
docker --version
docker compose version
```

## Step 2: Set Up Tailscale

### Create a Tailscale account
1. Go to [tailscale.com](https://tailscale.com/) and sign up
2. Install Tailscale on your laptop/phone for remote access

### Generate an auth key
1. Go to [Tailscale Admin → Settings → Keys](https://login.tailscale.com/admin/settings/keys)
2. Click "Generate auth key"
3. Options:
   - **Reusable**: Yes (so container can reconnect after restart)
   - **Expiration**: Set to your preference (or no expiry)
   - **Tags**: Optional, for ACL management
4. Copy the key — you'll need it for `.env`

## Step 3: Create a Telegram Bot

1. Open Telegram and search for **@BotFather**
2. Send `/newbot`
3. Choose a **display name** (e.g., "My AI Assistant")
4. Choose a **username** (must end in `bot`, e.g., `mycompany_ai_bot`)
5. BotFather gives you a token like: `<your-bot-token>`
6. Copy this token for `.env`

### Optional bot settings (via BotFather)
```
/setdescription - Set what people see before starting a chat
/setabouttext - Set the bot's bio
/setuserpic - Upload an avatar
/setcommands - Set command menu (can leave empty)
```

## Step 4: Get an Anthropic API Key

1. Go to [console.anthropic.com](https://console.anthropic.com/)
2. Sign up or log in
3. Go to **Settings → API Keys**
4. Click "Create Key"
5. Copy the key (starts with `sk-ant-`)
6. Add billing/credits to your account

### API pricing (as of 2026)
Your conversations use API tokens. Costs depend on the model:
- **Claude Sonnet**: ~$3/$15 per 1M tokens (input/output)
- **Claude Opus**: ~$15/$75 per 1M tokens (input/output)

A typical day of moderate use costs $1-5.

## Step 5: Clone and Configure

```bash
git clone https://github.com/YOUR_USERNAME/openclaw-stack.git
cd openclaw-stack

# Create your .env from the template
cp .env.example .env
```

Edit `.env` with your actual values:
```bash
nano .env
```

```env
TS_AUTHKEY=tskey-auth-kYoUrAcTuAlKeY-xxxxxxxxxxxxxxxxxxxxxxx
OPENCLAW_TOKEN=a-strong-random-string-use-openssl-rand-hex-32
ANTHROPIC_API_KEY=sk-ant-your-actual-key-here
TELEGRAM_BOT_TOKEN=<your-bot-token>
```

Generate a strong gateway token:
```bash
echo "OPENCLAW_TOKEN=$(openssl rand -hex 32)"
```

## Step 6: Launch

```bash
docker compose up -d
```

Watch the startup:
```bash
docker compose logs -f
```

You should see:
1. Tailscale connecting to your tailnet
2. Browser engine starting
3. OpenClaw gateway starting and connecting to Telegram

## Step 7: First Conversation

1. Open Telegram
2. Search for your bot's username
3. Click "Start"
4. Say hello!

The bot will go through its first-run setup (Bootstrap). It will:
- Ask for your name
- Pick a name for itself
- Establish its personality
- Set up workspace files

## Step 8: Remote Access (Optional)

### Access the Control UI

From any device on your Tailscale network:
```
http://<tailscale-hostname>:18789
```

Use your `OPENCLAW_TOKEN` to authenticate.

### SSH into the server

If Tailscale is on your laptop:
```bash
ssh user@<tailscale-hostname>
```

## Step 9: Set Up Backups

```bash
# Run backup manually
./scripts/backup.sh

# Or add to cron (daily at 3 AM)
crontab -e
# Add this line:
0 3 * * * /path/to/openclaw-stack/scripts/backup.sh >> /var/log/openclaw-backup.log 2>&1
```

## Next Steps

- Customize `data/workspace/SOUL.md` to adjust the bot's personality
- Add skills to `data/workspace/skills/` for new capabilities
- Set up HEARTBEAT.md for proactive background checks
- Join the [OpenClaw community](https://discord.com/invite/clawd) for help and ideas
