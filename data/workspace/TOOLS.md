# TOOLS.md - Local Notes

## GitHub

PAT tokens are passed via env vars (`GITHUB_USERNAME_N` + `GITHUB_TOKEN_N` in `.env`).
Run once to wire them into the container:

```bash
docker compose run --rm openclaw-cli bash \
  /home/node/.openclaw/workspace/scripts/setup-github.sh
```

Account details live in `GITHUB.md` (gitignored — copy from `GITHUB.md.example`).

---

_Add more entries as you configure your setup. Keep it minimal._
