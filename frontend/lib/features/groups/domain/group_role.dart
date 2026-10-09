/// Miroir de `App\Domain\Group\Entity\GroupRole` côté backend. Les valeurs de
/// l'enum (`member`, `admin`) correspondent exactement aux chaînes JSON
/// renvoyées par l'API — `.byName()` fait le mapping sans code à écrire.
enum GroupRole {
  member,
  admin;

  factory GroupRole.fromJson(String value) => GroupRole.values.byName(value);

  String get label => switch (this) {
    GroupRole.admin => 'Admin',
    GroupRole.member => 'Membre',
  };
}
