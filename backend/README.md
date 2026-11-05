# Backend — KeepMyDiet

Symfony 7 + API Platform + Doctrine (PostgreSQL).

## Domaines (`src/Domain/`)
- `Group` — groupes, adhésions, invitations (Carl)
- `Fridge` — frigo + placard, DLC (Carl)
- `Recipe` — recettes, ingrédients, formulaire d'ajout (Rémi)
- `Nutrition` — profils, calcul TDEE/déficit (Rémi)
- `ShoppingList` — liste de courses, croise Fridge et Recipe (Carl & Rémi)

`src/Shared/` : `User`, auth JWT, classes de base communes (socle commun).

## Dev local
`compose.yaml` démarre uniquement Postgres (port 5432 exposé via `compose.override.yaml`). L'app tourne en dehors de Docker (`symfony serve` ou `php -S`) — pas de conteneur PHP en dev, pour rester rapide à itérer.

### Temps réel (Mercure)
`compose.yaml` démarre aussi le hub Mercure (`docker compose up -d mercure`, exposé sur le port 3000). Après une modification de la liste de courses ou du frigo, `GroupChangePublisher` publie un événement sans donnée sur le sujet privé `/groups/{id}` ; l'app native se connecte via `GET /api/groups/{id}/realtime` (jeton d'abonné réservé aux membres du groupe) et recharge ses données.

Le `.env` local (non versionné) doit définir `MERCURE_URL` et `MERCURE_PUBLIC_URL` (`http://127.0.0.1:3000/.well-known/mercure`), `MERCURE_JWT_SECRET` et `MERCURE_JWT_ISSUER`. Sur téléphone : `adb reverse tcp:3000 tcp:3000` en plus du port 8000. Si le hub est arrêté, l'API continue de fonctionner (la publication est simplement ignorée).

## Prod (VPS)
`Dockerfile` (PHP-FPM Alpine, multi-stage) construit une image prod optimisée (autoload figé, `.env` compilé via `composer dump-env prod`). Il est consommé par `../infra/docker-compose.prod.yml` (nginx + app + Postgres), pas utilisé en dev. Détails et gestion des secrets : voir `../infra/README.md`.
