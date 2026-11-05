// Validation partagée entre le formulaire de profil et le parcours guidé.

double? parsePositive(String text) {
  final value = double.tryParse(text.trim());
  return value != null && value > 0 ? value : null;
}

String? validateBasics({
  required DateTime? birthDate,
  required String height,
  required String weight,
}) {
  if (birthDate == null) return 'Choisis ta date de naissance.';
  if (parsePositive(height) == null || parsePositive(weight) == null) {
    return 'Taille et poids doivent être des nombres positifs.';
  }
  return null;
}

String? validateTargetWeight(String text) {
  if (text.trim().isEmpty || parsePositive(text) != null) return null;
  return 'Le poids visé doit être un nombre positif.';
}
