<?php

namespace App\Domain\Group\Entity;

enum GroupRole: string
{
    case Member = 'member';
    case Admin = 'admin';
}
