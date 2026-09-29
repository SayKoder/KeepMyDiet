# Infra — KeepMyDiet

Déploiement production : Traefik + Docker Compose sur VPS.

## Contenu
- `docker-compose.prod.yml` — orchestre `app` (Symfony, build depuis `../backend/Dockerfile`), `nginx` (sert `public/` + proxy FastCGI vers `app`) et `database` (Postgres 16).
- `nginx/backend.conf` — vhost nginx classique pour un front controller Symfony (`public/index.php`).
- `.env.prod.dist` — modèle des variables requises. À copier en `.env.prod` **sur le VPS uniquement**, jamais commité (voir `.gitignore` racine).

## Secrets
Aucun secret réel dans le repo :
- `APP_SECRET`, `POSTGRES_PASSWORD`, `JWT_PASSPHRASE` viennent de `infra/.env.prod` (gitignored), lu par `docker compose --env-file`.
- Les clés JWT (`private.pem`/`public.pem`) sont générées une fois sur le VPS directement dans le volume nommé `jwt_keys` (jamais commitées, jamais buildées dans l'image) :
  ```
  docker compose -f docker-compose.prod.yml run --rm app \
    sh -c "openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -aes256 -pass pass:\$JWT_PASSPHRASE -out config/jwt/private.pem && \
           openssl pkey -in config/jwt/private.pem -passin pass:\$JWT_PASSPHRASE -pubout -out config/jwt/public.pem"
  ```

## Déploiement (résumé)
```
cp .env.prod.dist .env.prod   # puis renseigner les vraies valeurs sur le VPS
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

## À faire à l'étape 18 du plan (déploiement VPS réel)
- Brancher le service `nginx` sur le réseau Traefik existant du VPS (`networks.web.external: true` déjà en place, nom de réseau à vérifier).
- Remplacer le `Host()` placeholder (`api.TODO-domaine.tld`) et le `certresolver` dans les labels Traefik de `docker-compose.prod.yml` par les vraies valeurs.
- Générer les clés JWT de prod (voir ci-dessus) et renseigner `infra/.env.prod`.
