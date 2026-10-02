<?php

namespace App\Domain\Fridge\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Fridge\Entity\FridgeItem;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * N'importe quel membre du groupe peut retirer un aliment (consommé/jeté) —
 * pas réservé à qui l'a ajouté, contrairement à la suppression d'une recette.
 */
final class DeleteFridgeItemProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly GroupMembershipRepository $memberships,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        /** @var FridgeItem $data */
        $user = $this->security->getUser();
        $group = $data->getGroup();
        if (!$user instanceof User || null === $group || !$this->memberships->isMember($user, $group)) {
            throw new AccessDeniedException();
        }

        $this->em->remove($data);
        $this->em->flush();

        return null;
    }
}
