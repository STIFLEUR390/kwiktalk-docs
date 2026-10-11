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
- **`better-sqlite3` n'est pas utilisé au runtime** : Docus charge
  `@sqlite.org/sqlite-wasm`. La dépendance native ne sert qu'au build, si tant est
  qu'elle serve.

## Git

- **Le push `main` ne déploie plus rien** : l'app est en mode `docker`
  (image pré-buildée). Il faut builder et pousser l'image **manuellement**.
- **Ne pas committer `.output/`** (70 Mo), il est dans `.gitignore`.
- **`aicommit2 -d` peut crasher** (`ERR_USE_AFTER_CLOSE` sur le prompt inquirer).
  Repli : commit manuel avec un message Conventional Commits.
