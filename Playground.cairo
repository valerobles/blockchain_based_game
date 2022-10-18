%builtins output range_check

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.math import unsigned_div_rem

struct Pokemon {
    id: felt,
    hp: felt,
    atk: felt,
    init: felt,
    def: felt,
    type1: felt,
    type2: felt,
    atk1: Attack*,
    // atk2: Attack*,
    // atk3: Attack*,
    // atk4: Attack*,
}
struct Attack {
    type: felt,
    damage: felt,
}

func createBisasam() -> Pokemon* {
    return (new Pokemon(id=1, hp=152, atk=111, init=106, def=111, type1='grass', type2='', atk1=new Attack(type='grass', damage=30)));
}
func createPikachu() -> Pokemon* {
    return (new Pokemon(id=25, hp=142, atk=117, init=156, def=101, type1='electro', type2='', atk1=new Attack(type='electro', damage=30)));
}

func main{output_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    local bisasam: Pokemon* = createBisasam();
    local pikachu: Pokemon* = createPikachu();

    let _dmg = attackAndGetDamage(bisasam, bisasam.atk1, pikachu);
    local dmg = _dmg;
    let _dmg2 = attackAndGetDamage(pikachu, pikachu.atk1, bisasam);
    local dmg2 = _dmg2;

    let string = 'Damage done: ';

    // serialize_word(string);
    serialize_word(dmg);
    return ();
}

func attackAndGetDamage{range_check_ptr, output_ptr: felt*}(
    pkmn1: Pokemon*, atk: Attack*, pkmn2: Pokemon*
) -> felt {
    // Damage formula = (((2* level *1 or 2) / 5  * AttackDamage * Attack.Pok1 / Defense.Pok2) / 50 )* STAB *  random (217 bis 255 / 255)
    alloc_locals;
    local stab;
    if (atk.type == pkmn1.type1) {
        stab = 2;
    }
    if (atk.type == pkmn1.type1) {
        stab = 2;
    } else {
        stab = 1;
    }

    let level = 50000;
    let rand1 = get_random(2);
    let a = 2 * level * rand1;
    let (crit, r) = unsigned_div_rem(a, 5);
    let b = crit * atk.damage * pkmn1.atk;
    let (c, r) = unsigned_div_rem(b, pkmn2.def);
    let (d, r) = unsigned_div_rem(c, 50);
    let e = d * stab;
    let f = get_random(50);
    let g = e * (f + 205);
    let (h, r) = unsigned_div_rem(g, 255);
    let (final, r) = unsigned_div_rem(h, 1000);
    // serialize_word(final);
    return (final);
}
func fightAndGetWinner(pkmn1: Pokemon, pkmn2: Pokemon) -> Pokemon {
    return (pkmn1);
}

func get_random{range_check_ptr}(range: felt) -> felt {
    let (res, r) = unsigned_div_rem(1665829291743, range);  // toDo: replace with currentTimeMillis
    return (r + 1);
}
