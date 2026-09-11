# Frontend — KeepMyDiet

App Flutter/Dart mobile (Android/iOS), structure feature-first.

## Structure (`lib/`)
- `core/` — thème, router, config env
- `shared/` — widgets communs, extensions, `api_client.dart`
- `features/auth/` — login/register, stockage sécurisé du token (socle commun)
- `features/groups/` — groupes, invitations (Carl)
- `features/fridge/` — frigo + placard, scan code-barres (Carl)
- `features/recipes/` — recettes, formulaire d'ajout (Rémi)
- `features/nutrition/` — dashboard nutrition (Rémi)
- `features/shopping_list/` — liste de courses (Carl & Rémi)

À initialiser : `flutter create` puis mise en place de la structure ci-dessus.
