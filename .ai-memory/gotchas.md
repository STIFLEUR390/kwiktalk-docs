# Pièges

À lire **avant** de toucher au déploiement, à Docker, à Dokploy ou au contenu.

## Docker & images

- **Le `rm` dans un stage ne réduit l'image que s'il est dans un stage séparé.**
  Dans le même stage, les fichiers supprimés restent dans l'historique des couches
  et `docker images` affiche toujours la taille d'avant. D'où le stage `trim`.
- **Les `COPY` doivent tous viser `./.output/...`**, jamais `./server/...`. Le `CMD`
  est `node .output/server/index.mjs` : un chemin décalé casse le démarrage avec
  `Cannot find module '/app/.output/server/index.mjs'`.
- **`node:22-alpine` hérite un `ENTRYPOINT`** (`docker-entrypoint.sh`) et un `CMD`
  (`node`). Notre Dockerfile ne surcharge que le `CMD`, pas l'`ENTRYPOINT` : c'est
  voulu et normal, ne pas le « corriger ».
- **Alpine = musl, pas glibc.** Les binaires `*-linux-x64` de `@img/sharp` sont
  inutiles (~18 Mo) ; seuls `*-linuxmusl-x64` servent.
- **`--provenance=false --sbom=false`** : sinon buildx ajoute des manifestes
  d'attestation qui gonflent l'image affichée de ~18 Mo pour rien.

## Réseau

- **Le metadata pull bloque le build** : toujours `--pull=false` quand
  `node:22-alpine` est déjà en cache.
- **`docker push` tombe sur les uploads longs.** Réessayer ne suffit pas, il faut
  scinder les couches. Voir `errors.md` §4.
- **Un `docker push` peut être « mort mais encore visible »** : vérifier avec
  `pgrep -x docker -a | grep push` avant d'en relancer un autre.

## Piège récurrent de shell : `pkill -f`

`pkill -f "docker push"` ou `pgrep -f "push-retry.sh"` **matche la commande shell
en cours d'exécution** (le pattern y figure littéralement) et tue le shell de
l'agent — d'où un exit 137/143 inexpliqué.

```bash
# DANGEREUX : tue sa propre commande
pkill -f "docker push"

# SÛR : cibler par PID, ou utiliser pgrep -x
DPID=$(pgrep -x docker -a | grep push | awk '{print $1}')
kill "$DPID"
```

## Dokploy (via MCP)

- **`memoryLimit` ne supporte ni `3gb` ni `3072m`** → laisser `null`.
- **Un déploiement `done` en ~2 s ne prouve rien** : il a peut-être juste pullé une
  image. Vérifier le conteneur réel (`docker.getContainersByAppNameMatch` →
  `docker.getConfig`) et le site, pas seulement le statut.
- **Les déploiements peuvent rester `running` à l'infini** (cf. erreur 1). Ne pas
  en lancer un second avant d'avoir tué le premier via `application.killBuild`.
- **`application.readLogs` renvoie une 500** sur une app en statut `idle` (jamais
  déployée). Ce n'est pas un bug MCP, c'est Dokploy.
- **Le MCP timeout (502 / 30 s) pendant un build** : le serveur Dokploy est saturé.
  Patienter et réessayer, ne pas conclure à une panne.
- **Format mémoire non respecté** : `application.update` accepte le champ mais
  Dokploy le rejette au déploiement. Ne pas se fier au `true` de l'API.

## Contenu Docus

- **Numérotation** : le préfixe `N.` ordonne la sidebar, n'apparaît pas dans l'URL.
  Dans un sous-dossier, ça **commence à 2** — le `1.` est réservé au `index.md`.
- **Pas d'`index.md` = 404** sur l'URL racine du dossier.
- **Deux locales à synchroniser** : tout ce qui est ajouté en `fr/` doit l'être en
  `en/`, sinon une langue a des pages en moins.
- **Le `<title>` suffixé « - kwiktalk-docs »** vient de Docus, pas du `seo.title`
  du frontmatter. Pas de `app.config.ts` dans le projet.
