<?php

namespace App\Shared\Security;

use App\Domain\Fridge\Entity\FoodReference;
use App\Domain\Fridge\Entity\FoodSource;
use App\Domain\Group\Entity\Group;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Recipe\Entity\Recipe;
use App\Shared\Entity\User;
use Symfony\Component\Security\Core\Authentication\Token\TokenInterface;
use Symfony\Component\Security\Core\Authorization\Voter\Vote;
use Symfony\Component\Security\Core\Authorization\Voter\Voter;

/**
 * Seule source de vérité de « qui peut modifier quoi » : utilisée par les
 * opérations de l'API (`is_granted('EDIT', object)`) et par `canEdit`
 * (voir CanEditNormalizer). Groupe : un admin (le créateur l'est dès la
 * création). Recette et aliment : son créateur ; les aliments du catalogue
 * de base (Ciqual) ne se modifient pas.
 */
final class EditVoter extends Voter
{
    public const EDIT = 'EDIT';

    public function __construct(private readonly GroupMembershipRepository $memberships)
    {
    }

    protected function supports(string $attribute, mixed $subject): bool
    {
        return self::EDIT === $attribute
            && ($subject instanceof Group || $subject instanceof Recipe || $subject instanceof FoodReference);
    }

    protected function voteOnAttribute(string $attribute, mixed $subject, TokenInterface $token, ?Vote $vote = null): bool
    {
        $user = $token->getUser();
        if (!$user instanceof User) {
            return false;
        }

        return match (true) {
            $subject instanceof Group => $this->memberships->isAdmin($user, $subject),
            $subject instanceof Recipe => $this->isCreator($subject->getCreatedBy(), $user),
            default => FoodSource::Custom === $subject->getSource() && $this->isCreator($subject->getCreatedBy(), $user),
        };
    }

    private function isCreator(?User $creator, User $user): bool
    {
        return null !== $creator && $creator->getId() === $user->getId();
    }
}
