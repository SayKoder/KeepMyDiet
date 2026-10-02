<?php

namespace App\Domain\Fridge\Entity;

/**
 * Le placard couvre les produits secs/conserves à durée de vie longue, le
 * frigo les produits frais à rotation rapide (voir CLAUDE.md, section
 * "Frigo et placard").
 */
enum StorageLocation: string
{
    case Fridge = 'fridge';
    case Pantry = 'pantry';
}
