# Workflows

## Déployer une modification

Le seul workflow qui compte. **Ne jamais builder sur le VPS** : le prerender dépasse
la RAM disponible et le build reste `running` sans fin (`errors.md` §1).

### 1. Build local

```bash
npm run build
```

Produit `.output/` (~70 Mo). Environ 1-2 min. Vérifier que `.output/public/` contient
les pages attendues :

```bash
find .output/public/fr -name "*.html" | sed 's|.*/public||'
```

### 2. Construire l'image

```bash
docker build --pull=false --provenance=false --sbom=false \
  -t devmaster2023/kwiktalk-docs:vN -f Dockerfile .
```

`N` s'incrémente à chaque déploiement. **Ne jamais réutiliser `:latest`** (une image
périmée d'un ancien projet traîne sur ce compte, `errors.md` §2).

### 3. Vérifier avant de pousser

```bash
# le Cmd doit être [node .output/server/index.mjs], le User vide
docker inspect devmaster2023/kwiktalk-docs:vN --format '{{.Config.Cmd}} | {{.Config.User}}'

# test de fumée local
docker run -d --name kwik-test -p 3999:3000 devmaster2023/kwiktalk-docs:vN
sleep 8
curl -s -o /dev/null -w "/fr -> %{http_code}\n" http://localhost:3999/fr    # 200
curl -s -o /dev/null -w "/en -> %{http_code}\n" http://localhost:3998/en    # 200
docker rm -f kwik-test
```

`/` renvoie `302` (redirect i18n) : c'est normal.

### 4. Pousser

```bash
docker push devmaster2023/kwiktalk-docs:vN
```

**Compter ~20-30 min** si le réseau est dégradé. Le transfert est lent mais, avec les
couches scindées, il passe normalement **du premier coup**. Si ça échoue malgré tout,
c'est que les couches sont trop grosses : revoir le `Dockerfile`
(`errors.md` §4).

Pour relancer sans risquer de tuer sa propre shell, ne pas utiliser `pkill -f` :

```bash
DPID=$(pgrep -x docker -a | grep push | awk '{print $1}'); [ -n "$DPID" ] && kill "$DPID"
```

### 5. Pointer Dokploy dessus

Via le MCP `dokploy` :

```
dokploy.application-saveDockerProvider
  applicationId: S9Oi1xObtJOt8Azg4oYwW
  dockerImage:   devmaster2023/kwiktalk-docs:vN
  registryUrl:   null      (Docker Hub public, pas de registry configuré)
  username:      null
  password:      null

dokploy.application-deploy
  applicationId: S9Oi1xObtJOt8Azg4oYwW
  title:         "deploy: <ce qui change>"
```

Ne **pas** toucher à `memoryLimit` / `memoryReservation` (rester `null`).

### 6. Vérifier le résultat

Le déploiement doit être `done` en ~5-7 s (simple `docker pull`).

```bash
# le statut "done" ne suffit pas : vérifier le conteneur réel
dokploy.docker-getContainersByAppNameMatch   appName: newkwiktalk-docs-b7euo7
dokploy.docker-getConfig                    containerId: <le nouveau>

# puis le site lui-même
curl -sL https://kwiktalk-docs.applix.fr/en | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "%{http_code}\n" https://kwiktalk-docs.applix.fr/fr/getting-started/introduction
```

Confirmer que le contenu est **le bon** et pas celui d'une ancienne image.

---

## Ajouter une page de documentation

1. Créer le Markdown dans **les deux locales** :
   `content/fr/3.<section>/N.<page>.md` et `content/en/3.<section>/N.<page>.md`
2. Le numéro `N.` fixe l'ordre dans la sidebar. Dans un sous-dossier il commence à
   **2**.
3. Vérifier la route générée : `find .output/public/fr -name "*.html"` après build.
4. Pas d'`index.md` = l'URL racine du dossier 404. Ajouter un `index.md` si on veut
   cette URL.

---

## Ajouter une capture de code

Toujours **`codesnap`**, jamais une capture d'écran brute :

```bash
codesnap -f nuxt.config.ts -o content/fr/2.essentials/1.config.png
codesnap -f Dockerfile --range 10:20 -o content/fr/dockerfile.png
codesnap --execute "npm run build" --skip -o content/fr/build.png   # la commande, pas la sortie
```

Générer dans `/tmp` puis déplacer à sa place finale si le chemin est incertain. Ne
rien laisser de jetable dans le dépôt.

---

## Rollback

L'image précédente reste sur Docker Hub tant qu'elle n'est pas supprimée. Pour
revenir en arrière, il suffit de repointer Dokploy sur le tag précédent via
`application-saveDockerProvider` puis `application-deploy`. Aucun rebuild nécessaire.

---

## Auditer l'état Dokploy

```
dokploy.settings-health
dokploy.settings-getDokployVersion          → actuellement v0.30.8
dokploy.overview-services                   → tous les services + statuts
dokploy.deployment-all                      applicationId: S9Oi1xObtJOt8Azg4oYwW
dokploy.docker-getContainers                → état de tous les conteneurs
```

Le VPS héberge d'autres applications (Keycloak, SearXNG, ntfy, Hermes, Rustrak,
Linkwarden, RustFS, Mailpit…). **Toute action destructive Docker côté serveur exige
une validation explicite.** Toujours un dry-run/preview d'abord.
