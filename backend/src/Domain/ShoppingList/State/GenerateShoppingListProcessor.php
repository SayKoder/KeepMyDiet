<?php

namespace App\Domain\ShoppingList\State;

use ApiPlatform\Metadata\IriConverterInterface;
use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Group\Realtime\GroupChangePublisher;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Recipe\Entity\Recipe;
use App\Domain\ShoppingList\Dto\GenerateShoppingListInput;
use App\Domain\ShoppingList\Entity\ShoppingList;
use App\Domain\ShoppingList\Entity\ShoppingListItem;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;

/**
 * Ajoute à la liste active du groupe (créée si besoin) une ligne par
 * ingrédient de chaque recette sélectionnée. Quantités mises à l'échelle du
 * nombre de membres du groupe (CLAUDE.md, section "Liste de courses") — pas
 * de réglage par recette en v1. Pas de fusion des lignes qui partagent le
 * même nom entre deux recettes (décision actée avec Carl le 2026-10-02) :
 * une ligne par (recette, ingrédient), quitte à afficher deux fois "Tomate".
 */
final class GenerateShoppingListProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly ActiveShoppingListResolver $resolver,
        private readonly GroupMembershipRepository $memberships,
        private readonly IriConverterInterface $iriConverter,
        private readonly EntityManagerInterface $em,
        private readonly GroupChangePublisher $publisher,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): ShoppingList
    {
        /** @var GenerateShoppingListInput $data */
        $list = $this->resolver->resolve($uriVariables['groupId']);

        $servings = max(1, $this->memberships->countMembers($list->getGroup()));

        foreach ($data->recipes as $recipeIri) {
            $recipe = $this->iriConverter->getResourceFromIri($recipeIri);
            if (!$recipe instanceof Recipe) {
                throw new BadRequestHttpException(\sprintf('"%s" ne référence pas une recette.', $recipeIri));
            }

            $ratio = $servings / max(1, $recipe->getReferenceServings());

            foreach ($recipe->getIngredients() as $ingredient) {
                // Densité pour 100g indépendante du ratio (quantité et macros
                // scalent ensemble) : on la calcule depuis l'ingrédient
                // d'origine, pas depuis la quantité déjà mise à l'échelle.
                $base = $ingredient->getQuantity() > 0 ? $ingredient->getQuantity() : 1;

                $item = new ShoppingListItem();
                $item->setName($ingredient->getName());
                $item->setQuantity($ingredient->getQuantity() * $ratio);
                $item->setUnit($ingredient->getUnit());
                $item->setCaloriesPer100g($ingredient->getCalories() / $base * 100);
                $item->setProteinsPer100g($ingredient->getProteins() / $base * 100);
                $item->setCarbsPer100g($ingredient->getCarbs() / $base * 100);
                $item->setFatsPer100g($ingredient->getFats() / $base * 100);
                $item->setSourceRecipeName($recipe->getName());

                $list->addItem($item);
            }
        }

        $this->em->persist($list);
        $this->em->flush();
        $this->publisher->notify($list->getGroup(), 'shopping_list');

        return $list;
    }
}
