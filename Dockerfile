# syntax=docker/dockerfile:1
#
# Docs Nuxt/Docus : le site est prerendered pendant le build de l'image
# (étage `build`), puis servi en statique par nginx. Un HTML par route, aucun
# runtime Node dans l'image finale.
#
# ⚠ Le prerender demande ~2 Go de RAM. Sur le VPS Dokploy c'est la limite connue :
# NODE_OPTIONS est plafonné à 1536 Mo (mesure faite en local, voir
# nixpacks.toml) pour éviter que V8 réclame 6 Go et fasse swapper la machine.
# Si le build reste `running` sans fin, c'est un manque de RAM, pas un bug :
# voir .ai-memory/errors.md §1.
#
# Build local (recommandé, RAM dispo) :
#   docker build --pull=false --provenance=false --sbom=false \
#     -t devmaster2023/kwiktalk-docs:vN -f Dockerfile .

FROM oven/bun:1 AS build
WORKDIR /app

# Toolchain de secours : better-sqlite3 (peer dep de Docus) tombe sur node-gyp
# si prebuild-install n'a pas de prébuilt pour la plateforme.
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .

# static : tout est prerendered dans .output/public, servi par nginx ci-dessous.
# `site.url` doit rester défini dans nuxt.config, sinon le sitemap échoue.
ENV NITRO_PRESET=static
ENV NODE_OPTIONS="--max-old-space-size=1536"
RUN bun run build

FROM nginx:alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/.output/public /usr/share/nginx/html

# Port attendu par le routeur Traefik de Dokploy (voir docker/nginx.conf)
EXPOSE 3000
