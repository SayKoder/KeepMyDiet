<?php

namespace App\Domain\Nutrition\Dto;

/**
 * Entrée de `POST /water_goals/set`. Pour supprimer la surcharge (retour au
 * calcul par défaut côté client), voir `POST /water_goals/reset` à la place
 * — pas géré ici via un `goalMl` nul : l'entité renvoyée en réponse n'aurait
 * jamais d'id, et API Platform ne peut pas générer d'IRI pour ça (testé,
 * erreur 400 "Unable to generate an IRI").
 */
final class SetWaterGoalInput
{
    public int $goalMl = 0;
}
