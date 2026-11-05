# shared/

Code réutilisé par **plusieurs** features.

- `api_client.dart`, `token_storage.dart` — client HTTP et stockage du JWT.
- `home_navigation.dart` — onglet actif de la barre de navigation.
- `date_labels.dart`, `responsive.dart` — petits utilitaires.
- `widgets/` — widgets d'interface communs (cartes, pastilles, bannières, champs…).

Les widgets propres à un seul écran restent dans
`features/<feature>/presentation/widgets/`.
