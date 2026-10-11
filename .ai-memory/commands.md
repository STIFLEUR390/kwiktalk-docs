# Commandes

Le projet n'a **ni linter, ni typecheck, ni test runner**. Les seuls scripts sont
`dev` et `build`. Ne pas en inventer (voir [`tests.md`](tests.md)).

## Développement

```bash
npm install
npm run dev              # http://localhost:3000
npm run build            # produit .output/ (local uniquement, ~1-2 min)
```

## Déploiement

Le build se fait **en local**, jamais sur le VPS. Détail dans
[`workflows.md`](workflows.md). Raccourci :

```bash
npm run build
docker build --pull=false --provenance=false --sbom=false \
  -t devmaster2023/kwiktalk-docs:vN -f Dockerfile .
docker push devmaster2023/kwiktalk-docs:vN
```

- `--pull=false` : évite un metadata pull vers Docker Hub qui **bloque** le build.
- `--provenance=false --sbom=false` : supprime les manifestes d'attestation qui
  gonflent l'image sans utilité.

## Vérifier l'image avant de la pousser

```bash
# doit afficher [node .output/server/index.mjs] et un user vide
docker inspect devmaster2023/kwiktalk-docs:vN --format '{{.Config.Cmd}} | {{.Config.User}}'

# test de fumée : / et /fr doivent répondre
docker run -d --name kwik-test -p 3999:3000 devmaster2023/kwiktalk-docs:vN
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3999/fr   # 200
docker rm -f kwik-test
```

## Diagnostic

```bash
curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" https://kwiktalk-docs.applix.fr/fr
docker images devmaster2023/kwiktalk-docs --format "{{.Tag}} {{.Size}}" | sort
docker history devmaster2023/kwiktalk-docs:vN --human --format "{{.Size}}\t{{.CreatedBy}}" | grep -i copy
```

## Nettoyage

```bash
docker rmi devmaster2023/kwiktalk-docs:vN   # une image poussée peut être retirée en local
docker image prune -f                       # images orphelines
```

Ne **jamais** exécuter `docker system prune` sans `--dry-run` préalable : le VPS
Dokploy héberge toutes les autres applications (Keycloak, SearXNG, ntfy, Hermes,
Rustrak…). Toute action destructive sur le serveur Dokploy passe par une validation
explicite.

## Images de code pour la doc

`codesnap` est installé. Toujours lui préférer une capture d'écran brute :

```bash
codesnap -f nuxt.config.ts -o content/fr/2.essentials/1.config.png
codesnap -f nuxt.config.ts --range 3:10 -o content/fr/config.png   # lignes 3 à 10
codesnap -c "npm run build" --execute "npm run build" -o build.png  # sortie de commande
codesnap -f Dockerfile -o clipboard                                # presse-papiers
```

## Git & GitHub

```bash
git add -A && git commit -m "build(docker): ..."    # Conventional Commits
gh pr create / gh pr checkout / gh run list
```

Le push `main` **ne déclenche pas** de déploiement automatique : l'app Dokploy est
en mode `docker` (image pré-buildée), plus en mode `github`.
