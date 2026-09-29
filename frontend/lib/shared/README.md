# shared/

Widgets, extensions et utilitaires réutilisés par **plusieurs** features (pas transverses à toute l'app comme `core/`, mais pas propres à un seul domaine non plus) :
- `api_client.dart` (à créer) — client HTTP (dio/http) partagé, avec gestion du token JWT.
- Widgets communs (cards, boutons, etc.) au fur et à mesure des besoins réels — ne pas créer d'abstraction avant d'en avoir un second usage concret.
