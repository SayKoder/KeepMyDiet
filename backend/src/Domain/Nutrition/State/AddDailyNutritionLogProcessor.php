<?php

namespace App\Domain\Nutrition\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Nutrition\Dto\AddDailyNutritionLogInput;
use App\Domain\Nutrition\Entity\DailyNutritionLog;
use App\Domain\Nutrition\Repository\DailyNutritionLogRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

final class AddDailyNutritionLogProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly DailyNutritionLogRepository $dailyNutritionLogs,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): DailyNutritionLog
    {
        /** @var AddDailyNutritionLogInput $data */
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $date = null !== $data->date
            ? \DateTimeImmutable::createFromFormat('!Y-m-d', $data->date)
            : new \DateTimeImmutable('today');

        return $this->dailyNutritionLogs->applyDelta(
            $user,
            $date,
            $data->deltaKcal,
            $data->deltaProteinG,
            $data->deltaCarbG,
            $data->deltaFatG,
        );
    }
}
