# Architecture

## Stack

**Docus** — thème de documentation posé sur **Nuxt 4** avec `@nuxt/content`.
Le contenu est du Markdown, le rendu se fait à la volée (SSR Nitro) + prérendu des
routes au build.

```
content/{fr,en}/     Markdown, source unique du contenu
public/              favicon.ico, mountains.webp
nuxt.config.ts       extends: ['docus'] + module i18n
Dockerfile           multi-stage : trim → image finale scindée en couches
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
npm run build  →  .output/             docker pull  devmaster2023/kwiktalk-docs:vN
docker build   →  image vN             docker run   →  port 3000
docker push    →  Docker Hub          Traefik      →  kwiktalk-docs.applix.fr
```

Le VPS ne compile **jamais** rien. Il ne fait que tirer une image déjà construite.

### Le `Dockerfile` en deux stages

1. **`trim`** : copie `.output/` et supprime les binaires sharp **glibc**
   (`sharp-libvips-linux-x64`, `sharp-linux-x64`, ~18 Mo). Inutiles sur Alpine qui
   est en **musl**. Ce nettoyage doit se faire dans un stage séparé, sinon les
   fichiers restent dans l'historique des couches et l'image ne rétrécit pas.
2. **Image finale** : recopie `.output/` **en couches séparées, sans recouvrement**,
   chacune < 20 Mo.

### Pourquoi les couches sont scindées

Le réseau vers `registry-1.docker.io` est instable : un upload continu de > 30 s est
interrompu (`use of closed network connection`). En scindant `.output` en morceaux
de < 20 Mo, chaque upload est court et résiste. **Regrouper les `COPY` ferait
échouer le push.**

Ordre des couches (du plus gros au plus petit, toutes < 20 Mo) :

```
@img            19.3 Mo   binaires sharp musl
node_modules    19.4 Mo   @img/@sqlite.org/@shikijs exclus (déjà copiés)
public           8.3 Mo   assets statiques
chunks           4.5 Mo   bundles serveur
@sqlite.org      1.4 Mo   sqlite-wasm (utilisé au runtime)
@shikijs         1.1 Mo   coloration syntaxique
index.mjs …     16.4 Ko   entrypoint
nitro.json        4.1 B
```

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
