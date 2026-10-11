export default defineNuxtConfig({
  extends: ['docus'],
  modules: ['@nuxtjs/i18n'],

  // Nom affiché dans le suffixe des <title> et en alternative du logo
  site: {
    name: 'KwikTalk Docs',
  },

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

  // Les images OG ont besoin des polices Google, injoignables depuis Node dans
  // cet environnement (curl passe, fetch Node timeout) : Satori échoue et le
  // prerender des pages échoue avec lui. À réactiver si le réseau le permet.
  ogImage: { enabled: false },
})
