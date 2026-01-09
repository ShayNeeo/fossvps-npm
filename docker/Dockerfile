# Dockerfile - Simple Runner Image
#
# PURPOSE:
# This image is a lightweight runtime that assumes all build artifacts
# (frontend dist, backend node_modules) already exist on the host filesystem.
#
# USAGE:
# 1. Build frontend: cd frontend && yarn install && yarn build
# 2. Build backend: cd backend && yarn install --production
# 3. Build docker: docker build -f docker/Dockerfile .
#
# This is ideal for local development or CI/CD pipelines where the
# build artifacts are managed outside of Docker.

ARG REGISTRY=ghcr.io
ARG IMAGE_NAME=shayneeo/fossvps-npm
ARG BASE_VERSION=fossvps-mod
ARG TARGETPLATFORM

# Build metadata
ARG BUILD_VERSION
ARG BUILD_COMMIT
ARG BUILD_DATE

# ============================================================================
# STAGE 1: Extract test CA certificate
# ============================================================================
FROM ${REGISTRY}/${IMAGE_NAME}-testca:${BASE_VERSION} AS testca

# ============================================================================
# STAGE 2: Main application image
# ============================================================================
FROM ${REGISTRY}/${IMAGE_NAME}-base:${BASE_VERSION}

ARG TARGETPLATFORM
ARG BUILD_VERSION
ARG BUILD_COMMIT
ARG BUILD_DATE

# Environment variables
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

# Install s6-overlay
COPY docker/scripts/install-s6 /tmp/install-s6
RUN /tmp/install-s6 "${TARGETPLATFORM}" && rm -f /tmp/install-s6

EXPOSE 80 81 443

# Copy PRE-BUILT artifacts from the host
# Frontend must be in frontend/dist/
# Backend must have node_modules/
COPY backend       /app
COPY frontend/dist /app/frontend

# Copy configuration files and root CA certificate
COPY docker/rootfs /
COPY --from=testca /home/step/certs/root_ca.crt /etc/ssl/certs/NginxProxyManager.crt

# Cleanup
RUN rm -rf /etc/s6-overlay/s6-rc.d/user/contents.d/frontend /etc/nginx/conf.d/dev.conf \
	&& chmod 644 /etc/logrotate.d/nginx-proxy-manager

WORKDIR /app
VOLUME [ "/data" ]
ENTRYPOINT [ "/init" ]

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
