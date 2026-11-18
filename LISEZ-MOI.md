# Site Zayta Cosmétique (paiement à la livraison)

## Tu as déjà un site en ligne (mise à jour)
1. **Supabase** > SQL Editor > New query > colle tout `update.sql` > Run. (Ça ajoute les statistiques, les commandes en direct, le Pack Duo et les photos séparées.)
2. **GitHub** : remplace tous les fichiers du repo par ceux-ci, **y compris le dossier `assets/`** (3 photos : `duo.jpg`, `oil.jpg`, `butter.jpg`). Attends 1 à 2 minutes que GitHub Pages se mette à jour.
3. **Dashboard** > Produits : change le prix du Pack Duo (200 MAD par défaut).

## Nouveau projet (première installation)
1. **Supabase** : crée un projet gratuit. SQL Editor > colle `setup.sql` > Run.
2. **Admin** : Authentication > Users > Add user (ton email + mot de passe). Puis Authentication > Sign In / Providers > désactive "Allow new users to sign up" (important).
3. **Clés** : Project Settings > API. Copie `Project URL` et la clé publique dans `config.js`.
4. **GitHub Pages** : envoie tous les fichiers (avec `assets/`), puis Settings > Pages > Deploy from branch > main / root.
5. **Dashboard** : `https://TON-NOM.github.io/TON-REPO/admin.html`

La clé publique peut rester dans le code : la sécurité vient des règles (RLS) du SQL. Ne mets jamais la `service_role key` dans le site.

## WhatsApp
Le numéro est dans `config.js` (`wa: "212704854700"`), au format international sans le +.
