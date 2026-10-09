<?php

namespace App\Domain\MealPlan\Entity;

enum MealPlanEntryStatus: string
{
    case Eaten = 'eaten';
    case Skipped = 'skipped';
    case Replaced = 'replaced';
}
