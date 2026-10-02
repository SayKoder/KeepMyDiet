<?php

namespace App\Domain\Nutrition\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Nutrition\Entity\Profile;
use App\Domain\Nutrition\Repository\ProfileRepository;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Un seul profil par utilisateur — 409 si un profil existe déjà (passer par
 * Patch pour le modifier, pas par un nouveau Post).
 */
final class CreateProfileProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly Security $security,
        private readonly ProfileRepository $profiles,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        /** @var Profile $data */
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        if (null !== $this->profiles->findOneBy(['user' => $user])) {
            throw new ConflictHttpException('Un profil existe déjà pour cet utilisateur.');
        }

        $data->setUser($user);

        $this->em->persist($data);
        $this->em->flush();

        return $data;
    }
}
