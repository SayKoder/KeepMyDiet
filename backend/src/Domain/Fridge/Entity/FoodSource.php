<?php

namespace App\Domain\Fridge\Entity;

/**
 * Ciqual = seed global partagé par tout le monde (jamais créé depuis l'app).
 * Custom = produit personnalisé créé quand un code-barres scanné n'est pas
 * trouvé sur Open Food Facts, propre à un groupe (voir CLAUDE.md, "APIs
 * externes utilisées").
 */
enum FoodSource: string
{
    case Ciqual = 'ciqual';
    case Custom = 'custom';
}
