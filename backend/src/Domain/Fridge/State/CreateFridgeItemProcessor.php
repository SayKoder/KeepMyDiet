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

final class CreateFridgeItemProcessor implements ProcessorInterface
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
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $group = $data->getGroup();
        if (null === $group || !$this->memberships->isMember($user, $group)) {
            throw new AccessDeniedException();
        }

        $data->setAddedBy($user);

        $this->em->persist($data);
        $this->em->flush();

        return $data;
    }
}
