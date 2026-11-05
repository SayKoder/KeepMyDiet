<?php

namespace App\Shared\Serializer;

use App\Domain\Fridge\Entity\FoodReference;
use App\Domain\Group\Entity\Group;
use App\Domain\Recipe\Entity\Recipe;
use App\Shared\Security\EditVoter;
use Symfony\Component\Security\Core\Authorization\AuthorizationCheckerInterface;
use Symfony\Component\Serializer\Normalizer\NormalizerAwareInterface;
use Symfony\Component\Serializer\Normalizer\NormalizerAwareTrait;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

/**
 * Ajoute `canEdit` (droit de l'utilisateur courant, voir EditVoter) aux
 * ressources modifiables, pour que l'app sache quand afficher « Modifier »
 * sans connaître l'identité de l'utilisateur.
 */
final class CanEditNormalizer implements NormalizerInterface, NormalizerAwareInterface
{
    use NormalizerAwareTrait;

    private const ALREADY_CALLED = 'can_edit_normalizer_already_called';

    public function __construct(private readonly AuthorizationCheckerInterface $authorizationChecker)
    {
    }

    public function normalize(mixed $data, ?string $format = null, array $context = []): array|string|int|float|bool|\ArrayObject|null
    {
        $normalized = $this->normalizer->normalize($data, $format, $context + [self::ALREADY_CALLED => true]);

        if (\is_array($normalized)) {
            $normalized['canEdit'] = $this->authorizationChecker->isGranted(EditVoter::EDIT, $data);
        }

        return $normalized;
    }

    public function supportsNormalization(mixed $data, ?string $format = null, array $context = []): bool
    {
        return !isset($context[self::ALREADY_CALLED])
            && ($data instanceof Group || $data instanceof Recipe || $data instanceof FoodReference);
    }

    public function getSupportedTypes(?string $format): array
    {
        return [Group::class => false, Recipe::class => false, FoodReference::class => false];
    }
}
