%builtins output range_check

// Import the serialize_word() function.
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

func createBisasam() -> Pokemon {
    return (Pokemon(id=1, hp=45, atk=49, init=45, def=49, type1='grass', type2='', atk1=new Attack(type='grass', damage=11)));
}
func createPikachu() -> Pokemon {
    return (Pokemon(id=25, hp=35, atk=55, init=90, def=40, type1='electro', type2='', atk1=new Attack(type='electro', damage=10)));
}
func main{output_ptr: felt*, range_check_ptr}() {
    let bisasam = createBisasam();
    let pikachu = createPikachu();
    // let winner = fightAndGetWinner(bisasam,pikachu);
    // serialize_word(winner.id);
    let dmg = attackAndGetDamage{range_check_ptr=range_check_ptr}(bisasam, bisasam.atk1, pikachu);
    serialize_word(dmg);
    return ();
}

func attackAndGetDamage{range_check_ptr}(pkmn1: Pokemon, atk: Attack*, pkmn2: Pokemon) -> felt {
    alloc_locals;
    if (atk.type == pkmn1.type1) {
        local stab = 2;
        let (res, r) = unsigned_div_rem(pkmn1.atk, pkmn2.def);
        //let (res, r) = div(pkmn1.atk, pkmn2.def);
        // local damage =  res - pkmn2.def + atk.damage + stab;
        return (pkmn2.hp - res);
    }
    if (atk.type == pkmn1.type2) {
        local stab = 2;
        local damage = pkmn1.atk * atk.damage * stab;
        return (damage);
    }
    return (pkmn1.atk / pkmn2.def * atk.damage);
}
func fightAndGetWinner(pkmn1: Pokemon, pkmn2: Pokemon) -> Pokemon {
    return (pkmn1);
}

