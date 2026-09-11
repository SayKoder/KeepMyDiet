# Backend — KeepMyDiet

Symfony 7 + API Platform + Doctrine (PostgreSQL).

## Domaines (`src/Domain/`)
- `Group` — groupes, adhésions, invitations (Carl)
- `Fridge` — frigo + placard, DLC (Carl)
- `Recipe` — recettes, ingrédients, formulaire d'ajout (Rémi)
- `Nutrition` — profils, calcul TDEE/déficit (Rémi)
- `ShoppingList` — liste de courses, croise Fridge et Recipe (Carl & Rémi)

`src/Shared/` : `User`, auth JWT, classes de base communes (socle commun).

À initialiser : Symfony + API Platform + Doctrine + `docker-compose.yml` (Postgres).
