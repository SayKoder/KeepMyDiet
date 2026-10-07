<?php

namespace App\Domain\Nutrition\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Nutrition\Repository\WaterGoalRepository;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Supprime la ligne de l'utilisateur si elle existe (retour au calcul par
 * défaut côté client). `output: false` sur l'opération (voir WaterGoal) :
 * pas de corps de réponse à sérialiser, donc pas besoin de renvoyer une
 * entité avec un id — c'est précisément ce qui cassait l'ancienne version de
 * `set` avec `goalMl: null` (erreur "Unable to generate an IRI").
 */
final class ResetWaterGoalProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly WaterGoalRepository $waterGoals,
        private readonly EntityManagerInterface $em,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): void
    {
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $existing = $this->waterGoals->findForUser($user);
        if (null !== $existing) {
            $this->em->remove($existing);
            $this->em->flush();
        }
    }
}
