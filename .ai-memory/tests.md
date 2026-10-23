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

---

## Vérifier un build de contenu

Ces contrôles sont **obligatoires** après toute modification de `content/`. Un
build `exit=0` ne prouve **rien** : le prerender peut échouer silencieusement et
laisser des pages absentes.

```bash
npm run build > /tmp/build.log 2>&1; echo "exit=$?"

# 1. aucune route en échec (500 = YAML cassé, 404 = lien mort)
grep -cE '\[500\]|\[404\]' /tmp/build.log        # attendu : 0
grep -E '\[500\]|\[404\]|Linked from' /tmp/build.log

# 2. toutes les pages générées (50 = 25 FR + 25 EN)
find .output/public -name '*.html' | wc -l       # attendu : 50
grep -oE 'Prerendered [0-9]+ routes' /tmp/build.log  # attendu : ~137

# 3. aucun frontmatter YAML invalide (virgule+espace non quoté)
grep -rnE '^ +[a-z_]+: [^"].*: ' content/        # attendu : vide

# 4. aucune table de contenu manquante (cache périmé)
grep -c "no such table" /tmp/build.log            # attendu : 0
```

## Vérifier les liens internes

Un lien mort ne casse pas le build : il laisse un trou. Contrôle statique :

```bash
# comparer chaque lien ](/fr/…) et ](/en/…) aux routes dérivées des fichiers
# (préfixes numériques « 1. » retirés). Attendu : 0 lien brisé.
```

Le prerender fait aussi ce travail (`Linked from …`), mais uniquement si le
crawler atteint la page — donc seulement si les landings sont passés.

## Test navigateur (agent-browser)

```bash
export AGENT_BROWSER_SESSION="$(agent-browser session id --scope worktree --prefix task)"
agent-browser open http://localhost:3111/fr
agent-browser eval "document.querySelectorAll('h1').length"   # attendu : 1
agent-browser screenshot /tmp/check.png
agent-browser close
```

Points de contrôle visuels : logo « KwikTalk » (pas « kwiktalk-docs »), titres de
section accentués, un seul H1, images `public/images/` affichées, `og:image`
présent, **bascule de langue sur les 25 pages dans les deux sens**, aucune erreur
console, recherche `Ctrl+K` qui retourne des résultats.

### Bascule de langue — test obligatoire

Le sélecteur 🇫🇷/🇬🇧 ne fait que changer le **préfixe de locale** : si un chemin
FR n'existe pas EN (slug divergent), la page est **404**. À refaire après chaque
ajout de page.

```bash
# pour chaque page FR : ouvrir, cliquer le sélecteur, cliquer « English »,
# vérifier que location.pathname === chemin attendu ET qu'un h1 existe
# (h1 vide ou « Page not found » = KO)
```

Attendu : **25/25 dans chaque sens**.

⚠️ Piège de test : `agent-browser eval` renvoie du JSON **échappé** (`\"`) —
extraire les valeurs avec `tr -d '"'` ou lire `location.pathname` en texte brut,
sinon on compte des faux KO.

**Hygiène** : toujours un nom de session propre (`AGENT_BROWSER_SESSION`), et
`agent-browser close` en fin de tâche.
