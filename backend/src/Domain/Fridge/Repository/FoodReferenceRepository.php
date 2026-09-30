<?php

namespace App\Domain\Fridge\Repository;

use App\Domain\Fridge\Entity\FoodReference;
use App\Domain\Group\Entity\Group;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<FoodReference>
 */
class FoodReferenceRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, FoodReference::class);
    }

    /**
     * Seed global (Ciqual, group = null) + produits personnalisés propres à CE groupe.
     *
     * @return FoodReference[]
     */
    public function findForGroup(Group $group): array
    {
        return $this->createQueryBuilder('f')
            ->where('f.group IS NULL OR f.group = :group')
            ->setParameter('group', $group)
            ->orderBy('f.name', 'ASC')
            ->getQuery()
            ->getResult();
    }
}
