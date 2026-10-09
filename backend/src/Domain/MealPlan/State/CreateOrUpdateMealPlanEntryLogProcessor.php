<?php

namespace App\Domain\MealPlan\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\MealPlan\Entity\MealPlanEntry;
use App\Domain\MealPlan\Entity\MealPlanEntryLog;
use App\Domain\MealPlan\Entity\MealPlanEntryStatus;
use App\Domain\MealPlan\Repository\MealPlanEntryLogRepository;
use App\Domain\Nutrition\Repository\DailyNutritionLogRepository;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Upsert par (entry, user) : si une réponse existe déjà pour ce créneau
 * (l'utilisateur change d'avis, ou corrige le lendemain), on soustrait
 * d'abord ses `appliedX` du DailyNutritionLog du jour avant d'appliquer la
 * nouvelle réponse — jamais de double-comptage, et pas de recalcul depuis la
 * recette qui pourrait avoir changé depuis (voir MealPlanEntryLog).
 *
 * Pour `Eaten`, on compte toujours 1 portion de la recette (`totalX /
 * referenceServings`) : `servings` sur MealPlanEntry est la quantité
 * *prévue* pour le créneau (indépendante du nombre de membres, voir
 * MealPlanEntry), pas "combien ce membre en particulier a mangé" — un membre
 * qui répond au pop-up a mangé sa propre portion, pas le plat entier.
 */
final class CreateOrUpdateMealPlanEntryLogProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly MealPlanEntryLogRepository $mealPlanEntryLogs,
        private readonly DailyNutritionLogRepository $dailyNutritionLogs,
        private readonly GroupMembershipRepository $memberships,
        private readonly EntityManagerInterface $em,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): MealPlanEntryLog
    {
        /** @var MealPlanEntryLog $data */
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $entry = $data->getMealPlanEntry();
        if (null === $entry || !$this->memberships->isMember($user, $entry->getGroup())) {
            throw new AccessDeniedException();
        }

        $log = $this->mealPlanEntryLogs->findForEntryAndUser($entry, $user) ?? $data;
        $log->setMealPlanEntry($entry);
        $log->setUser($user);

        if ($log !== $data) {
            $log->setStatus($data->getStatus());
            $log->setReplacementDescription($data->getReplacementDescription());
            $log->setReplacementCalories($data->getReplacementCalories());
            $log->setReplacementProteinG($data->getReplacementProteinG());
            $log->setReplacementCarbG($data->getReplacementCarbG());
            $log->setReplacementFatG($data->getReplacementFatG());
        }

        // Annule la contribution précédemment appliquée (0 la première fois).
        $this->dailyNutritionLogs->applyDelta(
            $user,
            $entry->getDate(),
            -$log->getAppliedCalories(),
            -$log->getAppliedProteinG(),
            -$log->getAppliedCarbG(),
            -$log->getAppliedFatG(),
        );

        [$kcal, $protein, $carb, $fat] = match ($log->getStatus()) {
            MealPlanEntryStatus::Eaten => $this->portionFromRecipe($entry),
            MealPlanEntryStatus::Replaced => [
                (int) round($log->getReplacementCalories() ?? 0),
                $log->getReplacementProteinG() ?? 0.0,
                $log->getReplacementCarbG() ?? 0.0,
                $log->getReplacementFatG() ?? 0.0,
            ],
            MealPlanEntryStatus::Skipped => [0, 0.0, 0.0, 0.0],
        };

        $this->dailyNutritionLogs->applyDelta($user, $entry->getDate(), $kcal, $protein, $carb, $fat);

        $log->setAppliedCalories($kcal);
        $log->setAppliedProteinG($protein);
        $log->setAppliedCarbG($carb);
        $log->setAppliedFatG($fat);

        $this->em->persist($log);
        $this->em->flush();

        return $log;
    }

    /** @return array{0: int, 1: float, 2: float, 3: float} */
    private function portionFromRecipe(MealPlanEntry $entry): array
    {
        $recipe = $entry->getRecipe();
        $referenceServings = $recipe->getReferenceServings();

        return [
            (int) round($recipe->getTotalCalories() / $referenceServings),
            $recipe->getTotalProteins() / $referenceServings,
            $recipe->getTotalCarbs() / $referenceServings,
            $recipe->getTotalFats() / $referenceServings,
        ];
    }
}
