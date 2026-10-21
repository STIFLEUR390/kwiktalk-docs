# syntax=docker/dockerfile:1
#
# Docs Nuxt/Docus statique : le site est prerendered en local (SSG, un HTML par
# route), l'image ne fait que servir `.output/public` avec nginx. Aucun runtime
# Node/bun dans l'image, donc aucun SSR à l'exécution et rien à compiler ici.
#
# ⚠ Le prerender reste OBLIGATOIRE (`npm run build` en local, jamais sur le VPS :
# RAM insuffisante, voir .ai-memory/errors.md §1). Ne pas passer `ssr: false` :
# Nuxt n'écrirait plus qu'une coquille index.html, les 42 pages perdraient leur
# HTML prerendered (SEO, og:image) et les liens profonds tomberaient en 404.
#
#   npm run build                       # produit .output/public (~13 Mo)
#   docker build --pull=false --provenance=false --sbom=false \
#     -t devmaster2023/kwiktalk-docs:vN -f Dockerfile .

FROM nginx:alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY .output/public /usr/share/nginx/html

# Port attendu par le routeur Traefik de Dokploy (voir docker/nginx.conf)
EXPOSE 3000
