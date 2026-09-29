<?php

namespace App\Domain\Group\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Group\Entity\Group;
use App\Domain\Group\Entity\GroupMembership;
use App\Domain\Group\Entity\GroupRole;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Crée le groupe et l'adhésion admin du créateur en une seule opération
 * atomique — un groupe ne doit jamais exister sans au moins un admin.
 */
final class CreateGroupProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        /** @var Group $data */
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $this->em->persist($data);
        $this->em->persist(new GroupMembership($data, $user, GroupRole::Admin));
        $this->em->flush();

        return $data;
    }
}
