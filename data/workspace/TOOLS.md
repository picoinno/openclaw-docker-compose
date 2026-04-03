# TOOLS.md - Local Notes

## GitHub

PAT tokens are passed via environment variables (set in `.env`, never committed).
Wired into `~/.git-credentials` by running:

```bash
docker compose run --rm openclaw-cli bash /home/node/.openclaw/workspace/scripts/setup-github.sh
```

Configured tokens (update after running setup-github.sh):
- picoinno → personal account
- pico-inno → org

Other orgs (mijn-ui, sannkoko) → set `GITHUB_TOKEN_MIJN_UI` / `GITHUB_TOKEN_SANNKOKO` in `.env` and re-run script.

---

_Add more entries as you configure your setup. Keep it minimal._
