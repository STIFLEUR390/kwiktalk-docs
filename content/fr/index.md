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

#links
  :::u-button
  ---
  color: neutral
  size: xl
  to: /fr/overview/first-steps
  trailing-icon: i-lucide-arrow-right
  ---
  Premiers pas
  :::

  :::u-button
  ---
  color: neutral
  icon: i-lucide-credit-card
  size: xl
  to: /fr/overview/pricing
  variant: outline
  ---
  Tarifs
  :::
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
| Comprendre l'offre | [Présentation](/fr/overview/overview) |
| Créer un compte | [Créer un compte](/fr/overview/create-account) |
| Connecter WhatsApp | [Premiers pas](/fr/overview/first-steps) |
| Choisir un plan | [Tarifs](/fr/overview/pricing) |

## Les fonctionnalités principales

- **[Instances WhatsApp](/fr/features/whatsapp-instances)** — connectez un ou plusieurs numéros via QR code, surveillez leur état.
- **[Contacts et groupes](/fr/features/contacts-groups)** — importez un fichier Excel, validez les numéros, organisez-les en groupes.
- **[Modèles de messages](/fr/features/message-templates)** — réutilisez des messages avec variables dynamiques.
- **[Campagnes](/fr/features/messages-campaigns)** — envoyez en différé ou en lot, avec planification et protections anti-ban.
- **[Messages entrants](/fr/features/incoming-messages)** — centralisez les réponses de vos destinataires.
- **[Chatbot](/fr/features/chatbot)** — automatisez les réponses par règles ou par workflow.

## Pour les développeurs

- **[Applications API](/fr/integrations/api-applications)** — créez une clé, apparez-la à une instance, envoiez par `POST /api/v1/messages/send`.
- **[Webhooks](/fr/integrations/webhooks)** — recevez `message.received`, `message.status.updated`, `instance.connected`… avec signature HMAC-SHA256.

## Aide et confiance

- **[Formatteur WhatsApp](/fr/resources/whatsapp-formatter)** — outil gratuit pour rédiger et copier un message au format WhatsApp.
- **[Anti-spam et anti-ban](/fr/resources/anti-spam)** — les trois modes de protection et les bonnes pratiques d'envoi.
- **[FAQ](/fr/resources/faq)** — validation des numéros, sécurité, multi-numéros, essai gratuit.
- **[Sécurité](/fr/resources/security)** — chiffrement, clés API, contrôle des accès, bonnes pratiques.
- **[Statut de la plateforme](/fr/resources/status)** — disponibilité en temps réel et maintenances.
