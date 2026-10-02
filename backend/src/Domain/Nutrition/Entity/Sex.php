<?php

namespace App\Domain\Nutrition\Entity;

/**
 * Paramètre physiologique requis par la formule de Mifflin-St Jeor (le terme
 * constant final diffère selon le sexe biologique) — pas un champ d'identité
 * de genre plus large.
 */
enum Sex: string
{
    case Male = 'male';
    case Female = 'female';
}
