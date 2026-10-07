<?php

namespace App\Domain\ShoppingList\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Fridge\Entity\FoodReference;
use App\Domain\Fridge\Entity\FoodSource;
use App\Domain\Fridge\Entity\FridgeItem;
use App\Domain\Fridge\Entity\StorageLocation;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Group\Repository\GroupRepository;
use App\Domain\ShoppingList\Dto\CheckoutShoppingListInput;
use App\Domain\ShoppingList\Entity\ShoppingList;
use App\Domain\ShoppingList\Repository\ShoppingListItemRepository;
use App\Domain\ShoppingList\Repository\ShoppingListRepository;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Transforme chaque ligne achetée en un nouveau FoodReference "Custom" +
 * FridgeItem (toujours une création, jamais de recherche d'un FoodReference
 * existant par nom — décision actée avec Carl le 2026-10-02, voir
 * ShoppingList) puis la retire de la liste. Pas d'estimation automatique de
 * DLC par catégorie de produit (CLAUDE.md l'évoque comme piste, mais ça
 * suppose une taxonomie de produits qui n'existe pas encore) : la DLC est
 * obligatoire et saisie par le client pour chaque ligne.
 */
final class CheckoutShoppingListProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly GroupRepository $groups,
        private readonly GroupMembershipRepository $memberships,
        private readonly ShoppingListRepository $shoppingLists,
        private readonly ShoppingListItemRepository $shoppingListItems,
        private readonly EntityManagerInterface $em,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): ShoppingList
    {
        /** @var CheckoutShoppingListInput $data */
        $group = $this->groups->find($uriVariables['groupId']);
        if (null === $group) {
            throw new NotFoundHttpException();
        }

        $user = $this->security->getUser();
        if (!$user instanceof User || !$this->memberships->isMember($user, $group)) {
            throw new AccessDeniedException();
        }

        $list = $this->shoppingLists->findActiveForGroup($group);
        if (null === $list) {
            throw new NotFoundHttpException('Aucune liste de courses active pour ce groupe.');
        }

        foreach ($data->items as $checkoutItem) {
            $item = null !== $checkoutItem->itemId ? $this->shoppingListItems->find($checkoutItem->itemId) : null;
            if (null === $item || $item->getShoppingList() !== $list) {
                throw new BadRequestHttpException(\sprintf('Ligne %s introuvable dans cette liste.', $checkoutItem->itemId ?? '?'));
            }

            $storageLocation = StorageLocation::tryFrom((string) $checkoutItem->storageLocation);
            if (null === $storageLocation) {
                throw new BadRequestHttpException('storageLocation doit être "fridge" ou "pantry".');
            }

            if (null === $checkoutItem->expirationDate) {
                throw new BadRequestHttpException('expirationDate est obligatoire pour valider un achat.');
            }
            $expirationDate = \DateTimeImmutable::createFromFormat('!Y-m-d', $checkoutItem->expirationDate);
            if (false === $expirationDate) {
                throw new BadRequestHttpException('expirationDate doit être au format YYYY-MM-DD.');
            }

            $foodReference = new FoodReference();
            $foodReference->setName($item->getName());
            $foodReference->setCaloriesPer100g($item->getCaloriesPer100g());
            $foodReference->setProteinsPer100g($item->getProteinsPer100g());
            $foodReference->setCarbsPer100g($item->getCarbsPer100g());
            $foodReference->setFatsPer100g($item->getFatsPer100g());
            $foodReference->setSource(FoodSource::Custom);
            $foodReference->setGroup($group);
            $foodReference->setCreatedBy($user);
            $this->em->persist($foodReference);

            $fridgeItem = new FridgeItem();
            $fridgeItem->setGroup($group);
            $fridgeItem->setFoodReference($foodReference);
            $fridgeItem->setStorageLocation($storageLocation);
            $fridgeItem->setQuantity($item->getQuantity());
            $fridgeItem->setUnit($item->getUnit());
            $fridgeItem->setExpirationDate($expirationDate);
            $fridgeItem->setAddedBy($user);
            $this->em->persist($fridgeItem);

            $list->removeItem($item);
        }

        $this->em->flush();

        return $list;
    }
}
