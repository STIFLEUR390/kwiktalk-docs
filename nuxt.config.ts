export default defineNuxtConfig({
  extends: ['docus'],
  modules: ['@nuxtjs/i18n'],

  i18n: {
    defaultLocale: 'en',
    locales: [{
      code: 'en',
      name: 'English',
    }, {
      code: 'fr',
      name: 'Français',
    }],
  },

  // Nom affiché dans le suffixe des <title> et en alternative du logo.
  // `url` est obligatoire pour le prerender statique : sans elle, le module
  // sitemap throw au build ("You must provide a site URL to prerender a sitemap").
  site: {
    name: 'KwikTalk Docs',
    url: 'https://kwiktalk-docs.applix.fr',
  },

  // Note : le build tente de joindre fonts.google.com depuis Node (injoignable
  // depuis ce réseau — `curl` passe, `fetch` Node timeout). unifont le signale
  // en warning mais bascule sur des polices de repli : la génération des images
  // OG reste fonctionnelle. Ne pas désactiver ogImage pour autant.
  nitro: {
    prerender: {
      // Par défaut à false ici : /fr → fr.html, or Nitro ne résout pas `/fr` vers
      // `fr.html` mais cherche `fr/index.html`. Conséquence : la route tombait en
      // SSR et perdait les balises `og:image` générées au build. Avec `true`,
      // chaque route produit `x/index.html` et le handler statique la sert.
      autoSubfolderIndex: true,
    },
  },
})
