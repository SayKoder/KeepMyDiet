<?php

namespace App\Domain\ShoppingList\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\ShoppingList\Dto\AddShoppingListItemInput;
use App\Domain\ShoppingList\Entity\ShoppingList;
use App\Domain\ShoppingList\Entity\ShoppingListItem;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;

final class AddShoppingListItemProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly ActiveShoppingListResolver $resolver,
        private readonly EntityManagerInterface $em,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): ShoppingList
    {
        /** @var AddShoppingListItemInput $data */
        $name = trim($data->name);
        $unit = trim($data->unit);
        if ('' === $name || mb_strlen($name) > 120 || '' === $unit || mb_strlen($unit) > 20 || $data->quantity <= 0) {
            throw new BadRequestHttpException('Nom, quantité et unité sont requis.');
        }

        $list = $this->resolver->resolve($uriVariables['groupId']);

        $item = new ShoppingListItem();
        $item->setName($name);
        $item->setQuantity($data->quantity);
        $item->setUnit($unit);
        $item->setCaloriesPer100g($data->caloriesPer100g);
        $item->setProteinsPer100g($data->proteinsPer100g);
        $item->setCarbsPer100g($data->carbsPer100g);
        $item->setFatsPer100g($data->fatsPer100g);
        $list->addItem($item);

        $this->em->persist($list);
        $this->em->flush();

        return $list;
    }
}
