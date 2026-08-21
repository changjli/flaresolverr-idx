# FlareSolverr — Cloudflare challenge solver proxy.
# Used to test whether idx.co.id's Cloudflare challenge can be solved from a
# datacenter IP (SnapDeploy/Heroku). If it returns 200 + __cf_bm, cloud egress
# works; if it loops/times out, datacenter is hard-blocked and ingestion must
# run from a residential IP.
FROM ghcr.io/flaresolverr/flaresolverr:latest

# FlareSolverr reads the PORT env var and binds it (default 8191).
# SnapDeploy injects PORT -> FlareSolverr binds it automatically.
ENV PORT=8191
EXPOSE 8191