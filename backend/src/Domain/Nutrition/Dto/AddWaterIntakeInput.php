<?php

namespace App\Domain\Nutrition\Dto;

/**
 * Entrée de `POST /water_intakes/add`. Toujours un delta ("+250", ou négatif
 * pour annuler un ajout), jamais le total absolu — voir WaterIntake.
 */
final class AddWaterIntakeInput
{
    public int $deltaMl = 0;
}
