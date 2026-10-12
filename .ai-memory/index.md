# .ai-memory/ — kwiktalk-docs

Mémoire de projet partagée et versionnée. **Lire ce fichier en premier** au
démarrage d'une session, puis charger les autres fichiers uniquement si la tâche le
demande.

## Le projet en 30 secondes

Site de documentation **KwikTalk** sur **Docus** (Nuxt 4 + `@nuxt/content`),
bilingue **fr/en**, déployé sur **Dokploy** derrière Traefik.

| | |
|---|---|
| Repo | `github.com/STIFLEUR390/kwiktalk-docs` (branche `main`) |
| Live | https://kwiktalk-docs.applix.fr |
| Image Docker | `devmaster2023/kwiktalk-docs:vN` (Docker Hub) |
| App Dokploy | `S9Oi1xObtJOt8Azg4oYwW` |
| Projet Dokploy | `2NYRN0nkgXcIakWCAW9l5` (« new-kwiktalk ») |
| Environnement | `PICAZ14vMSAEiN5OaIQmy` (production) |
| Conteneur | `newkwiktalk-docs-b7euo7`, port 3000 |

## La règle qui domine tout le reste

> **Ne jamais builder sur le VPS.** Le prerender Nuxt/Docus demande ~2 Go de RAM, le
> VPS swappe, et le build reste `running` **indéfiniment sans jamais échouer**. Ce
> n'est pas une erreur visible : c'est un hang silencieux. Build en local, push sur
> Docker Hub, Dokploy pull.

Tout le reste du fichier est secondaire face à cette règle.

## Fichiers

| Fichier | Quand le charger |
|---|---|
| [`architecture.md`](architecture.md) | Comprendre la stack, le build, le routing |
| [`commands.md`](commands.md) | Besoin d'une commande concrète |
| [`errors.md`](errors.md) | **Une erreur s'affiche** — chercher la solution ici avant d'improviser |
| [`gotchas.md`](gotchas.md) | Avant de toucher au déploiement, Docker ou Dokploy |
| [`tests.md`](tests.md) | Vérifier qu'un changement casse rien |
| [`workflows.md`](workflows.md) | **Déployer** une modification |

## Pièges déjà payés (résumé)

1. **Build Dokploy qui pend 1h** → RAM insuffisante, pas un bug. Voir `errors.md`.
2. **`:latest` Docker Hub périmé** → une image Next.js d'un ancien projet traîne et
   sert un contenu faux. Toujours tagger en `vN`.
3. **Push Docker Hub coupé** → upload long d'une seule couche. Couches scindées
   dans le `Dockerfile`.
4. **`memoryLimit: "3gb"` rejeté** par Dokploy → laisser `null`.
5. **`seo.description` avec ` : ` non quoté** → prerender en 500, page absente du
   build. Voir `errors.md` §8.
6. **Cache `node_modules/.cache` périmé** → `no such table: _content_docs_en`,
   toute la locale EN en 404. Voir `errors.md` §9.
7. **Google Fonts injoignable depuis Node** → simple warning, les images OG
   fonctionnent. Ne pas désactiver `ogImage`. Voir `errors.md` §10.
8. **Slugs différents entre FR et EN** → la bascule de langue renvoie 404 sur
   16 pages sur 21. Slugs identiques dans les deux locales. Voir `gotchas.md`.

## État de la documentation

Réécrite le 11/10/2026 à partir du **code réel** (`kwiktalk-inertiajs`), en bilingue,
et **déployée en production** (image `v10`).

- **42 pages** : 21 FR + 21 EN, réparties en 5 sections.
- **Portée** : pages publiques + rôle `user` — jamais l'administration.
- **Images** : générées avec `codesnap` (`--disable-watermark`), dans `public/images/`.
- **Sections (identiques dans les deux locales, slugs anglais)** :
  `1.overview`, `2.features`, `3.integrations`, `4.account`, `5.resources` —
  indispensable au sélecteur de langue. Seuls les `title:` / `.navigation.yml`
  diffèrent (« Pour démarrer », « Fonctionnalités »…).
- Branding : logo « KwikTalk », suffixe de titre « KwikTalk Docs ».

### Procédure de mise à jour

Voir [`workflows.md`](workflows.md). En résumé :

```bash
npm run build
docker build --pull=false --provenance=false --sbom=false -t devmaster2023/kwiktalk-docs:vN -f Dockerfile .
docker push devmaster2023/kwiktalk-docs:vN
# puis Dokploy : saveDockerProvider + deploy, et vérifier le digest du conteneur
```

**Toujours vérifier après un build** (cf. `tests.md`) :

```bash
grep -cE '\[500\]|\[404\]' build.log   # doit être 0
find .output/public -name '*.html' | wc -l  # doit être 42
grep -rnE "^ +[a-z_]+: [^\"].*: " content/   # doit être vide (YAML valide)
```

## Ce qui reste à faire

- `better-sqlite3` est présent **et ne doit pas être supprimé** : c'est un
  *peer dependency obligatoire* de Docus (`12.x`, non optionnel) utilisé par la
  base SQLite de contenu **au build**. Il n'est pas dans `.output/` (inutile au
  runtime), donc retirer `@nuxt/content` du `package.json` casserait le build.
- **Images OG servies** sur les 42 pages — a nécessité `nitro.prerender
  .autoSubfolderIndex: true` (sans quoi Nitro ne trouvait pas le fichier et
  retombait en SSR). Voir [`gotchas.md`](gotchas.md) section « Prerender ».
- Non documentés (à voir si besoin) : `/ressources/blog`, `/confidentialite`,
  `/cgu` et `/contact` — légaux ou marketing, pas des fonctionnalités.
