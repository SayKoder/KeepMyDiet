/// Entièrement facultatif : une recette peut n'avoir aucune étape. L'ordre
/// vient de l'ordre renvoyé par le backend (voir RecipeStep côté backend),
/// pas de champ d'ordre explicite ici.
class RecipeStep {
  const RecipeStep({required this.instruction, this.durationMinutes});

  final String instruction;
  final int? durationMinutes;

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
    instruction: json['instruction'] as String,
    durationMinutes: json['durationMinutes'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'instruction': instruction,
    'durationMinutes': durationMinutes,
  };
}
