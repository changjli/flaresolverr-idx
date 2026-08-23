# FlareSolverr + Caddy — built from Docker-format bases (python:3.11-slim-bookworm)
# so the image pushes to Heroku's container registry, which rejects the OCI-format
# official ghcr.io FlareSolverr image ("error from registry: unsupported").
#
# Caddy owns the public PORT (Heroku/SnapDeploy-injected) and reverse-proxies /v1
# to FlareSolverr on a fixed internal port (8192). Caddy enforces a bearer token
# on /v1; GET / and GET /health are public (wake probe + platform health check).
FROM python:3.11-slim-bookworm

# Chromium + tools (same packages as the official FlareSolverr image).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        chromium chromium-common chromium-driver xvfb xauth dumb-init procps curl ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

# FlareSolverr from source (pinned tag), matching the official image layout.
RUN git clone --depth 1 --branch v3.5.0 https://github.com/FlareSolverr/FlareSolverr.git /tmp/fs \
    && pip install --no-cache-dir -r /tmp/fs/requirements.txt \
    && mkdir -p /app \
    && cp -r /tmp/fs/src/. /app/ \
    && cp /tmp/fs/package.json /app/ \
    && rm -rf /tmp/fs

# Caddy (arch-detected static binary).
RUN ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in \
         amd64) CADDY_ARCH=amd64 ;; \
         arm64) CADDY_ARCH=arm64 ;; \
         *) echo "unsupported arch: $ARCH"; exit 1 ;; \
       esac \
    && curl -fsSL -o /usr/bin/caddy "https://caddyserver.com/api/download?os=linux&arch=${CADDY_ARCH}" \
    && chmod +x /usr/bin/caddy

# Non-root runtime user (matches the official image).
RUN useradd -m -u 1000 flaresolverr \
    && mkdir -p /config \
    && chown -R flaresolverr /config /app

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER flaresolverr
ENV PORT=8080
EXPOSE 8080 8192
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]
