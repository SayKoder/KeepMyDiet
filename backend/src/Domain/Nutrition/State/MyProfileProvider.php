<?php

namespace App\Domain\Nutrition\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\Nutrition\Repository\ProfileRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Pas une vraie "collection" : renvoie 0 ou 1 élément (le profil de
 * l'utilisateur courant, s'il existe) — sans ça, le client n'a aucun moyen
 * de retrouver l'id de son propre profil avant de l'avoir créé une première
 * fois (même logique que MyGroupsProvider pour les groupes).
 */
final class MyProfileProvider implements ProviderInterface
{
    public function __construct(
        private readonly ProfileRepository $profiles,
        private readonly Security $security,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): array
    {
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $profile = $this->profiles->findOneBy(['user' => $user]);

        return null === $profile ? [] : [$profile];
    }
}
