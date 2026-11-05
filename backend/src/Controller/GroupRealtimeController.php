<?php

namespace App\Controller;

use App\Domain\Group\Realtime\GroupChangePublisher;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Group\Repository\GroupRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Mercure\HubInterface;
use Symfony\Component\Mercure\Jwt\Grant;
use Symfony\Component\Mercure\Jwt\TokenFactoryInterface;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

final class GroupRealtimeController extends AbstractController
{
    #[Route('/api/groups/{id}/realtime', name: 'group_realtime', requirements: ['id' => '\d+'], methods: ['GET'])]
    public function __invoke(
        int $id,
        GroupRepository $groups,
        GroupMembershipRepository $memberships,
        Security $security,
        HubInterface $hub,
        TokenFactoryInterface $defaultTokenFactory,
    ): JsonResponse {
        $group = $groups->find($id);
        if (null === $group) {
            throw new NotFoundHttpException();
        }

        $user = $security->getUser();
        if (!$user instanceof User || !$memberships->isMember($user, $group)) {
            throw new AccessDeniedException();
        }

        $topic = GroupChangePublisher::topic($id);

        return new JsonResponse([
            'url' => $hub->getPublicUrl(),
            'topic' => $topic,
            'token' => $defaultTokenFactory->create([new Grant([Grant::ACTION_SUBSCRIBE], [$topic])]),
        ]);
    }
}
