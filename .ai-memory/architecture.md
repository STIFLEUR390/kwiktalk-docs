# Architecture

## Stack

**Docus** — thème de documentation posé sur **Nuxt 4** avec `@nuxt/content`.
Le contenu est du Markdown. Tout est **prerendered au build** (`NITRO_PRESET=static`) :
un HTML par route dans `.output/public`, aucun SSR à l'exécution.

```
content/{fr,en}/     Markdown, source unique du contenu
public/              favicon.ico, mountains.webp
nuxt.config.ts       extends: ['docus'] + module i18n
Dockerfile           nginx:alpine + COPIE de .output/public (aucun runtime Node)
nixpacks.toml        OBSOLÈTE (le build ne se fait plus sur le VPS), conservé
                     comme trace de la limite mémoire du VPS
```

## `nuxt.config.ts`

```ts
export default defineNuxtConfig({
  extends: ['docus'],
  modules: ['@nuxtjs/i18n'],
  i18n: {
    defaultLocale: 'en',
    locales: [ { code: 'en', name: 'English' }, { code: 'fr', name: 'Français' } ],
  },
})
```

Pas de `app.config.ts` : tout le styling/branding Docus est par défaut. Le nom du
site affiché dans le `<title>` suffixe vient de Docus, pas de ce fichier.

## Build : deux étages, dans le `Dockerfile`, sur Dokploy

```
git push main  →  Dokploy clone  →  docker build (VPS)
                                     ├─ étage build : bun install + nuxt build
                                     │                → .output/public (prerender)
                                     └─ étage final : nginx:alpine + statique
                                   → conteneur port 3000 → Traefik
```

`Auto Deploy` est actif : **un push sur `main` déploie**. L'image Docker Hub
(`devmaster2023/kwiktalk-docs:vN`) n'est plus le chemin normal, elle sert de
secours/rollback.

### Le `Dockerfile` en deux étages

```dockerfile
FROM oven/bun:1 AS build          # + apt python3 make g++ (better-sqlite3)
COPY package.json bun.lock ./     # bun install --frozen-lockfile
COPY . .
ENV NITRO_PRESET=static
ENV NODE_OPTIONS="--max-old-space-size=1536"
RUN bun run build                 # prerender → .output/public

FROM nginx:alpine                 # 2e étage : 13 Mo de statique
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/.output/public /usr/share/nginx/html
```

`.output` et `node_modules` restent **gitignored et dockerignored** : le build les
régénère. Les committer n'aiderait à rien et polluerait le repo.

**RAM** : le `bun run build` demande ~2 Go. Sur le VPS c'est la limite connue
(`errors.md` §1) : d'où le plafond à 1536 Mo. Premier build sur une machine froide :
~20 min (l'apt du toolchain domine) ; les suivants réutilisent le cache de couches
(~1 min de build Nuxt + install).

**Ne pas passer `ssr: false`** : Nuxt n'écrirait plus qu'une coquille `index.html`
(22 routes au lieu de 189, 5 HTML au lieu de 45, plus d'`og:image` dans le HTML) et
les liens profonds tomberaient en 404 avec le `try_files` du `nginx.conf`.
Le « statique » utile ici, c'est **SSG** (prerender), pas SPA.

### Pourquoi plus de couches scindées

L'ancienne image `node-server` (~700 Mo) devait être scindée en couches de < 20 Mo
à cause des pushs Docker Hub interrompus. Avec 13 Mo de statique en une seule
couche, le problème ne se pose plus.

## Routing

Le prérendu ne génère que les pages qui **existent en Markdown**.

| URL | Résultat |
|---|---|
| `/` | `302` → `/en` (redirect i18n) |
| `/en`, `/fr` | `200` (l'`index.md` de la locale) |
| `/fr/getting-started/introduction` | `200` |
| `/fr/getting-started/` | **`404`** — pas d'`index.md` dans le dossier |

### Numérotation Docus

Les fichiers portent un préfixe numérique qui fixe l'ordre dans la sidebar :

```
content/fr/
├── index.md              → /
├── 1.getting-started/    → /fr/getting-started/
│   ├── 2.introduction.md →  /fr/getting-started/introduction
│   └── 3.installation.md →  /fr/getting-started/installation
└── 2.essentials/
    └── 1.markdown-syntax.md → /fr/essentials/markdown-syntax
```

Le préfixe **n'apparaît pas dans l'URL**. La numérotation **commence à 2** dans un
sous-dossier : le `1.` est réservé au `index.md` du dossier. Comme `1.getting-started/`
n'a **pas** d'`index.md`, son URL racine 404.

## Ce qui tourne réellement au runtime

```
node .output/server/index.mjs      (Nitro, preset node-server)
└── .output/server/node_modules/
    ├── @sqlite.org/sqlite-wasm    ← recherche côté serveur, en WASM
    ├── @img (sharp, musl)         ← génération d'images ipx/og
    └── @shikijs …                 ← coloration syntaxique
```

`better-sqlite3` est un **peer dependency obligatoire de Docus** (`12.x`, non
optionnel) : il sert à la **base SQLite de contenu au build**. En revanche il est
**absent** de `.output/server/node_modules` (Docus charge `@sqlite.org/sqlite-wasm`
au runtime) → **aucune compilation native dans le conteneur**, l'image reste
minimale. Ne pas le retirer du `package.json` : le build casserait.
