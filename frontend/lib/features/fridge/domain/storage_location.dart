/// Miroir de `App\Domain\Fridge\Entity\StorageLocation`.
enum StorageLocation {
  fridge,
  pantry;

  factory StorageLocation.fromJson(String value) => StorageLocation.values.byName(value);

  String get label => switch (this) {
        StorageLocation.fridge => 'Frigo',
        StorageLocation.pantry => 'Placard',
      };
}
