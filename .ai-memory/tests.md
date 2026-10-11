# Tests

Ce projet **n'a ni linter, ni typecheck, ni test runner**. Les seuls scripts sont :

```json
"scripts": { "dev": "nuxt dev", "build": "nuxt build" }
```

Ne pas en inventer un. Ajouter un framework de test pour un site de documentation
statique serait de la complexité spéculative. Si un jour un vrai besoin de test
apparaît, il faudra l'argumenter.

---

## La preuve qu'un changement marche

La seule vérification qui compte : **le build passe, puis le site répond**.

### 1. Le build passe

```bash
npm run build
```

C'est le test le plus efficace qui existe ici : `nuxt build` exécute le bundler, la
résolution de dépendances, le prerender de toutes les pages et la génération des
types. La moindre page Markdown cassée, le moindre composant absent, le moindre
import cassé fait échouer le build.

Un build vert = le contenu est valide et toutes les routes se génèrent.

### 2. Les routes existent

```bash
find .output/public/fr -name "*.html" | sed 's|.*/public||' | sort
```

Comparer avec la liste attendue. Une page disparue du listing = une page cassée.

### 3. Le conteneur démarre

```bash
docker build --pull=false --provenance=false --sbom=false -t kwik-test-img -f Dockerfile .
docker run -d --name kwik-test -p 3999:3000 kwik-test-img
sleep 8
docker ps --filter name=kwik-test --format "{{.Status}}"    # doit dire "healthy"
docker logs kwik-test | tail -5                             # pas de MODULE_NOT_FOUND
```

### 4. Le site répond

```bash
for p in / /en /fr; do
  curl -s -o /dev/null -w "$p -> %{http_code}\n" http://localhost:3999$p
done
```

| Route | Attendu |
|---|---|
| `/` | `302` (redirect i18n) |
| `/en` | `200` |
| `/fr` | `200` |

Puis sur le site réel après déploiement :

```bash
curl -sL https://kwiktalk-docs.applix.fr/en | grep -o "<title>[^<]*</title>"
curl -s -o /dev/null -w "%{http_code}\n" https://kwiktalk-docs.applix.fr/fr/getting-started/introduction
```

---

## Hygiène

- **Toujours travailler dans des conteneurs jetables** nommés `kwik-test`,
  supprimés en fin de session (`docker rm -f kwik-test`).
- **Aucun push Docker Hub dans un test** : le push est lent (~20-30 min) et
  consomme du quota. Ne pousser qu'une image validée.
- **Ne rien détruire sur le VPS Dokploy** sans accord : il héberge Keycloak,
  SearXNG, ntfy, Hermes, Rustrak et d'autres services de production.
- Ne jamais lancer `docker system prune` sans dry-run préalable.
- Nettoyer les images locales de test :
  `docker rmi devmaster2023/kwiktalk-docs:vN` (l'image poussée reste disponible sur
  Docker Hub).
