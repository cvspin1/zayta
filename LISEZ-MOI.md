# Site Zayta Cosmétique (paiement à la livraison)

1. **Supabase** : crée un projet gratuit sur supabase.com. SQL Editor > colle `setup.sql` > Run.
2. **Admin** : Authentication > Users > Add user (ton email + mot de passe). Puis Authentication > Sign In / Providers > désactive "Allow new users to sign up" (important : sinon n'importe qui peut devenir admin).
3. **Clés** : Project Settings > API. Copie `Project URL` et `anon public key` dans `config.js`.
4. **GitHub Pages** : crée un repo, envoie tous les fichiers, puis Settings > Pages > Deploy from branch > main / root.
5. **Dashboard** : `https://TON-NOM.github.io/TON-REPO/admin.html`. Ajoute les photos des produits dans l'onglet Produits.

La `anon key` peut rester publique dans le code : la sécurité vient des règles (RLS) de `setup.sql`. Ne mets jamais la `service_role key` dans le site.
