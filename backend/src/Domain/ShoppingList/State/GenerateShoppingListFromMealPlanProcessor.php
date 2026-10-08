<?php

namespace App\Domain\ShoppingList\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Fridge\Repository\FridgeItemRepository;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Group\Repository\GroupRepository;
use App\Domain\MealPlan\Repository\MealPlanEntryRepository;
use App\Domain\ShoppingList\Dto\GenerateFromMealPlanInput;
use App\Domain\ShoppingList\Entity\ShoppingList;
use App\Domain\ShoppingList\Entity\ShoppingListItem;
use App\Domain\ShoppingList\Repository\ShoppingListRepository;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Contrairement à `GenerateShoppingListProcessor` (une ligne par recette +
 * ingrédient, jamais fusionnée — décision actée avec Carl le 2026-10-02),
 * celui-ci fusionne les lignes qui partagent le même nom+unité à travers
 * tous les repas prévus sur la période : une semaine de planning sans
 * consolidation produirait une liste illisible (5 lignes "Tomate"
 * séparées). Divergence assumée et documentée plutôt que décidée en
 * silence — à challenger avec Carl si besoin d'ajuster.
 *
 * Soustrait aussi ce qui est déjà en stock (frigo + placard confondus), par
 * correspondance approximative sur le nom (insensible à la casse) : même
 * limite déjà acceptée pour l'autocomplete d'ingrédients (pas de FK entre
 * `RecipeIngredient` et `FoodReference`).
 */
final class GenerateShoppingListFromMealPlanProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly GroupRepository $groups,
        private readonly GroupMembershipRepository $memberships,
        private readonly MealPlanEntryRepository $mealPlanEntries,
        private readonly FridgeItemRepository $fridgeItems,
        private readonly ShoppingListRepository $shoppingLists,
        private readonly EntityManagerInterface $em,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): ShoppingList
    {
        /** @var GenerateFromMealPlanInput $data */
        $group = $this->groups->find($uriVariables['groupId']);
        if (null === $group) {
            throw new NotFoundHttpException();
        }

        $user = $this->security->getUser();
        if (!$user instanceof User || !$this->memberships->isMember($user, $group)) {
            throw new AccessDeniedException();
        }

        $from = \DateTimeImmutable::createFromFormat('!Y-m-d', (string) $data->from);
        $to = \DateTimeImmutable::createFromFormat('!Y-m-d', (string) $data->to);
        if (false === $from || false === $to) {
            throw new BadRequestHttpException('from/to doivent être au format YYYY-MM-DD.');
        }

        $entries = $this->mealPlanEntries->findForGroupInRange($group, $from, $to);
        if ([] === $entries) {
            throw new BadRequestHttpException('Aucun repas prévu sur cette période.');
        }

        // Clé = "nom normalisé|unité" : on agrège quantités ET macros
        // (jamais des "pour 100g" déjà arrondis) avant de reconvertir en
        // "pour 100g" une seule fois à la fin.
        $aggregated = [];
        foreach ($entries as $entry) {
            $recipe = $entry->getRecipe();
            $ratio = $entry->getServings() / max(1, $recipe->getReferenceServings());

            foreach ($recipe->getIngredients() as $ingredient) {
                $key = mb_strtolower($ingredient->getName()).'|'.$ingredient->getUnit();
                $aggregated[$key] ??= [
                    'name' => $ingredient->getName(),
                    'unit' => $ingredient->getUnit(),
                    'quantity' => 0.0,
                    'calories' => 0.0,
                    'proteins' => 0.0,
                    'carbs' => 0.0,
                    'fats' => 0.0,
                ];

                $aggregated[$key]['quantity'] += $ingredient->getQuantity() * $ratio;
                $aggregated[$key]['calories'] += $ingredient->getCalories() * $ratio;
                $aggregated[$key]['proteins'] += $ingredient->getProteins() * $ratio;
                $aggregated[$key]['carbs'] += $ingredient->getCarbs() * $ratio;
                $aggregated[$key]['fats'] += $ingredient->getFats() * $ratio;
            }
        }

        // Stock actuel (frigo + placard), sommé avec la même clé pour un lookup direct.
        $stock = [];
        foreach ($this->fridgeItems->findForGroup($group) as $item) {
            $key = mb_strtolower($item->getFoodReference()->getName()).'|'.$item->getUnit();
            $stock[$key] = ($stock[$key] ?? 0.0) + $item->getQuantity();
        }

        $list = $this->shoppingLists->findActiveForGroup($group);
        if (null === $list) {
            $list = new ShoppingList();
            $list->setGroup($group);
        }

        foreach ($aggregated as $key => $line) {
            $remaining = $line['quantity'] - ($stock[$key] ?? 0.0);
            if ($remaining <= 0) {
                continue;
            }

            $base = $line['quantity'] > 0 ? $line['quantity'] : 1;

            $item = new ShoppingListItem();
            $item->setName($line['name']);
            $item->setQuantity($remaining);
            $item->setUnit($line['unit']);
            $item->setCaloriesPer100g($line['calories'] / $base * 100);
            $item->setProteinsPer100g($line['proteins'] / $base * 100);
            $item->setCarbsPer100g($line['carbs'] / $base * 100);
            $item->setFatsPer100g($line['fats'] / $base * 100);
            $item->setSourceRecipeName('Planning de la semaine');

            $list->addItem($item);
        }

        $this->em->persist($list);
        $this->em->flush();

        return $list;
    }
}
