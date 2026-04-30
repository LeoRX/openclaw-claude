# openclaw-claude

[![Docker Pulls](https://img.shields.io/docker/pulls/leorx/openclaw-claude)](https://hub.docker.com/r/leorx/openclaw-claude)
[![Docker Image Size](https://img.shields.io/docker/image-size/leorx/openclaw-claude/latest)](https://hub.docker.com/r/leorx/openclaw-claude)
[![Build Status](https://github.com/LeoRX/openclaw-claude/actions/workflows/build.yml/badge.svg)](https://github.com/LeoRX/openclaw-claude/actions/workflows/build.yml)
[![Platforms](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-blue)](https://hub.docker.com/r/leorx/openclaw-claude)

A ready-to-run Docker image combining **[OpenClaw](https://github.com/openclaw/openclaw)** (personal AI assistant platform) with the **[Claude CLI](https://github.com/anthropics/claude-code)** (`@anthropic-ai/claude-code`), available for both `linux/amd64` and `linux/arm64`.

The image auto-rebuilds every 6 hours whenever a new OpenClaw release or Claude CLI version is detected.

---

## Quick Start

```bash
# 1. Copy the example env file
cp .env.example .env

# 2. Start the container
docker compose up -d

# 3. Authenticate Claude (first time only)
docker exec -it openclaw-claude bash
claude login
```

OpenClaw will be available at `http://localhost:18789`.

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

Configure OpenClaw via a `.env` file (see [`.env.example`](.env.example)):

| Variable | Description |
|----------|-------------|
| `TZ` | Timezone (e.g. `America/New_York`) |
| `OPENCLAW_GATEWAY_TOKEN` | Secret token to secure the gateway |
| `OPENCLAW_DISABLE_BONJOUR` | Set `true` to disable mDNS discovery |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OpenTelemetry collector endpoint |
| `OTEL_SERVICE_NAME` | Service name for telemetry |
| `CLAUDE_AI_SESSION_KEY` | Claude session key (alternative to `claude login`) |
| `CLAUDE_WEB_SESSION_KEY` | Claude web session key (alternative to `claude login`) |

---

## Volumes

| Volume | Container Path | Purpose |
|--------|---------------|---------|
| `openclaw-data` | `/home/node/.openclaw` | OpenClaw config, state, and plugins |
| `openclaw-plugins` | `/var/lib/openclaw/plugin-runtime-deps` | Plugin runtime dependencies |
| `claude-config` | `/home/node/.claude` | Claude CLI credentials and config |

---

## Ports

| Port | Description |
|------|-------------|
| `18789` | OpenClaw gateway (main UI/API) |
| `18790` | OpenClaw bridge |

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

## License

MIT
