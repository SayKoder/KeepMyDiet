<?php

namespace App\Domain\Nutrition\Dto;

/**
 * Entrée de `POST /water_intakes/add`. Toujours un delta ("+250", ou négatif
 * pour annuler un ajout), jamais le total absolu — voir WaterIntake.
 *
 * `date` optionnelle (format YYYY-MM-DD, défaut aujourd'hui) : permet de
 * corriger l'hydratation d'un jour passé depuis l'écran de navigation jour
 * par jour, pas seulement d'ajouter au jour courant.
 */
final class AddWaterIntakeInput
{
    public int $deltaMl = 0;
    public ?string $date = null;
}
