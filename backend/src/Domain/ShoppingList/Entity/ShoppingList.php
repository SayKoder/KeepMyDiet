<?php

namespace App\Domain\ShoppingList\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Link;
use ApiPlatform\Metadata\Post;
use App\Domain\Group\Entity\Group;
use App\Domain\ShoppingList\Dto\CheckoutShoppingListInput;
use App\Domain\ShoppingList\Dto\GenerateShoppingListInput;
use App\Domain\ShoppingList\Repository\ShoppingListRepository;
use App\Domain\ShoppingList\State\CheckoutShoppingListProcessor;
use App\Domain\ShoppingList\State\GenerateShoppingListProcessor;
use App\Domain\ShoppingList\State\ShoppingListProvider;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;

/**
 * Une seule liste "active" par groupe à la fois (voir CLAUDE.md, section
 * "Liste de courses") : `generate` crée la liste du groupe si elle n'existe
 * pas encore, sinon ajoute des lignes à celle en cours. `checkout` retire de
 * la liste les lignes achetées en les transformant en FoodReference +
 * FridgeItem (toujours un nouveau FoodReference "Custom", jamais de
 * matching par nom — voir JOURNAL.md, décision actée avec Carl le
 * 2026-10-02). Pas de `Post`/`Patch`/`Delete` classiques exposés : tout
 * passe par ces deux actions métier.
 */
#[ORM\Entity(repositoryClass: ShoppingListRepository::class)]
#[ApiResource(
    operations: [
        new GetCollection(
            uriTemplate: '/groups/{groupId}/shopping_lists',
            uriVariables: ['groupId' => new Link(fromClass: Group::class, toProperty: 'group')],
            provider: ShoppingListProvider::class,
        ),
        new Post(
            uriTemplate: '/groups/{groupId}/shopping_lists/generate',
            uriVariables: ['groupId' => new Link(fromClass: Group::class, toProperty: 'group')],
            input: GenerateShoppingListInput::class,
            processor: GenerateShoppingListProcessor::class,
        ),
        new Post(
            uriTemplate: '/groups/{groupId}/shopping_lists/checkout',
            uriVariables: ['groupId' => new Link(fromClass: Group::class, toProperty: 'group')],
            input: CheckoutShoppingListInput::class,
            processor: CheckoutShoppingListProcessor::class,
        ),
    ],
    normalizationContext: ['groups' => ['shopping_list:read']],
)]
class ShoppingList
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['shopping_list:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: Group::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ?Group $group = null;

    #[ORM\Column(type: 'datetime_immutable')]
    #[Groups(['shopping_list:read'])]
    private \DateTimeImmutable $createdAt;

    /** @var Collection<int, ShoppingListItem> */
    #[ORM\OneToMany(targetEntity: ShoppingListItem::class, mappedBy: 'shoppingList', cascade: ['persist'], orphanRemoval: true)]
    #[Groups(['shopping_list:read'])]
    private Collection $items;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
        $this->items = new ArrayCollection();
    }

    public function getId(): ?int
    {
        return $this->id;
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

    public function getCreatedAt(): \DateTimeImmutable
    {
        return $this->createdAt;
    }

    /**
     * Réindexée à chaque appel : après un `removeItem()` (checkout partiel),
     * `ArrayCollection` garde les clés PHP d'origine des éléments restants
     * (ex: `[1 => ...]` au lieu de `[0 => ...]`) — `json_encode` sérialise
     * alors ce tableau en objet JSON (`{"1": ...}`) plutôt qu'en array
     * (`[...]`), ce qui casse le `as List` attendu côté Flutter. Retourner
     * une collection neuve à partir de `array_values()` évite le problème
     * sans toucher à `$this->items`, que Doctrine suit pour la persistance.
     *
     * @return Collection<int, ShoppingListItem>
     */
    public function getItems(): Collection
    {
        return new ArrayCollection(array_values($this->items->toArray()));
    }

    public function addItem(ShoppingListItem $item): static
    {
        if (!$this->items->contains($item)) {
            $this->items->add($item);
            $item->setShoppingList($this);
        }

        return $this;
    }

    public function removeItem(ShoppingListItem $item): static
    {
        $this->items->removeElement($item);

        return $this;
    }
}
