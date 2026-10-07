<?php

namespace App\Domain\Nutrition\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Nutrition\Dto\AddWaterIntakeInput;
use App\Domain\Nutrition\Entity\WaterIntake;
use App\Domain\Nutrition\Repository\WaterIntakeRepository;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Crée la ligne du jour si elle n'existe pas encore, puis ajoute `deltaMl` au
 * total existant (jamais en dessous de 0, voir WaterIntake::setAmountMl).
 */
final class AddWaterIntakeProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly WaterIntakeRepository $waterIntakes,
        private readonly EntityManagerInterface $em,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): WaterIntake
    {
        /** @var AddWaterIntakeInput $data */
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $today = new \DateTimeImmutable('today');
        $intake = $this->waterIntakes->findForUserAndDate($user, $today);
        if (null === $intake) {
            $intake = new WaterIntake();
            $intake->setUser($user);
            $intake->setDate($today);
        }

        $intake->setAmountMl($intake->getAmountMl() + $data->deltaMl);

        $this->em->persist($intake);
        $this->em->flush();

        return $intake;
    }
}
