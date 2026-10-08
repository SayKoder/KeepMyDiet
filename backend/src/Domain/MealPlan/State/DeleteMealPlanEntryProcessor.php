<?php

namespace App\Domain\MealPlan\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\MealPlan\Entity\MealPlanEntry;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/** N'importe quel membre du groupe peut retirer un créneau, pas seulement qui l'a ajouté (même logique que FridgeItem). */
final class DeleteMealPlanEntryProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly GroupMembershipRepository $memberships,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        /** @var MealPlanEntry $data */
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
