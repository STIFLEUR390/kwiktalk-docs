# Workflows

## Déployer une modification

`Auto Deploy` est actif sur l'app `newkwiktalk-docs-b7euo7` : **un `git push` sur
`main` déclenche le déploiement**. Dokploy clone le repo, construit le `Dockerfile`
sur le VPS (prerender → `.output/public` → nginx), puis bascule le conteneur.

```bash
git push origin main      # = déploiement
```

Risque connu : le prerender demande ~2 Go de RAM (`errors.md` §1). Si le build reste
`running` sans fin, c'est la RAM du VPS, pas le code — voir la procédure de secours
ci-dessous.

### Vérifier localement avant de pousser (optionnel mais rapide)

```bash
npm run build        # ~1 min, produit .output/public (45 fichiers HTML)
npm run dev          # contrôle visuel
```

Ou construire l'image complète en local, c'est le même `Dockerfile` que sur le VPS :

```bash
docker build -t kwik-test-img -f Dockerfile .
docker run -d --name kwik-test -p 3999:3000 kwik-test-img
sleep 5
curl -s -o /dev/null -w "/fr -> %{http_code}\n" http://localhost:3999/fr   # 200
curl -s -o /dev/null -w "/  -> %{http_code}\n" http://localhost:3999/     # 302
docker rm -f kwik-test
```

Premier build à froid : ~20 min (l'apt du toolchain `better-sqlite3` domine).
Ensuite les couches sont en cache : ~1 min.

### Secours : image locale (si le build VPS pend)

```bash
docker build --pull=false --provenance=false --sbom=false \
  -t devmaster2023/kwiktalk-docs:vN -f Dockerfile .
docker push devmaster2023/kwiktalk-docs:vN
```

`N` s'incrémente à chaque envoi. **Ne jamais réutiliser `:latest`** (une image
périmée d'un ancien projet traîne sur ce compte, `errors.md` §2). Pour que Dokploy
serve cette image sans builder, l'app doit être en **General → Source = Docker**
avec `devmaster2023/kwiktalk-docs:vN` (voir `gotchas.md`).

### Vérifier en ligne

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://kwiktalk-docs.applix.fr/fr
curl -s https://kwiktalk-docs.applix.fr/fr | grep -c py-10    # sanity check connu
```

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
