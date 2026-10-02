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

        // Particularité observée (pas élucidée, testée avec plusieurs
        // contournements — proxy Doctrine forcé, em->clear()+find() frais —
        // sans effet) : la réponse de CE POST n'embarque QUE l'IRI de
        // `foodReference` (pas ses macros), alors qu'un GET juste après
        // l'affiche correctement. Sans impact réel : le client ne se fie
        // jamais à ce retour pour l'affichage, il rafraîchit toujours via un
        // GET après création (voir frontend/.../fridge_controller.dart).
        return $data;
    }
}
