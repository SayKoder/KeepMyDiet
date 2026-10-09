<?php

namespace App\Domain\Nutrition\Dto;

/**
 * Entrée de `POST /daily_nutrition_logs/add`. Toujours des deltas (potentiellement
 * négatifs pour corriger une saisie), jamais des totaux absolus — voir
 * DailyNutritionLog et AddWaterIntakeInput pour le même principe.
 *
 * `date` optionnelle (format YYYY-MM-DD, défaut aujourd'hui) : permet de
 * corriger un jour passé depuis l'écran de navigation jour par jour, pas
 * seulement d'ajouter au jour courant.
 */
final class AddDailyNutritionLogInput
{
    public int $deltaKcal = 0;
    public float $deltaProteinG = 0;
    public float $deltaCarbG = 0;
    public float $deltaFatG = 0;
    public ?string $date = null;
}
