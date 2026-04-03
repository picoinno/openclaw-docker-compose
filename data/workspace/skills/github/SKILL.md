# GitHub Skill

## Description
Git and GitHub operations: repository management, branching, PRs, code review, issue tracking, and CI/CD integration.

## When to Use
- Creating, cloning, or managing GitHub repositories
- Branching strategies, merging, resolving conflicts
- Creating and reviewing pull requests
- Issue tracking and project boards
- Checking CI/CD status and logs
- Repository hygiene (stale branches, unused repos)

## Capabilities
- Git CLI: commit, push, pull, branch, merge, rebase, cherry-pick
- GitHub API: repos, PRs, issues, releases, actions
- Code review: diff analysis, comment on changes
- Branch management: create, protect, clean up stale branches
- Release management: tags, changelogs, semantic versioning

## Available Accounts & Repos

Read `GITHUB.md` in the workspace for the current account list and access status.
If `GITHUB.md` doesn't exist, ask the user to copy `GITHUB.md.example` and fill it in.

Tokens are auto-applied via `~/.gitconfig` URL rewrites — no manual auth needed once configured.

## Red Lines
- **NEVER delete any repository. Ever.** (Strongest order)
- Never force-push to main/master without explicit approval
- Never expose tokens, keys, or secrets in commits
- Always use `.gitignore` — no secrets, no binaries

## Rules
- Commit messages: clear, descriptive, conventional format preferred
- PRs: always describe what and why, not just what
- Branch naming: `feature/`, `fix/`, `hotfix/`, `chore/`
- Check existing branches before creating new ones
- Keep repos clean: archive completed branches
- Fine-grained tokens: one owner only (user OR org, not both)

## Common Commands
```bash
# Status & info
git status
git log --oneline -10
git remote -v

# Branching
git checkout -b feature/my-feature
git push -u origin feature/my-feature

# GitHub API (via curl)
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/picoinno/<repo>/pulls
```
