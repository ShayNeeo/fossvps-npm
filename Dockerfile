# Production Dockerfile
# This file simply pulls the pre-built image from GHCR.
# Use this for 'Production' deployments in Dokploy.

FROM ghcr.io/shayneeo/fossvps-npm:latest

EXPOSE 80 81 443
VOLUME [ "/data", "/etc/letsencrypt" ]
