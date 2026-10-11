# syntax=docker/dockerfile:1

# Image pré-buildée : le build Nuxt/Docus est trop gourmand en RAM pour le VPS
# (le prerender dépasse les 2 Go et met le swap en PLS, ce qui fait "pendre" le
# build Dokploy). On build en local, on pousse sur Docker Hub, Dokploy pull.
#
#   docker build --pull=false --provenance=false --sbom=false -t devmaster2023/kwiktalk-docs:vN .
#   docker push devmaster2023/kwiktalk-docs:vN
#
# Le push Docker Hub est instable depuis ce réseau : un upload long d'une seule
# couche se fait couper. D'où le scindage en couches courtes ci-dessous.

# Stage "trim" : on élimine les binaires inutiles AVANT la couche finale,
# sinon ils restent dans l'historique des couches et l'image ne rétrécit pas.
FROM node:22-alpine AS trim
WORKDIR /app
COPY .output ./.output
# Alpine = musl : les binaires sharp glibc (~18 Mo) ne servent à rien ici
RUN rm -rf /app/.output/server/node_modules/@img/sharp-libvips-linux-x64 \
           /app/.output/server/node_modules/@img/sharp-linux-x64

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
ENV NITRO_PRESET=node-server
ENV PORT=3000

# .output scindé en couches sans recouvrement, chacune < 20 Mo.
COPY --from=trim /app/.output/server/node_modules/@img ./.output/server/node_modules/@img
COPY --from=trim /app/.output/server/node_modules/@sqlite.org ./.output/server/node_modules/@sqlite.org
COPY --from=trim /app/.output/server/node_modules/@shikijs ./.output/server/node_modules/@shikijs
COPY --from=trim --exclude=@img --exclude=@sqlite.org --exclude=@shikijs /app/.output/server/node_modules ./.output/server/node_modules
COPY --from=trim /app/.output/server/chunks ./.output/server/chunks
COPY --from=trim /app/.output/server/index.mjs /app/.output/server/index.mjs.map /app/.output/server/package.json ./.output/server/
COPY --from=trim /app/.output/public ./.output/public
COPY --from=trim /app/.output/nitro.json ./.output/nitro.json

EXPOSE 3000
CMD ["node", ".output/server/index.mjs"]