- **Ne pas supprimer `better-sqlite3`** : c'est un *peer dependency obligatoire* de
  Docus (`12.x`, non optionnel), utilisé par la base SQLite de contenu **au build**.
  Il est absent de `.output/` (donc pas dans l'image) — le retirer casserait le
  `npm install`/build. Inversement, Docus charge `@sqlite.org/sqlite-wasm` au
  runtime : pas de compilation native dans le conteneur.

## Git

- **Le push `main` ne déploie plus rien** : l'app est en mode `docker`
  (image pré-buildée). Il faut builder et pousser l'image **manuellement**.
- **Ne pas committer `.output/`** (70 Mo), il est dans `.gitignore`.
- **`aicommit2 -d` peut crasher** (`ERR_USE_AFTER_CLOSE` sur le prompt inquirer).
  Repli : commit manuel avec un message Conventional Commits.

## Docus : ce qui casse ou qui surprend

- **Un `seo.description` contenant ` : ` casse le prerender** (voir
  `errors.md` §8). Toujours **guillemeter** les valeurs de frontmatter qui
  contiennent un deux-points suivi d'une espace.
- **Docus rend le `title` du frontmatter en `<h1>`** : ne pas mettre `# Titre`
  en tête du corps Markdown, sinon **double H1** (mauvais pour le SEO). Vérifier
  avec `document.querySelectorAll('h1').length` — doit valoir 1.
- **Les titres de section de la sidebar viennent du nom de dossier**
  (`2.fonctionnalites` → « Fonctionnalites »), donc **sans accent ni casse
  voulue**. Il faut un fichier **`.navigation.yml`** dans le dossier :

  ```yaml
  title: Fonctionnalités
  ```

  Ces fichiers sont faciles à supprimer par mégarde quand on recrée une section.
- **Le logo et le suffixe des `<title>`** viennent de `site.name` (nuxt.config) et
  de `appConfig.header.title` (`app.config.ts`). Sans réglage, `site.name` vaut le
  nom du `package.json` → le logo affiche « kwiktalk-docs ». Docus **append**
  ` - {site.name}` à chaque `seo.title` : ne pas y remettre le nom du produit,
  sinon « Instances WhatsApp — KwikTalk - KwikTalk Docs ».
- **`ogImage` doit rester désactivé** tant que Google Fonts est injoignable depuis
  Node (voir `errors.md` §10).
- **Vérifier tous les liens internes après une restructuration** : le prerender
  les attrape (`Linked from ...`), mais un lien cassé fait un trou silencieux.
  Contrôle statique rapide : comparer les liens `](/fr/…)` des fichiers aux
  routes dérivées des chemins (préfixes numériques `1.` retirés).

## Portée de la documentation

- La doc couvre **les pages publiques + le rôle `user`**, pas l'administration.
- La protection se fait par **permission** (`permission:manage …`), pas par rôle.
  `/admin/*` est **l'espace utilisateur** (malgré le préfixe), `admin-panel/*` est
  la vue transverse **super-admin**.
- Les permissions du rôle `user` : `view dashboard`, `manage whatsapp instances`,
  `manage contacts`, `manage message templates`, `send messages`,
  `manage messages`, `send message campaigns`, `manage message campaigns`,
  `view incoming messages`, `manage incoming messages`, `manage api applications`,
  `manage chatbot`, `manage webhooks`.
- **Ne pas s'appuyer sur `docs/` du dépôt Laravel** (`kwiktalk-inertiajs`) : cette
  documentation est obsolète et sera retirée. La source de vérité est **le code**.

## Prerender : le fichier doit être servable (`autoSubfolderIndex`)

**Piège silencieux** : le prerender écrit bien `.output/public/fr.html` avec
`og:image`/`twitter:image`, mais **Nitro ne résout pas `/fr` → `fr.html`** : il
cherche `fr/index.html`. Résultat, la route tombait en **SSR** — réponse plus
longue et **sans les balises OG**, alors que le fichier existait.

Le défaut de Nuxt/Docus produit `x.html` (`autoSubfolderIndex: false`), alors que
la doc Nitro indique `true` par défaut :

```
autoSubfolderIndex: true   → /about → .output/public/about/index.html   (served)
autoSubfolderIndex: false  → /about → .output/public/about.html          (SSR wins)
```

**Fix appliqué** dans `nuxt.config.ts` :

```ts
nitro: { prerender: { autoSubfolderIndex: true } }
```

**Pour vérifier** — comparer la taille servie avec celle du fichier statique, et
compter les OG :

```bash
curl -s localhost:PORT/fr | wc -c
wc -c < .output/public/fr/index.html     # doit être égal
curl -s localhost:PORT/fr | grep -c og:image   # attendu : 1
```

**Symptôme inverse à ne pas confondre** : si `og:image` est absent, vérifier
d'abord que le fichier existe (`find .output/public -name index.html`), puis que
la réponse servie n'est pas du SSR.

## i18n : les slugs doivent être identiques entre locales

**Piège lourd** : `nuxt-i18n` construit la cible du sélecteur de langue en
**changeant uniquement le préfixe de locale** (`switchLocalePath`). Avec des slugs
traduits (`/fr/fonctionnalites/chatbot` → `/en/fonctionnalities/chatbot`), la page
cible **n'existe pas** → **404 silencieux**.

Constat initial : **16 pages sur 21** renvoyaient 404 après un clic sur 🇫🇷/🇬🇧.
Seules celles dont le slug était déjà identique passaient (`webhooks`, `chatbot`,
`notifications`, `faq`, `anti-spam`).

**Règle appliquée** : les **deux locales partagent exactement les mêmes chemins** ;
seul le contenu et les titres diffèrent. Slugs en anglais dans les deux cas
(`defaultLocale: 'en'`), traduction assurée par les fichiers `title:` /
`.navigation.yml`.

- `content/fr/` et `content/en/` doivent avoir **la même structure relative** —
  contrôle rapide : comparer les deux listes de chemins relatifs.
- Après tout ajout de page, vérifier que **les deux locales ont le même chemin** :
  une page ajoutée seulement en FR avec un slug traduit casserait la bascule.

**Test obligatoire** (agent-browser) : pour chaque page, cliquer le sélecteur de
langue et vérifier que le chemin cible existe. 404 = slug divergent.

```bash
# contrôle statique : chaque /fr/X a un /en/X
python3 -c "...comparer les chemins relatifs FR et EN..."
```

## La landing (`content/<locale>/index.md`) n'a aucun conteneur

`/fr` et `/en` ne passent **pas** par le layout `docs` : Docus sert la route
`/:lang` avec `app/templates/landing.vue`, qui rend le Markdown **brut**, sans
`UContainer` ni `UPage`. Seul `::u-page-hero` apporte son propre conteneur — tout le
Markdown qui suit est donc **collé aux bords**, pleine largeur.

Les deux index doivent être enveloppés :

```md
::u-container{class="py-10"}

## Première section
...
::
```

Conséquence de l'imbrication MDC : les composants **à l'intérieur** du conteneur
prennent **un `:` de plus** (`::note` → `:::note`, fermeture `:::`), sinon le
conteneur ne se ferme pas et la page casse au prerender.

## Dokploy doit **tirer** l'image, jamais builder le repo

Le provider de l'app `newkwiktalk-docs-b7euo7` doit être en **Docker (image
préconstruite)** : `devmaster2023/kwiktalk-docs:vN`. En mode Nixpacks/Dockerfile,
le log de déploiement commence par `Cloning Repo … to
/etc/dokploy/applications/<app>/code` puis lance un build **sur le VPS** → hit RAM
(`errors.md` §1), build `running` à l'infini.

Depuis le passage à nginx, un build Dockerfile depuis le repo échoue de toute façon
en quelques secondes : `.output/` est dans `.gitignore`, donc `COPY .output/public`
ne trouve rien. **Un log qui commence par « Cloning Repo » = mauvaise config côté
Dokploy**, pas un bug du code.

## Digest : podman ne renvoie pas celui de Docker Hub

`docker push` (podman) pousse un **index OCI** : le `Digest` local ne correspondra
jamais au digest que Docker Hub affiche, même quand l'image est bonne. Comparer
plutôt l'**id de config** :

```bash
docker pull docker.io/devmaster2023/kwiktalk-docs:vN
# l'id affiché doit être celui du build local (docker inspect --format '{{.Id}}')
```
