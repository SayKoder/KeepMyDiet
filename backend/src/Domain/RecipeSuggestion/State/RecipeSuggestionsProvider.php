<?php

namespace App\Domain\RecipeSuggestion\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\Fridge\Repository\FridgeItemRepository;
use App\Domain\Group\Entity\Group;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Group\Repository\GroupRepository;
use App\Domain\Nutrition\Repository\ProfileRepository;
use App\Domain\Recipe\Entity\Recipe;
use App\Domain\Recipe\Repository\RecipeRepository;
use App\Domain\RecipeSuggestion\Dto\RecipeSuggestion;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Classe chaque recette du pool global selon ce qui est disponible dans le
 * frigo/placard du groupe (CLAUDE.md, section "Moteur de recettes") :
 * 1. Couverture d'ingrédients (combien sont déjà en stock) — critère
 *    principal, décroissant.
 *    2. Urgence DLC (la recette utilisant l'ingrédient qui périme le plus
 *    tôt passe devant) — départage à couverture égale.
 * 3. Proximité calorique au besoin moyen du groupe — dernier départage,
 *    jamais un filtre strict (voir RecipeSuggestion, portée actée le
 *    2026-10-02).
 *
 * Matching par nom NORMALISÉ (trim + minuscule), exact sinon — "Tomate" et
 * "tomate" matchent, "Tomate" et "Tomates cerises" non (décision actée avec
 * Carl le 2026-10-02 : pas de correspondance partielle, trop de faux
 * positifs possibles sans un vrai système de synonymes).
 */
final class RecipeSuggestionsProvider implements ProviderInterface
{
    public function __construct(
        private readonly GroupRepository $groups,
        private readonly GroupMembershipRepository $memberships,
        private readonly FridgeItemRepository $fridgeItems,
        private readonly RecipeRepository $recipes,
        private readonly ProfileRepository $profiles,
        private readonly Security $security,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): array
    {
        $group = $this->groups->find($uriVariables['groupId']);
        if (null === $group) {
            throw new NotFoundHttpException();
        }

        $user = $this->security->getUser();
        if (!$user instanceof User || !$this->memberships->isMember($user, $group)) {
            throw new AccessDeniedException();
        }

        $earliestExpiryByName = $this->earliestExpiryByIngredientName($group);
        $averageCalorieGoal = $this->averageCalorieGoal($group);

        $suggestions = array_map(
            fn (Recipe $recipe) => $this->buildSuggestion($recipe, $earliestExpiryByName),
            $this->recipes->findAll(),
        );

        usort($suggestions, fn (RecipeSuggestion $a, RecipeSuggestion $b) => $this->compare($a, $b, $averageCalorieGoal));

        return $suggestions;
    }

    /** @return array<string, \DateTimeImmutable> nom normalisé -> DLC la plus proche parmi les FridgeItem de ce nom */
    private function earliestExpiryByIngredientName(Group $group): array
    {
        $earliest = [];
        foreach ($this->fridgeItems->findForGroup($group) as $item) {
            $key = $this->normalize($item->getFoodReference()->getName());
            $date = $item->getExpirationDate();
            if (!isset($earliest[$key]) || $date < $earliest[$key]) {
                $earliest[$key] = $date;
            }
        }

        return $earliest;
    }

    private function averageCalorieGoal(Group $group): ?float
    {
        $goals = [];
        foreach ($this->memberships->findForGroup($group) as $membership) {
            $profile = $this->profiles->findOneBy(['user' => $membership->getUser()]);
            if (null !== $profile) {
                $goals[] = $profile->getCalorieGoal();
            }
        }

        return [] === $goals ? null : array_sum($goals) / \count($goals);
    }

    /** @param array<string, \DateTimeImmutable> $earliestExpiryByName */
    private function buildSuggestion(Recipe $recipe, array $earliestExpiryByName): RecipeSuggestion
    {
        $matched = 0;
        $missing = [];
        $soonest = null;

        foreach ($recipe->getIngredients() as $ingredient) {
            $key = $this->normalize($ingredient->getName());
            if (isset($earliestExpiryByName[$key])) {
                ++$matched;
                $date = $earliestExpiryByName[$key];
                if (null === $soonest || $date < $soonest) {
                    $soonest = $date;
                }
            } else {
                $missing[] = $ingredient->getName();
            }
        }

        $total = \count($recipe->getIngredients());

        return new RecipeSuggestion(
            id: $recipe->getId(),
            name: $recipe->getName(),
            referenceServings: $recipe->getReferenceServings(),
            caloriesPerServing: $recipe->getReferenceServings() > 0 ? $recipe->getTotalCalories() / $recipe->getReferenceServings() : 0.0,
            matchedIngredientsCount: $matched,
            totalIngredientsCount: $total,
            missingIngredientNames: $missing,
            soonestExpirationDate: $soonest,
        );
    }

    private function compare(RecipeSuggestion $a, RecipeSuggestion $b, ?float $averageCalorieGoal): int
    {
        $coverageA = $a->getTotalIngredientsCount() > 0 ? $a->getMatchedIngredientsCount() / $a->getTotalIngredientsCount() : 0.0;
        $coverageB = $b->getTotalIngredientsCount() > 0 ? $b->getMatchedIngredientsCount() / $b->getTotalIngredientsCount() : 0.0;
        if ($coverageA !== $coverageB) {
            return $coverageA < $coverageB ? 1 : -1;
        }

        $urgencyA = $a->getSoonestExpirationDate();
        $urgencyB = $b->getSoonestExpirationDate();
        if ($urgencyA != $urgencyB) {
            if (null === $urgencyA) {
                return 1;
            }
            if (null === $urgencyB) {
                return -1;
            }

            return $urgencyA <=> $urgencyB;
        }

        if (null !== $averageCalorieGoal) {
            $diffA = abs($a->getCaloriesPerServing() - $averageCalorieGoal);
            $diffB = abs($b->getCaloriesPerServing() - $averageCalorieGoal);

            return $diffA <=> $diffB;
        }

        return 0;
    }

    private function normalize(string $name): string
    {
        return mb_strtolower(trim($name));
    }
}
