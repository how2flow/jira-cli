# Jira Automation Workspace

AI-powered Jira ticket management automation. Works with Claude Code, OpenAI Codex CLI, and Google Gemini CLI.

## Quick Start

```bash
# 1. Set environment variables
export JIRA_CLOUD_URL="https://your-site.atlassian.net"
export JIRA_CLOUD_ID="your-site.atlassian.net"

# 2. Run setup (interactive)
./envsetup.sh

# 3. Use slash command in CLI session
/<skill-name>

# 4. Or run manually
./skills/<skill-name>/schedule/run.sh
```

## Directory Structure

```
.
├── envsetup.sh                         # One-stop setup (MCP, skills, cron)
├── scripts/
│   ├── params.sh                       # CLI detection, variables
│   └── functions.sh                    # All shared functions
├── skills/
│   └── <skill-name>/
│       ├── install.sh                  # Slash command installer
│       ├── <skill-name>.md             # Skill definition (interactive use)
│       ├── requirements.md             # Requirements documentation
│       ├── rules/                      # Per-rule prompts (multi-pass execution)
│       │   └── rule<N>-<name>.md
│       └── schedule/                   # Cron automation (optional)
│           ├── install.sh
│           ├── run.sh
│           └── logs/
├── projects/                           # Multi-skill composite workflows
│   └── <project-name>/
│       └── schedule/
└── okr/                                # OKR tracking
```

## Supported CLIs

| CLI | Global Config | Project Config | MCP Format |
|-----|--------------|----------------|------------|
| Claude Code | `~/.claude/settings.json` | `.claude/settings.local.json` | JSON (`mcpServers`) |
| Codex CLI | `~/.codex/config.toml` | `.codex/config.toml` | TOML (`mcp_servers`) |
| Gemini CLI | `~/.gemini/settings.json` | `.gemini/settings.json` | JSON (`mcpServers`) |

## Environment Variables

Set via `.env` file or export in your shell profile (`~/.bashrc`, `~/.zshrc`).

| Variable | Description | Example |
|----------|-------------|---------|
| `JIRA_CLOUD_URL` | Jira Cloud URL | `https://your-site.atlassian.net` |
| `JIRA_CLOUD_ID` | Jira Cloud ID (used as cloudId in API) | `your-site.atlassian.net` |
| `JIRA_CLI_OVERRIDE` | Force specific CLI (optional) | `claude`, `codex`, `gemini` |
| `JIRA_DEBUG` | Enable debug output (optional) | `1` |

## Installation

```bash
# Full setup (interactive)
./envsetup.sh

# Individual skill
./skills/<skill-name>/install.sh
./skills/<skill-name>/schedule/install.sh
./skills/<skill-name>/schedule/install.sh "0 7 * * 1-5"  # Custom cron

# Remove
./envsetup.sh --remove
./skills/<skill-name>/install.sh --remove
./skills/<skill-name>/schedule/install.sh --remove
```
