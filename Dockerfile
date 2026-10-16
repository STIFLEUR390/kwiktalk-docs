# syntax=docker/dockerfile:1
#
# Docs Nuxt/Docus en statique, même pattern que le Dockerfile Astro :
# build avec bun (NITRO_PRESET=static → .output/public), runtime nginx.
#
# ⚠ Build LOCAL uniquement (trop gourmand en RAM pour le VPS) :
#   docker build --pull=false --provenance=false --sbom=false \
#     -t devmaster2023/kwiktalk-docs:vN -f Dockerfile .
#
# Image finale ~35 Mo (nginx + 13 Mo de statique) : le push Docker Hub
# tient désormais en une couche courte — pas besoin de split-layer.

FROM oven/bun:1 AS build
WORKDIR /app

# Toolchain de secours : better-sqlite3 (peer dep de Docus) tombe sur
# node-gyp si prebuild-install n'a pas de prébuild pour la plateforme.
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .

# Static : tout est prerendered dans .output/public (189 routes),
# servi par nginx ci-dessous. `site.url` doit être défini dans
# nuxt.config sinon le prerender du sitemap échoue au build.
ENV NITRO_PRESET=static
ENV NODE_OPTIONS="--max-old-space-size=1536"
RUN bun run build

FROM nginx:alpine AS runtime
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/.output/public /usr/share/nginx/html

# Port attendu par le routeur Traefik de Dokploy (voir docker/nginx.conf)
EXPOSE 3000
