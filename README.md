# openclaw-claude

[![Docker Pulls](https://img.shields.io/docker/pulls/leorx/openclaw-claude)](https://hub.docker.com/r/leorx/openclaw-claude)
[![Docker Image Size](https://img.shields.io/docker/image-size/leorx/openclaw-claude/latest)](https://hub.docker.com/r/leorx/openclaw-claude)
[![Build Status](https://github.com/LeoRX/openclaw-claude/actions/workflows/build.yml/badge.svg)](https://github.com/LeoRX/openclaw-claude/actions/workflows/build.yml)
[![Platforms](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-blue)](https://hub.docker.com/r/leorx/openclaw-claude)

A ready-to-run Docker image combining **[OpenClaw](https://github.com/openclaw/openclaw)** (personal AI assistant platform) with the **[Claude CLI](https://github.com/anthropics/claude-code)** (`@anthropic-ai/claude-code`), available for both `linux/amd64` and `linux/arm64`.

The image auto-rebuilds every 6 hours whenever a new OpenClaw release or Claude CLI version is detected.

> **Official OpenClaw Docker docs:** https://docs.openclaw.ai/install/docker

---

## Quick Start

### 1. Copy the example files

```bash
cp docker-compose.example.yml docker-compose.yml
cp .env.example .env
```

Both `docker-compose.yml` and `.env` are gitignored — customise them freely without worrying about accidentally committing secrets.

[`docker-compose.example.yml`](docker-compose.example.yml) is a fully annotated Compose file with every supported environment variable included and commented.

### 2. Set your gateway token

Open `.env` and set at minimum:

```env
# A strong random secret — protects your gateway API
OPENCLAW_GATEWAY_TOKEN=change-me-to-a-random-secret

# Your timezone
TZ=America/New_York
```

Generate a strong token with:

```bash
openssl rand -hex 32
```

### 3. Start the container

```bash
docker compose up -d
```

### 4. Authenticate Claude (first time only)

```bash
docker exec -it openclaw-claude bash
claude login
exit
```

This opens a browser OAuth flow. Your credentials are stored in the `claude-config` volume and persist across container restarts.

### 5. Open the dashboard

OpenClaw will be available at **http://localhost:18789**

Retrieve the exact dashboard URL at any time:

```bash
docker compose exec openclaw-claude node openclaw.mjs dashboard --no-open
```

---

## Authenticating Claude CLI

Claude CLI stores its credentials in `/home/node/.claude` inside the container. This path is mounted as a named Docker volume (`claude-config`) so your session **persists across restarts**.

```bash
# Shell into the running container
docker exec -it openclaw-claude bash

# Log in (opens browser OAuth flow)
claude login

# Verify
claude --version
```

You only need to do this once. The volume keeps you logged in.

---

## Image Tags

| Tag | Description |
|-----|-------------|
| `latest` | Most recent build |
| `YYYY.MM.DD` | Date-stamped build (e.g. `2026.04.30`) |
| `claude-X.Y.Z` | Build pinned to a specific claude-code version |

```bash
docker pull leorx/openclaw-claude:latest
docker pull leorx/openclaw-claude:2026.04.30
```

---

## Environment Variables

Configure via a `.env` file (see [`.env.example`](.env.example)). All variables are passed directly to the OpenClaw process.

### Core

| Variable | Description |
|----------|-------------|
| `TZ` | Timezone (e.g. `America/New_York`) |
| `OPENCLAW_GATEWAY_TOKEN` | **Required.** Secret token to authenticate gateway API access. Generate with `openssl rand -hex 32`. |

### Claude Authentication (alternative to `claude login`)

| Variable | Description |
|----------|-------------|
| `CLAUDE_AI_SESSION_KEY` | Claude session key (headless alternative to running `claude login`) |
| `CLAUDE_WEB_SESSION_KEY` | Claude web session key |

### OpenClaw Networking

| Variable | Description |
|----------|-------------|
| `OPENCLAW_DISABLE_BONJOUR` | Set to `true` to disable mDNS/Bonjour advertising on the local network |
| `OPENCLAW_SANDBOX` | Enable sandbox mode for agent execution. Set to `1`, `true`, `yes`, or `on` |
| `OPENCLAW_DOCKER_SOCKET` | Override Docker socket path (useful for rootless Docker setups) |
| `OPENCLAW_EXTRA_MOUNTS` | Comma-separated extra host bind mounts to expose inside the container |
| `OPENCLAW_HOME_VOLUME` | Persist `/home/node` in a Docker named volume |
| `OPENCLAW_PLUGIN_STAGE_DIR` | Container path for generated plugin dependencies |
| `OPENCLAW_SKIP_ONBOARDING` | Set to `true` to skip the interactive onboarding step on first start |
| `OPENCLAW_DISABLE_BUNDLED_SOURCE_OVERLAYS` | Disable bundled plugin source bind-mount overlays |

### OpenTelemetry (optional)

| Variable | Description |
|----------|-------------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP/HTTP collector endpoint (e.g. `http://otel-collector:4318`) |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | OTLP protocol — only `http/protobuf` is supported |
| `OTEL_SERVICE_NAME` | Service name label for telemetry data |
| `OTEL_SEMCONV_STABILITY_OPT_IN` | Opt into latest experimental GenAI semantic attributes |
| `OPENCLAW_OTEL_PRELOADED` | Set to `true` to skip starting a second OpenTelemetry SDK |

---

## Volumes

| Volume | Container Path | Purpose |
|--------|---------------|---------|
| `openclaw-data` | `/home/node/.openclaw` | OpenClaw config, state, workspace, and auth profiles |
| `openclaw-plugins` | `/var/lib/openclaw/plugin-runtime-deps` | Plugin runtime dependencies (high-churn) |
| `claude-config` | `/home/node/.claude` | Claude CLI credentials and config |

### What lives in `openclaw-data` (`/home/node/.openclaw`)

```
/home/node/.openclaw/
├── openclaw.json          # Main behavior configuration
├── .env                   # Runtime secrets (OPENCLAW_GATEWAY_TOKEN, etc.)
├── workspace/             # Agent workspaces
└── agents/
    └── <agentId>/
        └── agent/
            └── auth-profiles.json   # OAuth tokens & API keys per agent
```

---

## Ports

| Port | Description |
|------|-------------|
| `18789` | OpenClaw gateway — web dashboard and API |
| `18790` | OpenClaw bridge |

### Health checks

```bash
# Liveness probe
curl -fsS http://127.0.0.1:18789/healthz

# Readiness probe
curl -fsS http://127.0.0.1:18789/readyz

# Deep health snapshot (requires gateway token)
docker compose exec openclaw-claude node openclaw.mjs health --token "$OPENCLAW_GATEWAY_TOKEN"
```

### Prometheus metrics

Metrics are exposed (authenticated) at:

```
http://127.0.0.1:18789/api/diagnostics/prometheus
```

---

## Connecting to Local AI Models

To reach services running on your **host machine** (e.g. LM Studio, Ollama) from inside the container, use the special Docker hostname:

```
host.docker.internal
```

Example endpoints:

| Service | URL |
|---------|-----|
| LM Studio | `http://host.docker.internal:1234` |
| Ollama | `http://host.docker.internal:11434` |

> **Note:** The local service must listen on `0.0.0.0` (not `127.0.0.1`) to be reachable from Docker.

---

## Messaging Channels

OpenClaw supports connecting messaging platforms to your AI agents. Shell into the container to configure:

```bash
docker exec -it openclaw-claude bash

# WhatsApp
node openclaw.mjs channels login

# Telegram
node openclaw.mjs channels add --channel telegram --token "<your-telegram-bot-token>"

# Discord
node openclaw.mjs channels add --channel discord --token "<your-discord-bot-token>"
```

---

## Device Management

Approve connected devices (e.g. mobile apps) from the CLI:

```bash
# List pending device requests
docker compose exec openclaw-claude node openclaw.mjs devices list

# Approve a device
docker compose exec openclaw-claude node openclaw.mjs devices approve <requestId>
```

---

## Automatic Updates

This image is rebuilt automatically every 6 hours by a GitHub Actions workflow that:

1. Checks the current `ghcr.io/openclaw/openclaw:latest` manifest digest
2. Checks the latest `@anthropic-ai/claude-code` version on npm
3. Compares against [`versions.json`](versions.json) (the last-built state)
4. If either changed → commits updated `versions.json` → triggers a new multi-arch build → pushes to Docker Hub

To pull the latest image:

```bash
docker compose pull && docker compose up -d
```

---

## Building Locally

```bash
# Clone the repo
git clone https://github.com/LeoRX/openclaw-claude.git
cd openclaw-claude

# Set up your local config files
cp docker-compose.example.yml docker-compose.yml
cp .env.example .env
# Edit .env and set OPENCLAW_GATEWAY_TOKEN

# Build for your local platform
docker build -t openclaw-claude:local .

# Build multi-arch (requires Docker Buildx)
docker buildx create --use
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg CLAUDE_VERSION=1.2.3 \
  -t leorx/openclaw-claude:local \
  --load .
```

---

## Secrets Setup (for fork/contributors)

To publish images from your own fork, add these secrets to your GitHub repository:

| Secret | Value |
|--------|-------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (not your password) |

Generate a Docker Hub access token at: **Docker Hub → Account Settings → Personal Access Tokens**

---

## Further Reading

- [OpenClaw Docker install guide](https://docs.openclaw.ai/install/docker)
- [OpenClaw gateway security hardening](https://docs.openclaw.ai/gateway/security)
- [Claude CLI documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Docker Hub — leorx/openclaw-claude](https://hub.docker.com/r/leorx/openclaw-claude)

---

## License

MIT
