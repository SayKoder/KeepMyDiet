<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Index fonctionnel sur `LOWER(name)` pour `RecipeIngredientRepository::searchByName()`
 * (l'autocomplete d'ingrédients) : sans ça, cette requête scanne toute la
 * table `recipe_ingredient` à chaque frappe, un pool global qui grossit avec
 * tous les utilisateurs (contrairement au frigo/aliments, scopés par groupe).
 * Écrite à la main (pas générée par `make:migration`) : Doctrine ne modélise
 * pas les index fonctionnels avec classe d'opérateur via ses attributs.
 *
 * `varchar_pattern_ops` est nécessaire pour qu'un `LIKE 'query%'` puisse
 * utiliser l'index en PostgreSQL, indépendamment de la locale de la base (un
 * index B-tree classique sur `LOWER(name)` ne suffit pas si la collation
 * n'est pas "C").
 */
final class Version20261007154500 extends AbstractMigration
{
    public function getDescription(): string
    {
        return "Index fonctionnel sur LOWER(name) pour l'autocomplete d'ingrédients de recette";
    }

    public function up(Schema $schema): void
    {
        $this->addSql('CREATE INDEX idx_recipe_ingredient_name_lower ON recipe_ingredient (LOWER(name) varchar_pattern_ops)');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('DROP INDEX idx_recipe_ingredient_name_lower');
    }
}
