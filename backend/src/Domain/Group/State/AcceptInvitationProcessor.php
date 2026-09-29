<?php

namespace App\Domain\Group\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Group\Entity\GroupMembership;
use App\Domain\Group\Entity\GroupRole;
use App\Domain\Group\Entity\Invitation;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Group\Repository\InvitationRepository;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Rejoint un groupe via un token d'invitation — crée une nouvelle adhésion
 * SANS jamais retirer l'utilisateur de ses groupes existants (voir CLAUDE.md).
 */
final class AcceptInvitationProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly InvitationRepository $invitations,
        private readonly GroupMembershipRepository $memberships,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        /** @var Invitation $data (objet transitoire désérialisé du body, pas encore l'entité réelle) */
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $invitation = $this->invitations->findOneByToken($data->getToken());
        if (null === $invitation) {
            throw new NotFoundHttpException("Invitation introuvable.");
        }

        $group = $invitation->getGroup();
        if ($this->memberships->isMember($user, $group)) {
            throw new ConflictHttpException('Vous êtes déjà membre de ce groupe.');
        }

        $this->em->persist(new GroupMembership($group, $user, GroupRole::Member));
        $this->em->flush();

        return $invitation;
    }
}
