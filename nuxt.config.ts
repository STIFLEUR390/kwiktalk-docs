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

  // Nom affiché dans le suffixe des <title> et en alternative du logo
  site: {
    name: 'KwikTalk Docs',
  },

  // Note : le build tente de joindre fonts.google.com depuis Node (injoignable
  // depuis ce réseau — `curl` passe, `fetch` Node timeout). unifont le signale
  // en warning mais bascule sur des polices de repli : la génération des images
  // OG reste fonctionnelle. Ne pas désactiver ogImage pour autant.
})
