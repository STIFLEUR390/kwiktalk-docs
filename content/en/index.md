---
seo:
  title: Documentation
  description: "Learn how to use KwikTalk: WhatsApp instances, contacts, message templates, campaigns, chatbot, API and webhooks."
---

::u-page-hero
#title
KwikTalk documentation
#description
Everything you need to connect your number, import your contacts and send your first WhatsApp campaigns.

#links
  :::u-button
  ---
  color: neutral
  size: xl
  to: /en/overview/first-steps
  trailing-icon: i-lucide-arrow-right
  ---
  First steps
  :::

  :::u-button
  ---
  color: neutral
  icon: i-lucide-credit-card
  size: xl
  to: /en/overview/pricing
  variant: outline
  ---
  Pricing
  :::
::

::u-container{class="py-10"}

## Who is this documentation for?

This documentation covers **two scopes**:

- **Public features** — available without an account: product overview, pricing, free tools, legal pages and status.
- **`user` role features** — the full workspace of a regular account: WhatsApp instances, contacts, templates, messages, campaigns, incoming messages, chatbot, API and webhooks.

:::u-alert{color="info" icon="i-lucide-info"}
Platform administration (users, roles, plans, internal billing, global settings) is **not** documented here — those functions belong to the `admin` and `super-admin` roles.
:::

## Where to start

| Step | Page |
|---|---|
| Understand the offer | [Overview](/en/overview/overview) |
| Create an account | [Create an account](/en/overview/create-account) |
| Connect WhatsApp | [First steps](/en/overview/first-steps) |
| Pick a plan | [Pricing](/en/overview/pricing) |

## Main features

- **[WhatsApp instances](/en/features/whatsapp-instances)** — connect one or more numbers via QR code, monitor their state.
- **[Contacts and groups](/en/features/contacts-groups)** — import an Excel file, validate numbers, organise them into groups.
- **[Message templates](/en/features/message-templates)** — reuse messages with dynamic variables.
- **[Campaigns](/en/features/messages-campaigns)** — send in bulk or on a schedule, with anti-ban protection.
- **[Incoming messages](/en/features/incoming-messages)** — collect your recipients' replies.
- **[Chatbot](/en/features/chatbot)** — automate replies with rules or workflows.

## For developers

- **[API applications](/en/integrations/api-applications)** — create a key, bind it to an instance, call `POST /api/v1/messages/send`.
- **[Webhooks](/en/integrations/webhooks)** — receive `message.received`, `message.status.updated`, `instance.connected`… with HMAC-SHA256 signatures.

## Help and trust

- **[WhatsApp formatter](/en/resources/whatsapp-formatter)** — free tool to write and copy a message in WhatsApp format.
- **[Anti-spam and anti-ban](/en/resources/anti-spam)** — the three protection modes and healthy sending practices.
- **[FAQ](/en/resources/faq)** — number validation, security, multiple numbers, free trial.
- **[Security](/en/resources/security)** — encryption, API keys, access control, best practices.
- **[Platform status](/en/resources/status)** — real-time availability and maintenance.

::
