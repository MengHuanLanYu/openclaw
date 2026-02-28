ARG BASE_IMAGE=ghcr.io/coollabsio/openclaw-base:latest

FROM ${BASE_IMAGE}

ENV NODE_ENV=production


# Patch @homebridge/ciao to truncate instead of crash on long hostnames
RUN node -e "const fs=require('fs');const f='/opt/openclaw/app/node_modules/.pnpm/@homebridge+ciao@1.3.5/node_modules/@homebridge/ciao/lib/coder/DNSLabelCoder.js';let c=fs.readFileSync(f,'utf8');c=c.replace('assert_1.default.ok(labelLength <= 63','if(labelLength>63){label=label.slice(0,63);labelLength=63;}assert_1.default.ok(labelLength <= 63');fs.writeFileSync(f,c);console.log('patched');"


RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    nginx \
    apache2-utils \
  && rm -rf /var/lib/apt/lists/*

# Remove default nginx site
RUN rm -f /etc/nginx/sites-enabled/default

COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

ENV NPM_CONFIG_PREFIX="/data/npm-global" \
    UV_TOOL_DIR="/data/uv/tools" \
    UV_CACHE_DIR="/data/uv/cache" \
    GOPATH="/data/go" \
    PATH="/data/npm-global/bin:/data/uv/tools/bin:/data/go/bin:${PATH}"

ENV PORT=8000
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:${PORT:-8000}/healthz || exit 1

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
