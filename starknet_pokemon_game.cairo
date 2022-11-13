%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_nn
from starkware.starknet.common.messages import send_message_to_l1
// TODO change to our contract adress
@storage_var
func l1_address() -> ( felt) {
}
@external
func set_l1_address{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(address: felt) {
    l1_address.write(address);
    return ();
}
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
    name_id: felt,
    // atk3: Attack*,
    // atk4: Attack*,
}
//for testing purposes
func createBisasam() -> Pokemon* {
    return (new Pokemon(id=1, hp=152, atk=111, init=106, def=111, type1='grass', type2='', atk1_type='grass', atk1_damage=30, atk2_type='normal', atk2_damage=40, name_id=1));
}
//for testing purposes
func createPikachu() -> Pokemon* {
    return (new Pokemon(id=25, hp=142, atk=117, init=156, def=101, type1='electro', type2='', atk1_type='electro', atk1_damage=30, atk2_type='normal', atk2_damage=35, name_id=2));
}

@storage_var
func winner(fight_id: felt) -> (winner_id: felt) {
}
//for testing purposes
@external
func no_param_fight{pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (winner: felt) {
    let (res) = fight(createBisasam(), createPikachu());

    return (winner=res);
}
//deprecated
@external
func pokemon_game_old{pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pkmn1: Pokemon, pkmn2: Pokemon
) -> (winner: felt) {
    let (__fp__, _) = get_fp_and_pc();
    let (res) = fight(&pkmn1, &pkmn2);
    return (winner=res);
}

@l1_handler
func pokemon_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_address: felt, pkmn1: Pokemon, pkmn2: Pokemon, fight_id: felt
) {
    let (__fp__, _) = get_fp_and_pc();
    // TODO doesnt compile
    //let (l1_contract_address)= l1_address.read();
       // assert from_address = l1_contract_address;
    let (res) = fight(&pkmn1, &pkmn2);

    // save winner in map
    winner.write(fight_id, res);

    get_winner(fight_id);
    return ();
}
//read winner from a fight_id
@external
func get_winner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fight_id: felt
) {
    let (res) = winner.read(fight_id=fight_id);
    let (message_payload: felt*) = alloc();
    assert message_payload[0] = fight_id;
    assert message_payload[1] = res;
      let (l1_contract_address)=l1_address.read();
    send_message_to_l1(to_address=l1_contract_address, payload_size=2, payload=message_payload);
    
    return ();
}
func fight{pedersen_ptr: HashBuiltin*, range_check_ptr}(pkmn1: Pokemon*, pkmn2: Pokemon*) -> (
    res: felt
) {
    // toDo : use random attacks -> use get_random()

    alloc_locals;
    // local firstIsFaster = is_le(pkmn1.init,pkmn2.init);

    local faster_pkmn: Pokemon*;
    local slower_pkmn: Pokemon*;
    if (is_le(pkmn1.init, pkmn2.init) == 0) {
        faster_pkmn = pkmn1;
        slower_pkmn = pkmn2;
    } else {
        faster_pkmn = pkmn2;
        slower_pkmn = pkmn1;
    }

    // pkmn1 is faster
    let _dmgx = attackAndGetDamage(
        faster_pkmn, faster_pkmn.atk1_type, faster_pkmn.atk1_damage, slower_pkmn
    );
    local dmg = _dmgx;

    // calculate new HP
    local pkmn2_hp = slower_pkmn.hp - dmg;

    let newPok_: Pokemon* = updateHP(slower_pkmn, pkmn2_hp);
    local newPok: Pokemon* = newPok_;

    // if new HP value less 0 -> dead
    if (is_le(newPok.hp, 0) == 1) {
        // return winner
        // serialize_word(newPok.hp);
        // winner_pkmn.write(faster_pkmn);
        return (res=faster_pkmn.id);
    }

    let _dmgSecondFight = attackAndGetDamage(
        slower_pkmn, slower_pkmn.atk1_type, slower_pkmn.atk1_damage, faster_pkmn
    );
    local dmgSecondFight = _dmgSecondFight;

    local pkmn1_hp = faster_pkmn.hp - dmg;

    let newPok_2: Pokemon* = updateHP(faster_pkmn, pkmn1_hp);
    local newPok2: Pokemon* = newPok_2;

    if (is_le(newPok2.hp, 0) == 1) {
        // return winner
        // serialize_word(newPok2.hp);
        return (res=slower_pkmn.id);
    }

    let (res) = fight(newPok, newPok2);

    return (res=res);
}

func attackAndGetDamage{range_check_ptr}(
    pkmn1: Pokemon*, atk_type: felt, atk_damage: felt, pkmn2: Pokemon*
) -> felt {
    // Damage formula = (((2* level *1 or 2) / 5  * AttackDamage * Attack.Pok1 / Defense.Pok2) / 50 )* STAB *  random (217 bis 255 / 255)
    alloc_locals;
    local stab;
    if (atk_type == pkmn1.type1) {
        stab = 2;
    } else {
        if (atk_type == pkmn1.type2) {
            stab = 2;
        } else {
            stab = 1;
        }
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

func updateHP(pkmn: Pokemon*, hp_: felt) -> Pokemon* {
    return (new Pokemon(id=pkmn.id, hp=hp_, atk=pkmn.atk, init=pkmn.init, def=pkmn.def,
        type1=pkmn.type1, type2=pkmn.type2, atk1_type=pkmn.atk1_type,
        atk1_damage=pkmn.atk1_damage, atk2_type=pkmn.atk2_type,
        atk2_damage=pkmn.atk2_damage, name_id=pkmn.name_id));
}

func get_random{range_check_ptr}(range: felt) -> felt {
    let (res, r) = unsigned_div_rem(1665829291743, range);  // toDo: replace with currentTimeMillis
    return (r + 1);
}
