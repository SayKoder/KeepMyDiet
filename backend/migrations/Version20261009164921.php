<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * food_reference.name : 120 -> 255 caractères. Préparation pour l'import
 * complet Ciqual 2020 (Version20261009190000) : une poignée de noms
 * officiels dépassent 120 caractères (ex: "Boisson lactée aromatisée
 * (arôme inconnu), sucrée, au lait partiellement écrémé, enrichie et/ou
 * restaurée en vitamines et/ou minéraux (aliment moyen)", 149 caractères).
 */
final class Version20261009164921 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'food_reference.name : 120 -> 255 caractères (noms Ciqual longs)';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE food_reference ALTER name TYPE VARCHAR(255)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE food_reference ALTER name TYPE VARCHAR(120)');
    }
}
