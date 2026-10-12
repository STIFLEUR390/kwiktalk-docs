# AGENTS.md — kwiktalk-docs

Site de documentation **KwikTalk**, basé sur **Docus** (Nuxt 4 + @nuxt/content),
bilingue **fr/en**. Hébergé sur **Dokploy**.

> Mémoire de projet détaillée : [`.ai-memory/`](.ai-memory/index.md). La lire en
> premier au démarrage d'une session ; charger le reste à la demande.

---

## Langue

**Toujours répondre en français.** Le code, les noms de symboles, les commandes et
les messages d'erreur restent en anglais.

---

## Règle n°1 : ne jamais builder sur le VPS

Le prerender Nuxt/Docus demande ~2 Go de RAM. Le VPS Dokploy swappe, et le build
reste `running` **indéfiniment** sans jamais passer en erreur. C'est le piège n°1 du
projet, déjà rencontré une dizaine de fois.

**Le build se fait en local**, l'image est poussée sur Docker Hub, Dokploy ne fait
que la `pull`. Voir [`.ai-memory/workflows.md`](.ai-memory/workflows.md).

```bash
npm run build                                       # produit .output/
docker build --pull=false --provenance=false --sbom=false \
  -t devmaster2023/kwiktalk-docs:vN -f Dockerfile .
docker push devmaster2023/kwiktalk-docs:vN
```

Le **push Docker Hub est instable** depuis ce réseau : un upload long d'une seule
couche est coupé. Le `Dockerfile` scinde donc `.output` en couches de < 20 Mo —
ne pas les regrouper, sinon le push échoue.

---

## Commandes utiles

| Tâche | Commande |
|---|---|
| Dev | `npm run dev` → http://localhost:3000 |
| Build | `npm run build` |
| Image Docker | voir ci-dessus |
| Voir le site live | https://kwiktalk-docs.applix.fr |

Pas de linter, pas de test runner, pas de script de typecheck dans ce projet. Ne pas
en inventer — voir [`.ai-memory/tests.md`](.ai-memory/tests.md).

---

## Contenu

- Tout le contenu vit dans `content/{fr,en}/`, **42 pages** (21 par locale).
- **Les deux locales partagent exactement les mêmes chemins** : sections
  `1.overview`, `2.features`, `3.integrations`, `4.account`, `5.resources`, et des
  fichiers identiques. Slugs **anglais dans les deux cas**, traduction portée par
  `title:` et `.navigation.yml`.
  ⚠️ Obligatoire : `nuxt-i18n` ne traduit que le **préfixe de locale**, un slug
  divergent donne un **404 au clic sur le sélecteur de langue** (16 pages/21 avant
  correction). Toute page ajoutée doit exister **aux deux mêmes chemins**.
- **Les fichiers sont numérotés** : le préfixe `1.` d'un dossier est réservé à son
  `index.md`, les pages commencent à `2.`. Le préfixe n'apparaît pas dans l'URL.
- Chaque dossier de section contient un **`.navigation.yml`** (`title:`) : sans lui,
  la sidebar affiche le nom de dossier brut — d'où les titres français séparés
  (« Pour démarrer », « Fonctionnalités », « Mon compte »…).
- Un dossier **sans `index.md` renvoie un 404** sur son URL racine.
- Les deux locales doivent rester **synchronisées** : toute page ajoutée en `fr`
  doit l'être en `en`, et inversement.

### Pièges de rédaction

- **Guillemeter** toute valeur de frontmatter contenant ` : `, sinon le prerender
  échoue en 500 et la page manque au build (voir `.ai-memory/errors.md` §8).
- **Ne pas remettre `# Titre`** en tête du corps : Docus génère déjà le `<h1>`
  depuis `title:` — sinon double H1.
- Ne pas répéter « KwikTalk » dans `seo.title` : Docus ajoute déjà
  ` - KwikTalk Docs`.
- Après modification : `.ai-memory/tests.md` liste les 4 contrôles obligatoires
  (build sans 500/404, 36 HTML, YAML valide, cache non périmé).

Pour générer une image de code dans la doc, utiliser **`codesnap`** (déjà installé)
plutôt qu'une capture d'écran. Sortie dans `public/images/` :

```bash
codesnap -f src/foo.ts --range 3:10 --disable-watermark -o public/images/foo.png
```

---

## Ne pas faire

- **Ne pas commit `.output/`** — il est dans `.gitignore` pour de bon (70 Mo de
  build).
- **Ne pas toucher au `memoryLimit` Dokploy** au format `3gb`/`3072m` : Dokploy le
  rejette. Le laisser `null`.
- **Ne pas faire `docker push :latest`** à la place d'un tag versionné : `:latest`
  traîne sur le compte Docker Hub depuis un ancien projet et sert un contenu faux.
- **Ne pas supprimer `nixpacks.toml`** : il documente la limite mémoire connue du
  VPS, utile comme trace.
- **Aucune clé, token ou mot de passe** dans le code, les docs ou les commandes.

---

## Convention de nommage des tags

Tagger en `vN` incrémental (`v6`, `v7`…), jamais `latest`. Après un push, vérifier
que le digest correspond avant de pointer Dokploy dessus :

```bash
docker inspect devmaster2023/kwiktalk-docs:vN --format '{{.Config.Cmd}}'
# attendu : [node .output/server/index.mjs]   (et non "node server.js")
```
