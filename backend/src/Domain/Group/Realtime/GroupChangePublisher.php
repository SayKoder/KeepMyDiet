<?php

namespace App\Domain\Group\Realtime;

use App\Domain\Group\Entity\Group;
use Psr\Log\LoggerInterface;
use Symfony\Component\Mercure\HubInterface;
use Symfony\Component\Mercure\Update;

/**
 * Prévient les membres d'un groupe qu'une ressource a changé (message sans
 * donnée : le client recharge via l'API, qui contrôle déjà les droits).
 * Mercure indisponible = simple log : l'action de l'utilisateur ne doit
 * jamais échouer à cause du temps réel.
 */
final class GroupChangePublisher
{
    public function __construct(
        private readonly HubInterface $hub,
        private readonly LoggerInterface $logger,
    ) {
    }

    public static function topic(int $groupId): string
    {
        return '/groups/'.$groupId;
    }

    public function notify(?Group $group, string ...$types): void
    {
        if (null === $group || null === $group->getId()) {
            return;
        }

        foreach ($types as $type) {
            try {
                $this->hub->publish(new Update(
                    self::topic($group->getId()),
                    json_encode(['type' => $type], \JSON_THROW_ON_ERROR),
                    private: true,
                ));
            } catch (\Throwable $e) {
                $this->logger->warning('Publication Mercure impossible.', ['exception' => $e]);

                return;
            }
        }
    }
}
