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
5. **`/fr/getting-started/` → 404** → pas d'`index.md` dans le dossier, normal.

## Ce qui reste à faire

- Le titre affiché porte encore le suffixe du template Docus
  (« … - kwiktalk-docs ») au lieu de « KwikTalk Docs ».
- `content/fr/` et `content/en/` sont désynchronisés : le template Docus par défaut
  contient des pages de démo (studio, migration, troubleshooting) sans lien avec
  KwikTalk.
- `better-sqlite3` est en dépendance mais **jamais utilisé au runtime** (Docus
  charge `@sqlite.org/sqlite-wasm`). Candidat à la suppression.
