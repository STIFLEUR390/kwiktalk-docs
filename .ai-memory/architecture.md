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

## Build : deux étapes, deux machines

```
LOCAL (RAM dispo)                      VPS Dokploy (RAM faible)
──────────────────                     ────────────────────────
npm run build  →  .output/public       docker pull  devmaster2023/kwiktalk-docs:vN
docker build   →  image vN             docker run   →  port 3000
docker push    →  Docker Hub          Traefik      →  kwiktalk-docs.applix.fr
```

Le VPS ne compile **jamais** rien. Il ne fait que tirer une image déjà construite.

### Le `Dockerfile` : nginx + statique, rien d'autre

```dockerfile
FROM nginx:alpine
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY .output/public /usr/share/nginx/html
EXPOSE 3000
```

Aucun build dans Docker : `.output/public` doit **déjà** exister (`npm run build`),
sinon le `COPY` échoue franchement. L'image fait ~83 Mo (52 Mo de nginx:alpine
+ 13 Mo de statique), ne contient ni Node ni bun, et se construit en quelques
secondes au lieu de plusieurs minutes.

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
