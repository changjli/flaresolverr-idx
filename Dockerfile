# FlareSolverr + Caddy — Cloudflare challenge solver with bearer-token auth.
#
# Caddy owns the public PORT (SnapDeploy-injected) and reverse-proxies /v1 to
# FlareSolverr on a fixed internal port (8192). FlareSolverr has no built-in
# auth, so Caddy rejects any /v1 request without `Authorization: Bearer
# $FLARESOLVERR_TOKEN`; the health endpoint GET / is exempt (it reveals nothing
# and is what the Go client pings to wake the container).
FROM ghcr.io/flaresolverr/flaresolverr:latest

# The base image runs as non-root `flaresolverr`; switch to root only to
# install Caddy, then drop back for runtime.
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in \
         amd64) CADDY_ARCH=amd64 ;; \
         arm64) CADDY_ARCH=arm64 ;; \
         *) echo "unsupported arch: $ARCH"; exit 1 ;; \
       esac \
    && curl -fsSL -o /usr/bin/caddy "https://caddyserver.com/api/download?os=linux&arch=${CADDY_ARCH}" \
    && chmod +x /usr/bin/caddy \
    && apt-get purge -y curl \
    && rm -rf /var/lib/apt/lists/*

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER flaresolverr

# Public port. SnapDeploy injects PORT at runtime; Caddy binds it. High port
# because the runtime user is non-root (cannot bind 80). If unset, 8080.
ENV PORT=8080
EXPOSE 8080 8192

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]
