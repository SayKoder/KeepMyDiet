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

## Lancer le projet
```
cd frontend
flutter analyze   # analyse statique
flutter test       # tests
flutter run        # sur un émulateur/téléphone connecté
```

`org` de l'app : `com.keepmydiet`. Plateformes générées : Android + iOS uniquement (pas de web/desktop pour l'instant, voir CLAUDE.md).
