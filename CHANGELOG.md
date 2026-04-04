# Changelog

All notable changes to this repository are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [2026-04-04] — OpenRouter-first model chain

### Why
Anthropic pricing is expensive for a self-hosted stack where cost efficiency matters. OpenRouter gives access to 100+ models via a single API key. By making OpenRouter the default and keeping Anthropic/OpenAI as named fallbacks (plus a local Ollama option), users get the best price-to-performance ratio with full resilience.

### Changed
- **Default primary model**: `openrouter/qwen/qwen-3.5-72b-instruct` (via OpenRouter) — replaces `anthropic/claude-sonnet-4-20250514`
- **Fallback chain** (in order):
  1. `openrouter/qwen/qwen-3.5-72b-instruct` — primary, fast + cost-efficient
  2. `anthropic/claude-sonnet-4-6` — official Anthropic fallback
  3. `openai/gpt-4o` — official OpenAI fallback
  4. `openrouter/minimax/minimax-m2.7` — strong agent model via OpenRouter
  5. `ollama/qwen2.5` — local fallback, zero API cost
- **`.env.example`**: OpenRouter key is now uncommented and marked recommended; Anthropic/OpenAI keys moved to commented fallback section
- **Ollama support**: added `OLLAMA_BASE_URL` config for local model fallback

---

## [2026-04-03] — Production hardening + agent expansion

### Why
After running the stack in production, we identified several gaps: no department-level agents, weak Docker security posture, no GitHub automation, and leaked personal account names in public files. This batch resolves all of it.

### Added
- **Department agents**: Finance 💰, HR 👥, Marketing 📢, PM 📋 — each with dedicated persona files and skills
- **Nexus agent** 🔮 — Opus-powered deep-thinking agent for research and reasoning tasks
- **Deep-dive skill** — routes complex analysis tasks to Nexus automatically
- **GitHub credential setup**: generic `GITHUB_USERNAME_N` / `GITHUB_TOKEN_N` env pattern + `setup-github.sh` script
- **`GITHUB.md.example`** — gitignored template for storing agent GitHub account knowledge
- **Workspace starter files**: `SOUL.md`, `IDENTITY.md`, `USER.md`, `AGENTS.md`, `HEARTBEAT.md`, `TOOLS.md`, `MEMORY.md` pre-populated with sane defaults

### Changed
- **Docker hardening** (Sentry security audit): socket proxy, browserless auth token, `SYS_MODULE` capability removed, resource limits tightened
- **Token optimization**: context pruning (5m TTL), memory flush, image downscaling, session reset at 4 AM
- **Log rotation** added to all containers
- **`.env.example`** rewritten with `[REQUIRED]` markers and clearer section grouping
- **`openclaw.json.template`** expanded with full fallback chain, heartbeat config, subagent limits

### Fixed
- Removed personal account name (`PICOINNO`) from README → generic placeholders
- Fixed fake/placeholder tokens in security-sensitive config examples
- Tailscale paths added to `.gitignore` to prevent credential leaks

---

## [2026-03-22] — Initial improvements + provider flexibility

### Why
The initial release was Anthropic-only and had minimal docs. Contributors needed multi-provider support and clearer onboarding.

### Added
- **`switch-provider` script** — swap AI provider (Anthropic → OpenAI → OpenRouter etc.) without editing compose files manually
- **`init-config` script** — auto-sets `AI_MODEL` in `openclaw.json` from `.env` on first boot
- **Extended `.env.example`** — full list of supported provider keys, optional services (Brave, ElevenLabs, Deepgram, Perplexity)
- **Tailscale setup guide** in README — step-by-step including reusable auth keys
- **Telegram pairing docs** — how to approve the bot and pair your account

### Fixed
- `ANTHROPIC_API_KEY` warning no longer appears when using non-Anthropic providers
- Dynamic Tailscale hostname — `TS_HOSTNAME` in `.env` now correctly propagates to the container

---

## [2026-03-22] — Initial release

### Why
A clean, self-hostable Docker Compose stack for OpenClaw was missing from the ecosystem. Existing setups were either too minimal or required manual configuration that wasn't documented.

### Added
- `docker-compose.yml` with OpenClaw Gateway, Tailscale VPN, and Browserless Chrome
- Basic `.env.example` with Anthropic + Telegram as defaults
- README with quickstart guide
- Initial project structure

---

## Upgrade Notes

### Switching to OpenRouter (upcoming)
If you were using Anthropic as your primary provider:
1. Get an [OpenRouter API key](https://openrouter.ai/keys)
2. In `.env`: set `OPENROUTER_API_KEY=sk-or-...` and update `AI_MODEL=openrouter/google/gemini-2.5-flash`
3. Remove or comment out `ANTHROPIC_API_KEY`
4. Restart: `docker compose up -d`

No other changes needed — the fallback chain in `openclaw.json.template` handles the rest automatically.
