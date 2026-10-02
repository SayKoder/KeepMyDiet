<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Seed d'une vingtaine d'aliments bruts courants, valeurs nutritionnelles
 * approximatives pour 100g (moyennes largement documentées, PAS un export
 * officiel du fichier Ciqual de l'ANSES — décision actée avec Carl le
 * 2026-09-30 : un seed réduit à la main pour débloquer le développement,
 * le vrai import complet pourra se faire plus tard sans changer le modèle
 * de données, voir JOURNAL.md).
 */
final class Version20260930200200 extends AbstractMigration
{
    public function getDescription(): string
    {
        return "Seed d'aliments bruts courants (source=ciqual, group=null)";
    }

    public function up(Schema $schema): void
    {
        $foods = [
            ['Pomme', 52, 0.3, 14.0, 0.2],
            ['Banane', 89, 1.1, 23.0, 0.3],
            ['Riz blanc cuit', 130, 2.7, 28.0, 0.3],
            ['Pâtes cuites', 131, 5.0, 25.0, 1.1],
            ['Poulet (blanc, cru)', 165, 31.0, 0.0, 3.6],
            ['Œuf entier', 155, 13.0, 1.1, 11.0],
            ['Pomme de terre cuite', 87, 1.9, 20.0, 0.1],
            ['Tomate', 18, 0.9, 3.9, 0.2],
            ['Carotte', 41, 0.9, 10.0, 0.2],
            ['Brocoli', 34, 2.8, 7.0, 0.4],
            ['Lait demi-écrémé', 46, 3.3, 4.8, 1.6],
            ['Yaourt nature', 61, 3.5, 4.7, 3.3],
            ['Emmental', 380, 28.0, 0.0, 30.0],
            ['Baguette', 274, 9.0, 55.0, 1.2],
            ['Bœuf haché 15% MG', 230, 20.0, 0.0, 15.0],
            ['Saumon cru', 208, 20.0, 0.0, 13.0],
            ['Lentilles cuites', 116, 9.0, 20.0, 0.4],
            ['Avocat', 160, 2.0, 8.5, 14.7],
            ["Huile d'olive", 884, 0.0, 0.0, 100.0],
            ['Beurre', 717, 0.9, 0.1, 81.0],
        ];

        foreach ($foods as [$name, $calories, $proteins, $carbs, $fats]) {
            $this->addSql(
                'INSERT INTO food_reference (name, calories_per100g, proteins_per100g, carbs_per100g, fats_per100g, source, barcode, group_id, created_by_id) '
                . "VALUES (:name, :calories, :proteins, :carbs, :fats, 'ciqual', NULL, NULL, NULL)",
                ['name' => $name, 'calories' => $calories, 'proteins' => $proteins, 'carbs' => $carbs, 'fats' => $fats]
            );
        }
    }

    public function down(Schema $schema): void
    {
        $this->addSql("DELETE FROM food_reference WHERE source = 'ciqual'");
    }
}
