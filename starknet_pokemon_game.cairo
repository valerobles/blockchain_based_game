
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le

struct Pokemon {
    id: felt,
    hp: felt,
    atk: felt,
    init: felt,
    def: felt,
    type1: felt,
    type2: felt,
    atk1_type: felt,
    atk1_damage: felt,
    atk2_type: felt,
    atk2_damage: felt,
    // atk3: Attack*,
    // atk4: Attack*,
}

@storage_var
func winner_pkmn() -> (winner: Pokemon) {

}


// Increases the balance by the given amount.
@external
func fight{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(pkmn1: Pokemon, pkmn2: Pokemon) -> (res: felt) {
       // toDo : use random attacks -> use get_random()
   
   alloc_locals;
    // local firstIsFaster = is_le(pkmn1.init,pkmn2.init);
    local pkmn1_ : Pokemon* = new Pokemon(id=pkmn1.id, hp=pkmn1.hp, atk=pkmn1.atk, init=pkmn1.init, def=pkmn1.def,
    type1=pkmn1.type1, type2=pkmn1.type2, atk1_type=pkmn1.atk1_type,
    atk1_damage=pkmn1.atk1_damage, atk2_type=pkmn1.atk2_type,
    atk2_damage=pkmn1.atk2_damage);
    
    local pkmn2_ : Pokemon* = new Pokemon(id=pkmn2.id, hp=pkmn2.hp, atk=pkmn2.atk, init=pkmn2.init, def=pkmn2.def,
    type1=pkmn2.type1, type2=pkmn2.type2, atk1_type=pkmn2.atk1_type,
    atk1_damage=pkmn2.atk1_damage, atk2_type=pkmn2.atk2_type,
    atk2_damage=pkmn2.atk2_damage);
    
    
    
    local faster_pkmn: Pokemon*;
    local slower_pkmn: Pokemon*;
    if (is_le(pkmn1.init, pkmn2.init) == 0) {
        faster_pkmn = pkmn1_;
        slower_pkmn = pkmn2_;
    } else {
        faster_pkmn = pkmn2_;
        slower_pkmn = pkmn1_;
    }

    // pkmn1 is faster
    let _dmgx = attackAndGetDamage(faster_pkmn, faster_pkmn.atk1_type, faster_pkmn.atk1_damage, slower_pkmn);
    local dmg = _dmgx;

    // calculate new HP
    local pkmn2_hp = slower_pkmn.hp - dmg;

    let newPok_: Pokemon* = updateHP(slower_pkmn, pkmn2_hp);
    local newPok: Pokemon* = newPok_;

    // if new HP value less 0 -> dead
    if (is_le(newPok.hp, 0) == 1) {
        // return winner
        //serialize_word(newPok.hp);
        //winner_pkmn.write(faster_pkmn);
        return (res=faster_pkmn.id);
    }

    let _dmgSecondFight = attackAndGetDamage(slower_pkmn, slower_pkmn.atk1_type, slower_pkmn.atk1_damage,faster_pkmn);
    local dmgSecondFight = _dmgSecondFight;

    local pkmn1_hp = faster_pkmn.hp - dmg;

    let newPok_2: Pokemon* = updateHP(faster_pkmn, pkmn1_hp);
    local newPok2: Pokemon* = newPok_2;

    if (is_le(newPok2.hp, 0) == 1) {
        // return winner
        //serialize_word(newPok2.hp);
        return (res=slower_pkmn.id);
    }
      
    let winner_id = fight(newPok, newPok2);  
    
  
    return (res=winner_id);
}


func attackAndGetDamage{range_check_ptr}(
    pkmn1: Pokemon*, atk_type: felt, atk_damage: felt,  pkmn2: Pokemon*
) -> felt {
    // Damage formula = (((2* level *1 or 2) / 5  * AttackDamage * Attack.Pok1 / Defense.Pok2) / 50 )* STAB *  random (217 bis 255 / 255)
    alloc_locals;
    local stab;
    if (atk_type == pkmn1.type1) {
        stab = 2;
    }
    if (atk_type == pkmn1.type1) {
        stab = 2;
    } else {
        stab = 1;
    }

    let level = 50000;
    let rand1 = get_random(2);
    let a = 2 * level * rand1;
    let (crit, r) = unsigned_div_rem(a, 5);
    let b = crit * atk_damage * pkmn1.atk;
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

func updateHP(pkmn: Pokemon*, hp_: felt) -> (pok: Pokemon*) {
    return (new Pokemon(id=pkmn.id, hp=hp_, atk=pkmn.atk, init=pkmn.init, def=pkmn.def,
    type1=pkmn.type1, type2=pkmn.type2, atk1_type=pkmn.atk1_type,
    atk1_damage=pkmn.atk1_damage, atk2_type=pkmn.atk2_type,
    atk2_damage=pkmn.atk2_damage, ));
}

func get_random{range_check_ptr}(range: felt) -> felt {
    let (res, r) = unsigned_div_rem(1665829291743, range);  // toDo: replace with currentTimeMillis
    return (r + 1);
}

