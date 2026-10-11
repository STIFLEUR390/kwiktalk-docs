# Erreurs connues

Chaque entrée : **le symptôme tel qu'il apparaît**, puis **la cause réelle**, puis
**la solution**. Appliquer la solution avant d'improviser.

---

## 1. Le build Dokploy reste `running` pendant des heures

**Symptôme** — `applicationStatus: "running"` sans fin. Les logs s'arrêtent sur :

```
● Prerendering routes (2m 03s · 2m 37s)
● Prerendering routes (1m 58s · 2m 32s)
```

…et ne bougent plus. Jamais en `error`. Peut durer 1h+.

**Cause** — **Pas une erreur : un manque de RAM.** Le prerender Nuxt/Docus demande
~2 Go. Le VPS swappe, le process Node ralentit à mort mais ne crash jamais, donc
Dokploy affiche `running` indéfiniment. Vérifiable : le même build en local finit en
1-2 min.

**Ne pas faire** :
- Ne pas « attendre plus longtemps » — ça ne finira pas.
- Ne pas désactiver le SSR : le coût est au **build** (1232 modules compilés +
  prerender), pas au runtime.
- Ne pas augmenter `memoryLimit` (cf. erreur 3, le format est rejeté).

**Solution** — Ne pas builder sur le VPS. Build local + image Docker poussée sur
Docker Hub. Voir [`workflows.md`](workflows.md).

---

## 2. Le site répond mais sert un contenu faux / ancien

**Symptôme** — Le déploiement est `done`, le conteneur est `healthy`, mais les
pages montrent un autre site. Ex : titre « KwikTalk Docs » au lieu du titre Docus
attendu.

**Cause** — Le tag `:latest` sur Docker Hub traîne depuis un ancien projet (une
image **Next.js** : `Cmd: node server.js`, `User: nextjs`). Le push réel n'avait
jamais terminé, donc `:latest` pointe toujours vers l'ancienne image.

**Diagnostic** — Comparer ce qui tourne vs ce qu'on croit déployer :

```bash
# dans Dokploy MCP : docker.getConfig sur le conteneur → regarder .Config.Cmd / .Config.User
# attendu : [node .output/server/index.mjs]  — suspect : [node server.js]
docker inspect devmaster2023/kwiktalk-docs:vN --format '{{.Config.Cmd}}'
docker inspect devmaster2023/kwiktalk-docs:vN --format '{{.Id}}'   # comparer au digest poussé
```

**Solution** — Taguer en `vN` incrémental et pointer Dokploy sur ce tag précis.
**Ne jamais utiliser `:latest`.**

---

## 3. `invalid memory value 3: Must be at least 4MiB`

**Symptôme** — Le déploiement échoue en < 2 s :

```
(HTTP code 400) unexpected - rpc error: code = InvalidArgument desc =
invalid memory value 3: Must be at least 4MiB
```

Même message avec `"3072m"` (`invalid memory value 3072`).

**Cause** — Dokploy parse mal le `memoryLimit` : il tranche l'unité et ne garde que
la valeur numérique, que Docker interprète en **octets**.

**Solution** — Laisser `memoryLimit` et `memoryReservation` à **`null`** via
`application.update`. Ne pas tenter de format alternatif.

---

## 4. Push Docker Hub coupé en plein transfert

**Symptôme** — `docker push` échoue :

```
failed to copy: failed to do request: Put "https://registry-1.docker.io/v2/...":
write tcp 192.168.x.x:xxxxx->44.195.142.59:443: use of closed network connection
```

Échoue toujours sur la **plus grosse couche**, après ~30-60 s de transfert
continu. Réessayer 12 fois de suite ne change rien : c'est systématique.

**Cause** — Instabilité du réseau vers `registry-1.docker.io` sur les uploads longs.
Ce n'est ni la taille totale (80 Mo gzip) ni le rate limit.

**Diagnostic** — Voir quelle couche est énorme :

```bash
docker history devmaster2023/kwiktalk-docs:vN --human --format "{{.Size}}\t{{.CreatedBy}}" | grep -i copy
```

**Solution** — Scinder `.output` en **couches de < 20 Mo** dans le `Dockerfile`,
sans recouvrement entre elles. Chaque upload devient court et passe. Le push passe
alors **du premier coup**.

Attention, deux pièges de scindage :
- Un `COPY` de `server/` après `node_modules/` **recopie** les fichiers en delta →
  duplication. Copier les fichiers un par un, jamais le dossier parent.
- `COPY --exclude=@img` : les patterns sont **relatifs au dossier source**, pas au
  chemin complet.

---

## 5. `/fr/getting-started/` renvoie 404

**Symptôme** — La page racine d'une section donne 404, alors que ses sous-pages
marchent (`/fr/getting-started/introduction` → 200).

**Cause** — Pas d'`index.md` dans le dossier. Docus ne prérend que les pages
**existantes en Markdown**. Ce n'est pas un bug serveur ni de routing.

**Solution** — Ajouter `content/fr/1.getting-started/index.md` (et son équivalent
`en/`) si on veut que l'URL racine existe. Sinon, s'assurer que la sidebar ne lie
jamais cette URL.

---

## 6. Le build local Docker est anormalement lent (> 5 min)

**Symptôme** — `docker build` reste bloqué sur :

```
#5 [internal] load metadata for docker.io/library/node:22-alpine
#5 ...
```

**Cause** — BuildKit va vérifier les métadonnées auprès de Docker Hub, et cette
requête bloque (même instabilité réseau que l'erreur 4).

**Solution** — Passer `--pull=false`. L'image `node:22-alpine` est déjà en cache
local.

---

## 7. Le site met 13 s à répondre au premier appel

**Symptôme** — Le premier `curl` après un redémarrage du conteneur est lent
(~13 s), les suivants sont normaux.

**Cause** — Cold start : le serveur Node compile à la volée le premier render
SSR. Le `node-server` Nitro n'est pas pré-warmé.

**Solution** — Aucune, c'est normal et non bloquant. Seuls les appels suivants
comptent pour la mesure (0,5-2 s).
