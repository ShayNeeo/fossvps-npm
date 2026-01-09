# Dockerfile - Main application image
#
# This Dockerfile builds the final Nginx Proxy Manager application image.
# It requires base images to be built first using Dockerfile.build.
#
# BUILD REQUIREMENTS:
# 1. Base images must exist in registry (built via Dockerfile.build)
# 2. Frontend must be pre-built (via ./scripts/ci/frontend-build)
# 3. Use docker buildx for multi-arch support
#
# BASE IMAGE DEPENDENCIES:
# - testca-base: Provides root CA certificate for SSL testing
# - nginx-base: Main runtime (nginx + certbot + Node.js)
#
# WHY DIFFERENT BASE IMAGES?
# =========================
# 1. testca-base (testca):
#    - Purpose: Only provides /home/step/certs/root_ca.crt file
#    - Used for: SSL certificate testing in development/CI
#    - Why separate: Lightweight, only needed for one file copy
#    - Source: nginxproxymanager/testca (upstream)
#
# 2. nginx-base (main base):
#    - Purpose: Complete runtime environment
#    - Contains: Nginx, Certbot, Node.js, system dependencies
#    - Why separate: Heavy image, changes infrequently, benefits from caching
#    - Source: nginxproxymanager/nginx-full:certbot-node (upstream)
#
# This separation allows:
# - Better caching (base images rebuild less often)
# - Version tracking (know exactly which upstream versions are used)
# - Multi-arch efficiency (build base once per platform, reuse)
# - Registry management (base images can be shared across projects)

# Build arguments
ARG REGISTRY=ghcr.io
ARG IMAGE_NAME=shayneeo/fossvps-npm
ARG BASE_VERSION=latest
ARG TARGETPLATFORM

# Build metadata
ARG BUILD_VERSION
ARG BUILD_COMMIT
ARG BUILD_DATE

# ============================================================================
# STAGE 1: Extract test CA certificate
# ============================================================================
# Pull testca base image from registry (built via Dockerfile.build)
# We only need the root CA certificate file from this image
FROM ${REGISTRY}/${IMAGE_NAME}-testca:${BASE_VERSION} AS testca

# ============================================================================
# STAGE 2: Main application image
# ============================================================================
# Pull nginx-base from registry (built via Dockerfile.build)
# This is our main runtime base with nginx, certbot, and Node.js
FROM ${REGISTRY}/${IMAGE_NAME}-base:${BASE_VERSION}

ARG TARGETPLATFORM
ARG BUILD_VERSION
ARG BUILD_COMMIT
ARG BUILD_DATE

# Environment variables for s6-overlay and application
# See: https://github.com/just-containers/s6-overlay/blob/master/README.md
ENV SUPPRESS_NO_CONFIG_WARNING=1 \
	S6_BEHAVIOUR_IF_STAGE2_FAILS=1 \
	S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
	S6_FIX_ATTRS_HIDDEN=1 \
	S6_KILL_FINISH_MAXTIME=10000 \
	S6_VERBOSITY=1 \
	NODE_ENV=production \
	NPM_BUILD_VERSION="${BUILD_VERSION}" \
	NPM_BUILD_COMMIT="${BUILD_COMMIT}" \
	NPM_BUILD_DATE="${BUILD_DATE}" \
	NODE_OPTIONS="--openssl-legacy-provider"

# Install system dependencies
RUN echo "fs.file-max = 65535" > /etc/sysctl.conf \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends jq logrotate \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Install s6-overlay for process management
COPY docker/scripts/install-s6 /tmp/install-s6
RUN /tmp/install-s6 "${TARGETPLATFORM}" && rm -f /tmp/install-s6

# Expose ports
# 80: HTTP, 81: Admin UI, 443: HTTPS
EXPOSE 80 81 443

# Copy application code
COPY backend       /app
COPY frontend/dist /app/frontend

# Install Node.js dependencies
WORKDIR /app
RUN yarn install \
	&& yarn cache clean

# Copy configuration files and root CA certificate
# (Copy late to limit cache-busting by modifications)
COPY docker/rootfs /
COPY --from=testca /home/step/certs/root_ca.crt /etc/ssl/certs/NginxProxyManager.crt

# Cleanup: Remove dev-only files
RUN rm -rf /etc/s6-overlay/s6-rc.d/user/contents.d/frontend /etc/nginx/conf.d/dev.conf \
	&& chmod 644 /etc/logrotate.d/nginx-proxy-manager

# Volume for persistent data
VOLUME [ "/data" ]

# Entrypoint
ENTRYPOINT [ "/init" ]

# Image metadata
LABEL org.label-schema.schema-version="1.0" \
	org.label-schema.license="MIT" \
	org.label-schema.name="nginx-proxy-manager" \
	org.label-schema.description="Docker container for managing Nginx proxy hosts with a simple, powerful interface " \
	org.label-schema.url="https://github.com/ShayNeeo/fossvps-npm" \
	org.label-schema.vcs-url="https://github.com/ShayNeeo/fossvps-npm.git" \
	org.label-schema.version="${BUILD_VERSION}" \
	org.opencontainers.image.version="${BUILD_VERSION}" \
	org.opencontainers.image.revision="${BUILD_COMMIT}" \
	org.opencontainers.image.created="${BUILD_DATE}" \
	org.opencontainers.image.source="https://github.com/ShayNeeo/fossvps-npm"
