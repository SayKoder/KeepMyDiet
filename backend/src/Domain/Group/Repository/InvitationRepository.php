<?php

namespace App\Domain\Group\Repository;

use App\Domain\Group\Entity\Invitation;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<Invitation>
 */
class InvitationRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Invitation::class);
    }

    public function findOneByToken(string $token): ?Invitation
    {
        return $this->findOneBy(['token' => $token]);
    }
}
