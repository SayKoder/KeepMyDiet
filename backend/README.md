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

## Prod (VPS)
`Dockerfile` (PHP-FPM Alpine, multi-stage) construit une image prod optimisée (autoload figé, `.env` compilé via `composer dump-env prod`). Il est consommé par `../infra/docker-compose.prod.yml` (nginx + app + Postgres), pas utilisé en dev. Détails et gestion des secrets : voir `../infra/README.md`.
