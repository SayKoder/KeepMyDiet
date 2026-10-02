<?php

namespace App\Domain\Fridge\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Link;
use ApiPlatform\Metadata\Post;
use App\Domain\Fridge\Repository\FoodReferenceRepository;
use App\Domain\Fridge\State\CreateFoodReferenceProcessor;
use App\Domain\Fridge\State\FoodReferenceCollectionProvider;
use App\Domain\Group\Entity\Group;
use App\Shared\Entity\User;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * Catalogue d'aliments de référence, en deux origines (voir CLAUDE.md,
 * "APIs externes utilisées") :
 * - Ciqual (source = ciqual, group = null) : seed global partagé par tout le
 *   monde, jamais créé depuis l'app — seulement via migration.
 * - Produit personnalisé (source = custom, group = <groupe>) : créé depuis
 *   l'app, soit pré-rempli via un scan de code-barres trouvé sur Open Food
 *   Facts, soit saisi à la main si le scan ne trouve rien — réutilisable
 *   ensuite uniquement par CE groupe. Le barcode n'est donc PAS unique en
 *   base : deux groupes qui scannent le même produit créent chacun leur
 *   propre ligne (doublon accepté, voir JOURNAL.md).
 *
 * Valeurs nutritionnelles toujours pour 100g (convention Ciqual/Open Food
 * Facts) — contrairement à RecipeIngredient qui stocke les macros pour SA
 * quantité précise (voir JOURNAL.md, étape 8 : deux domaines, deux
 * conventions différentes, chacune adaptée à son cas d'usage).
 */
#[ORM\Entity(repositoryClass: FoodReferenceRepository::class)]
#[ApiResource(
    operations: [
        new GetCollection(
            uriTemplate: '/groups/{groupId}/food_references',
            uriVariables: ['groupId' => new Link(fromClass: Group::class, toProperty: 'group')],
            provider: FoodReferenceCollectionProvider::class,
        ),
        new Post(processor: CreateFoodReferenceProcessor::class, validationContext: ['groups' => ['food_reference:write']]),
    ],
    normalizationContext: ['groups' => ['food_reference:read']],
    denormalizationContext: ['groups' => ['food_reference:write']],
)]
class FoodReference
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['food_reference:read', 'fridge_item:read'])]
    private ?int $id = null;

    #[ORM\Column(length: 120)]
    #[Groups(['food_reference:read', 'food_reference:write', 'fridge_item:read'])]
    #[Assert\NotBlank(groups: ['food_reference:write'])]
    private string $name = '';

    #[ORM\Column(type: 'float')]
    #[Groups(['food_reference:read', 'food_reference:write', 'fridge_item:read'])]
    #[Assert\PositiveOrZero(groups: ['food_reference:write'])]
    private float $caloriesPer100g = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['food_reference:read', 'food_reference:write', 'fridge_item:read'])]
    #[Assert\PositiveOrZero(groups: ['food_reference:write'])]
    private float $proteinsPer100g = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['food_reference:read', 'food_reference:write', 'fridge_item:read'])]
    #[Assert\PositiveOrZero(groups: ['food_reference:write'])]
    private float $carbsPer100g = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['food_reference:read', 'food_reference:write', 'fridge_item:read'])]
    #[Assert\PositiveOrZero(groups: ['food_reference:write'])]
    private float $fatsPer100g = 0;

    /** Toujours forcé à Custom par le processor de création — jamais choisi par le client. */
    #[ORM\Column(length: 20, enumType: FoodSource::class)]
    #[Groups(['food_reference:read', 'fridge_item:read'])]
    private FoodSource $source = FoodSource::Custom;

    #[ORM\Column(length: 64, nullable: true)]
    #[Groups(['food_reference:read', 'food_reference:write', 'fridge_item:read'])]
    private ?string $barcode = null;

    /** null = seed global (Ciqual), partagé par tout le monde. */
    #[ORM\ManyToOne(targetEntity: Group::class)]
    #[ORM\JoinColumn(nullable: true)]
    #[Groups(['food_reference:read', 'food_reference:write'])]
    #[Assert\NotNull(groups: ['food_reference:write'])]
    private ?Group $group = null;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: true)]
    private ?User $createdBy = null;

    public function getId(): ?int
    {
        return $this->id;
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

    public function getSource(): FoodSource
    {
        return $this->source;
    }

    public function setSource(FoodSource $source): static
    {
        $this->source = $source;

        return $this;
    }

    public function getBarcode(): ?string
    {
        return $this->barcode;
    }

    public function setBarcode(?string $barcode): static
    {
        $this->barcode = $barcode;

        return $this;
    }

    public function getGroup(): ?Group
    {
        return $this->group;
    }

    public function setGroup(?Group $group): static
    {
        $this->group = $group;

        return $this;
    }

    public function getCreatedBy(): ?User
    {
        return $this->createdBy;
    }

    public function setCreatedBy(?User $createdBy): static
    {
        $this->createdBy = $createdBy;

        return $this;
    }
}
