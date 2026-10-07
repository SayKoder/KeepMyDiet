<?php

namespace App\Domain\Nutrition\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Nutrition\Dto\SetWaterGoalInput;
use App\Domain\Nutrition\Entity\WaterGoal;
use App\Domain\Nutrition\Repository\WaterGoalRepository;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/** Crée ou met à jour la ligne de l'utilisateur. Pour l'effacer, voir ResetWaterGoalProcessor. */
final class SetWaterGoalProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly WaterGoalRepository $waterGoals,
        private readonly EntityManagerInterface $em,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): WaterGoal
    {
        /** @var SetWaterGoalInput $data */
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $goal = $this->waterGoals->findForUser($user) ?? new WaterGoal();
        $goal->setUser($user);
        $goal->setGoalMl($data->goalMl);

        $this->em->persist($goal);
        $this->em->flush();

        return $goal;
    }
}
