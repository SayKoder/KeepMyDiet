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

/**
 * PATCH (merge-patch+json) : seuls `recipe`/`servings` sont envoyés par le
 * client, `group`/`date`/`mealType` restent ceux déjà persistés (API
 * Platform fusionne le payload sur l'entité existante avant d'appeler ce
 * processor). Si le créneau avait déjà une réponse (MealPlanEntryLog), le
 * client doit renvoyer `respondToEntry` juste après ce PATCH :
 * CreateOrUpdateMealPlanEntryLogProcessor relit `entry.getRecipe()` à ce
 * moment-là, donc il annule l'ancienne contribution puis applique la
 * nouvelle automatiquement, sans double-comptage.
 */
final class UpdateMealPlanEntryProcessor implements ProcessorInterface
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

        $this->em->flush();

        return $data;
    }
}
