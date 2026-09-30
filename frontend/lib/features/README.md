# features/

Un dossier par domaine métier (même découpage que `backend/src/Domain/` côté Symfony), chacun avec 3 sous-dossiers :

- `data/` — accès à l'API (requêtes HTTP, DTO/modèles de sérialisation JSON, repository qui les expose).
- `domain/` — logique métier pure de la feature (entités, règles), idéalement sans dépendance à Flutter.
- `presentation/` — écrans et widgets Flutter de la feature, + gestion d'état locale (Riverpod/Bloc — à trancher, voir "Décisions ouvertes" dans CLAUDE.md).

Répartition (voir CLAUDE.md) :
- `auth/` — socle commun (Carl & Rémi)
- `groups/`, `fridge/` — Carl
- `recipes/`, `nutrition/` — Rémi
- `shopping_list/` — Carl & Rémi

Dossiers actuellement vides (juste squelette) — le code arrive feature par feature, pas avant d'en avoir besoin.
