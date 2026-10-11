---
seo:
  title: Documentation
  description: "Apprenez à utiliser KwikTalk : instances WhatsApp, contacts, modèles de messages, campagnes, chatbot, API et webhooks."
---

::u-page-hero
#title
Documentation KwikTalk
#description
Tout ce qu'il faut pour connecter votre numéro, importer vos contacts et envoyer vos premières campagnes WhatsApp.
::

## Pour qui est cette documentation ?

Cette documentation couvre **deux périmètres** :

- **Les fonctionnalités publiques** — accessibles sans compte : présentation du produit, tarifs, outils gratuits, pages légales et statut.
- **Les fonctionnalités du rôle `user`** — l'espace de travail complet d'un compte utilisateur : instances WhatsApp, contacts, modèles, messages, campagnes, messages entrants, chatbot, API et webhooks.

::note{type="info"}
L'administration de la plateforme (utilisateurs, rôles, plans, facturation interne, paramètres globaux) n'est pas documentée ici : ces fonctions relèvent des rôles `admin` et `super-admin`.
::

## Par où commencer

| Étape | Page |
|---|---|
| Comprendre l'offre | [Présentation](/fr/pour-demarrer/presentation) |
| Créer un compte | [Créer un compte](/fr/pour-demarrer/creer-un-compte) |
| Connecter WhatsApp | [Premiers pas](/fr/pour-demarrer/premiers-pas) |
| Choisir un plan | [Tarifs](/fr/pour-demarrer/tarifs) |

## Les fonctionnalités principales

- **[Instances WhatsApp](/fr/fonctionnalites/instances-whatsapp)** — connectez un ou plusieurs numéros via QR code, surveillez leur état.
- **[Contacts et groupes](/fr/fonctionnalites/contacts-et-groupes)** — importez un fichier Excel, validez les numéros, organisez-les en groupes.
- **[Modèles de messages](/fr/fonctionnalites/modeles-de-messages)** — réutilisez des messages avec variables dynamiques.
- **[Campagnes](/fr/fonctionnalites/messages-et-campagnes)** — envoyez en différé ou en lot, avec planification et protections anti-ban.
- **[Messages entrants](/fr/fonctionnalites/messages-entrants)** — centralisez les réponses de vos destinataires.
- **[Chatbot](/fr/fonctionnalites/chatbot)** — automatisez les réponses par règles ou par workflow.

## Pour les développeurs

- **[Applications API](/fr/integrations/applications-api)** — créez une clé, apparez-la à une instance, envoiez par `POST /api/v1/messages/send`.
- **[Webhooks](/fr/integrations/webhooks)** — recevez `message.received`, `message.status.updated`, `instance.connected`… avec signature HMAC-SHA256.
