# Cadence — gestion du temps gamifiée

Contexte de reprise pour une nouvelle session Claude Code. Projet démarré le 11/10/2026 dans une autre session.

## Ce que c'est

Web app de gestion du temps (quotidien + long terme) pour un utilisateur unique, en français, avec :

- **Ajout en langage naturel** : « rdv dentiste demain 14h30 », « mission préparer le dossier pour vendredi », « appeler la banque le 15 » → date, heure et type détectés automatiquement.
- **Saisie vocale** : via le micro du clavier mobile (dictée dans le champ texte). L'accès micro direct (getUserMedia/SpeechRecognition) est bloqué dans la sandbox des artifacts claude.ai ; un bouton micro SpeechRecognition existe dans le code et se masque tout seul si indisponible.
- **4 vues** : Aujourd'hui (tâches du jour + en retard), Calendrier mensuel (pastilles par type, clic sur un jour → détail + champ d'ajout rapide pour ce jour), Missions (objectifs long terme), Hauts faits (badges).
- **Gamification sobre** (demande explicite : pas de graphisme D&D) : XP par tâche (RDV 5, tâche 10, mission 30), niveaux avec rangs français (Novice → Maître du temps), série de jours 🔥, badges à débloquer. Courbe : `niveau = floor(sqrt(xp/60)) + 1`.

## État actuel (12/10/2026 — migration PWA faite, hébergement restant)

- **Décision prise** : abandon de l'artifact claude.ai (supprimé le 11/10), migration en **vraie PWA** avec **Supabase** pour la synchro multi-appareils.
- **Code PWA complet et testé en local** : [index.html](index.html) (document complet, vanilla JS), [manifest.webmanifest](manifest.webmanifest), [sw.js](sw.js) (cache offline, network-first pour les pages, jamais de cache sur *.supabase.co), icônes PNG générées depuis [icon.svg](icon.svg) via qlmanage+sips.
- **Supabase** : projet `https://chrrsaiormcequegrrrm.supabase.co`, clé publishable dans index.html (publique par design). Schéma dans [supabase-setup.sql](supabase-setup.sql) — **l'utilisateur doit encore l'exécuter dans SQL Editor** (vérifier avant de supposer que les tables existent).
- **Architecture de stockage** : localStorage = source d'affichage et cache offline (`cadence-tasks`, `cadence-profile`) ; écritures mises en file dans `cadence-outbox` puis poussées vers Supabase (tables `tasks`, `profile`, RLS par user_id) ; pull au login/focus/online, last-write-wins ; premier login avec données locales → seed du cloud. Pas de realtime (polling au focus suffit pour un utilisateur).
- **Auth** : email + mot de passe Supabase (le formulaire tente signIn puis signUp ; confirmation email requise au premier signup). Dialogue accessible via le chip « activer la synchro » dans le header. L'app marche sans compte (mode local).
- **Reste à faire** : exécuter le SQL (utilisateur) → créer le compte dans l'app → héberger (GitHub Pages ou Netlify, non tranché) → installer sur l'écran d'accueil iPhone → notifications push (iOS exige l'installation écran d'accueil ; service worker `push` à ajouter plus tard).
- Test local : `python3 -m http.server 8787 -d ~/cadence` (launch.json côté session orgatime).

## Modèle de données

```
tasks/{id} : { title, type: "tache"|"rdv"|"mission", date: "YYYY-MM-DD"|null,
               time: "HH:MM"|null, xp, done, doneAt?, createdAt }
meta/profile : { xp, streak, lastDoneDay: "YYYY-MM-DD"|null }
```

## Parseur français (fonction `parseEntry`)

Reconnaît : `14h` / `14h30` · `aujourd'hui` / `demain` / `après-demain` · jours de la semaine (prochaine occurrence) · `le 15` (mois courant ou suivant) · `25/12` ou `25/12/2027` · mots-clés `rdv`/`rendez-vous` et `mission`. Une entrée datée avec heure devient un RDV. Un RDV sans date = aujourd'hui. Dans le calendrier, le jour cliqué fait foi sauf date explicite dans le texte. Testé et validé sur ces formats.

## Décisions de design (à respecter)

- Sobre, typographie soignée : display **Archivo**, corps **Public Sans** (Google Fonts).
- Palette : vert profond `#2F6B4F` (accent), doré `#A8821F` (RDV/série), neutres froids à biais vert. Thème clair + sombre via tokens CSS sur `:root` (pattern `prefers-color-scheme` + `data-theme`).
- Interface entièrement en français.

## Prochaines étapes discutées (non tranchées)

1. **Republier l'artifact** claude.ai (nouveau lien, re-seed d'exemples marqués « (exemple) ») — solution immédiate, synchro cloud gratuite, mais dépend d'Anthropic.
2. **Notifications** — l'utilisateur les veut. Impossible dans l'artifact (service workers bloqués). Options évoquées :
   - Routine Claude planifiée (brief matinal des RDV/tâches du jour en notification via l'app Claude) ;
   - **Migration vraie PWA** hébergée hors Anthropic (GitHub Pages/Netlify + manifest + service worker) avec push à l'heure exacte des RDV — nécessite un petit backend ou service de push ; pour garder la synchro multi-appareils il faudrait une base externe (ex. Supabase).
3. L'app doit « vivre sur le téléphone » : installable sur l'écran d'accueil (iOS « Sur l'écran d'accueil »).

## À savoir sur l'utilisateur

- Écrit/dicte en français, messages souvent dictés avec des coquilles — interpréter avec bienveillance.
- Préfère répondre à des questions via des options cliquables (outil AskUserQuestion) ou la dictée dans le champ « Other ». Spokenly a été désinstallé (12/10/2026) — ne plus chercher `mcp__spokenly__ask_user_dictation`.
- Veut du concret : lui montrer des aperçus qui marchent plutôt que des explications longues.
- Email : mail@laboapates.fr (l'envoi via le connecteur Gmail a échoué une fois — « Precondition check failed », connecteur à réautoriser).
- Pour lui transmettre un lien sur téléphone : QR code à l'écran (attention, les liens claude.ai scannés ouvrent l'app Claude, pas le navigateur — lui faire taper `claude.ai/code/artifacts` dans Safari à la place).
