<?php

namespace App\Domain\ShoppingList\Entity;

use App\Domain\ShoppingList\Repository\ShoppingListItemRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;

/**
 * Pas une ApiResource à part entière : toujours créé (via `generate`) et
 * consommé (via `checkout`) à travers ShoppingList, même principe que
 * RecipeIngredient pour Recipe. Macros stockées déjà converties pour 100g
 * (convention FoodReference, pas la convention "pour ma quantité" de
 * RecipeIngredient) : ça évite de refaire la conversion au moment du
 * checkout, où on copie ces champs tels quels dans le FoodReference créé.
 */
#[ORM\Entity(repositoryClass: ShoppingListItemRepository::class)]
class ShoppingListItem
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['shopping_list:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: ShoppingList::class, inversedBy: 'items')]
    #[ORM\JoinColumn(nullable: false)]
    private ?ShoppingList $shoppingList = null;

    #[ORM\Column(length: 120)]
    #[Groups(['shopping_list:read'])]
    private string $name = '';

    #[ORM\Column(type: 'float')]
    #[Groups(['shopping_list:read'])]
    private float $quantity = 0;

    #[ORM\Column(length: 20)]
    #[Groups(['shopping_list:read'])]
    private string $unit = 'g';

    #[ORM\Column(type: 'float')]
    #[Groups(['shopping_list:read'])]
    private float $caloriesPer100g = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['shopping_list:read'])]
    private float $proteinsPer100g = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['shopping_list:read'])]
    private float $carbsPer100g = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['shopping_list:read'])]
    private float $fatsPer100g = 0;

    /** Nom de la recette d'origine, dénormalisé au moment de `generate` — juste pour affichage, pas une vraie relation. */
    #[ORM\Column(length: 120, nullable: true)]
    #[Groups(['shopping_list:read'])]
    private ?string $sourceRecipeName = null;

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getShoppingList(): ?ShoppingList
    {
        return $this->shoppingList;
    }

    public function setShoppingList(?ShoppingList $shoppingList): static
    {
        $this->shoppingList = $shoppingList;

        return $this;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function setName(string $name): static
    {
        $this->name = $name;

        return $this;
    }

    public function getQuantity(): float
    {
        return $this->quantity;
    }

    public function setQuantity(float $quantity): static
    {
        $this->quantity = $quantity;

        return $this;
    }

    public function getUnit(): string
    {
        return $this->unit;
    }

    public function setUnit(string $unit): static
    {
        $this->unit = $unit;

        return $this;
    }

    public function getCaloriesPer100g(): float
    {
        return $this->caloriesPer100g;
    }

    public function setCaloriesPer100g(float $caloriesPer100g): static
    {
        $this->caloriesPer100g = $caloriesPer100g;

        return $this;
    }

    public function getProteinsPer100g(): float
    {
        return $this->proteinsPer100g;
    }

    public function setProteinsPer100g(float $proteinsPer100g): static
    {
        $this->proteinsPer100g = $proteinsPer100g;

        return $this;
    }

    public function getCarbsPer100g(): float
    {
        return $this->carbsPer100g;
    }

    public function setCarbsPer100g(float $carbsPer100g): static
    {
        $this->carbsPer100g = $carbsPer100g;

        return $this;
    }

    public function getFatsPer100g(): float
    {
        return $this->fatsPer100g;
    }

    public function setFatsPer100g(float $fatsPer100g): static
    {
        $this->fatsPer100g = $fatsPer100g;

        return $this;
    }

    public function getSourceRecipeName(): ?string
    {
        return $this->sourceRecipeName;
    }

    public function setSourceRecipeName(?string $sourceRecipeName): static
    {
        $this->sourceRecipeName = $sourceRecipeName;

        return $this;
    }
}
