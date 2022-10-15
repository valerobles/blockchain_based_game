%builtins output range_check


from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.math import unsigned_div_rem
// For StarkNet contracts
//from starkware.starknet.common.syscalls import (
//    get_block_number,
//    get_block_timestamp,
//)

// ...

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
    let rand = get_random{range_check_ptr=range_check_ptr}(2);

    // let winner = fightAndGetWinner(bisasam,pikachu);
    // serialize_word(winner.id);
    // let dmg = attackAndGetDamage{range_check_ptr=range_check_ptr}(bisasam, bisasam.atk1, pikachu);
    serialize_word(rand);
    return ();
}

func attackAndGetDamage{range_check_ptr}(pkmn1: Pokemon, atk: Attack*, pkmn2: Pokemon) -> felt {
   // Damage formula = (((2* 1 or 2) / 5 + 2 * AttackDamage * Attack.Pok1 / Defense.Pok2) / 50) + 2 * STAB * Type1 * Type2 * random (217 bis 255 / 255)
   
   
   
   alloc_locals;
    if (atk.type == pkmn1.type1) {
        local stab = 2;  // Same Type Attack Bonus (STAB)
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

func get_random{range_check_ptr}(range: felt,) -> felt {
      let (res, r) = unsigned_div_rem(1665829291743, range); // toDo: replace with currentTimeMillis
      return r+1;  
}



