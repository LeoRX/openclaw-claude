# openclaw-claude
# Combines ghcr.io/openclaw/openclaw with Claude CLI (@anthropic-ai/claude-code)
# Multi-arch: linux/amd64, linux/arm64
#
# Usage:
#   docker compose up -d
#   docker exec -it openclaw-claude bash
#   claude login

FROM ghcr.io/openclaw/openclaw:latest

# Pass specific version at build time (e.g. --build-arg CLAUDE_VERSION=1.2.3)
# Defaults to latest if not specified
ARG CLAUDE_VERSION

USER root

# Install Claude CLI globally (pinned version when provided)
RUN npm install -g @anthropic-ai/claude-code${CLAUDE_VERSION:+@${CLAUDE_VERSION}}

# Declare persistent volume for Claude credentials/config
# Mount this to persist `claude login` sessions across container restarts
VOLUME ["/home/node/.claude"]

USER node
