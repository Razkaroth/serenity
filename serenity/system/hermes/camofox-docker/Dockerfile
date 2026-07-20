FROM node:22-slim

ARG CAMOUFOX_VERSION=135.0.1
ARG CAMOUFOX_RELEASE=beta.24
ARG TARGETARCH

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    curl \
    fonts-liberation \
    fonts-noto-color-emoji \
    fontconfig \
    git \
    libasound2 \
    libdbus-glib-1-2 \
    libegl1-mesa \
    libgbm1 \
    libgl1-mesa-dri \
    libgtk-3-0 \
    libx11-xcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxt6 \
    libxtst6 \
    python3-minimal \
    unzip \
    xvfb \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Use upstream's release lockfile. The npm package declares camoufox-js with a
# broad range, which currently resolves to an incompatible virtual-display API.
# Browser binary installation is handled explicitly below.
RUN git clone --depth 1 --branch v1.11.2 \
    https://github.com/jo-inc/camofox-browser.git /app \
  && npm ci --omit=dev --ignore-scripts \
  && npm rebuild better-sqlite3

RUN set -eux; \
  case "${TARGETARCH}" in \
    amd64) camoufox_arch=x86_64 ;; \
    arm64) camoufox_arch=arm64 ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
  esac; \
  mkdir -p /root/.cache/camoufox; \
  curl --fail --location \
    "https://github.com/daijro/camoufox/releases/download/v${CAMOUFOX_VERSION}-${CAMOUFOX_RELEASE}/camoufox-${CAMOUFOX_VERSION}-${CAMOUFOX_RELEASE}-lin.${camoufox_arch}.zip" \
    --output /tmp/camoufox.zip; \
  (unzip -q /tmp/camoufox.zip -d /root/.cache/camoufox || true); \
  chmod -R 755 /root/.cache/camoufox; \
  printf '{"version":"%s","release":"%s"}\n' "${CAMOUFOX_VERSION}" "${CAMOUFOX_RELEASE}" > /root/.cache/camoufox/version.json; \
  test -f /root/.cache/camoufox/camoufox-bin; \
  rm /tmp/camoufox.zip

ENV CAMOFOX_PORT=9377

EXPOSE 9377

CMD ["sh", "-c", "node --max-old-space-size=${MAX_OLD_SPACE_SIZE:-128} server.js"]
