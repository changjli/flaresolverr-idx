#!/bin/sh
set -e

# FlareSolverr binds a fixed internal port (8192), ignoring the injected PORT
# which belongs to Caddy. The Go client sends session_ttl_minutes per request,
# so the server-side session default is not set here.
PORT=8192 /usr/local/bin/python -u /app/flaresolverr.py &

# Caddy owns the public PORT and enforces bearer-token auth on /v1.
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

wait
