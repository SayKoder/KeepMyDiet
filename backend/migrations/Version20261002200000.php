<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Le scan de code-barres (étape 15) peut faire se rencontrer le même produit
 * dans deux groupes différents, qui créeraient alors chacun leur propre
 * FoodReference "Custom" pour ce barcode (décision : rester scopé par
 * groupe plutôt que de passer au group=null partagé façon Ciqual). L'index
 * unique posé à la création du schéma l'interdisait — on le remplace par un
 * index simple (toujours utile pour la recherche par barcode).
 */
final class Version20261002200000 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'food_reference.barcode : index unique -> index simple (plusieurs groupes peuvent scanner le même produit)';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('DROP INDEX UNIQ_3659248897AE0266');
        $this->addSql('CREATE INDEX IDX_3659248897AE0266 ON food_reference (barcode)');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('DROP INDEX IDX_3659248897AE0266');
        $this->addSql('CREATE UNIQUE INDEX UNIQ_3659248897AE0266 ON food_reference (barcode)');
    }
}
