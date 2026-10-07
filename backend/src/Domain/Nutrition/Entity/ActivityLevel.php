<?php

namespace App\Domain\Nutrition\Entity;

/**
 * Multiplicateur appliqué au métabolisme de base (BMR) pour obtenir la
 * dépense calorique totale journalière (TDEE) — échelle standard popularisée
 * par Harris-Benedict, couramment réutilisée avec Mifflin-St Jeor.
 */
enum ActivityLevel: string
{
    case Sedentary = 'sedentary';
    case Light = 'light';
    case Moderate = 'moderate';
    case Active = 'active';
    case VeryActive = 'very_active';

    public function multiplier(): float
    {
        return match ($this) {
            self::Sedentary => 1.2,
            self::Light => 1.375,
            self::Moderate => 1.55,
            self::Active => 1.725,
            self::VeryActive => 1.9,
        };
    }
}
