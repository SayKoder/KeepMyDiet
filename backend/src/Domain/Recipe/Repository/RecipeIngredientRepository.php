<?php

namespace App\Domain\Recipe\Repository;

use App\Domain\Recipe\Entity\RecipeIngredient;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<RecipeIngredient>
 */
class RecipeIngredientRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, RecipeIngredient::class);
    }

    /**
     * Noms distincts (insensible à la casse) commençant par `$query`, un seul
     * exemplaire par nom — le plus récent — pour pré-remplir l'autocomplete à
     * la création d'une recette. Dédoublonnage fait en PHP plutôt qu'en SQL
     * (DISTINCT ne garderait pas les colonnes macros associées) : on sur-pêche
     * large (50) puis on garde le premier (le plus récent) par nom normalisé.
     *
     * @return RecipeIngredient[]
     */
    public function searchByName(string $query, int $limit = 10): array
    {
        /** @var RecipeIngredient[] $rows */
        $rows = $this->createQueryBuilder('i')
            ->andWhere('LOWER(i.name) LIKE :query')
            ->setParameter('query', mb_strtolower($query).'%')
            ->orderBy('i.id', 'DESC')
            ->setMaxResults(50)
            ->getQuery()
            ->getResult();

        $seen = [];
        $result = [];
        foreach ($rows as $row) {
            $key = mb_strtolower($row->getName());
            if (isset($seen[$key])) {
                continue;
            }
            $seen[$key] = true;
            $result[] = $row;
            if (count($result) >= $limit) {
                break;
            }
        }

        return $result;
    }
}
