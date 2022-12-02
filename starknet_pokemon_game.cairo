%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.math import unsigned_div_rem, split_felt
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_nn
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import get_tx_info
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.registers import get_label_location

@storage_var
func l1_address() -> (felt,) {
}
@storage_var
func nonce() -> (felt,) {
}
@event
func address_set(address: felt) {
}
@event
func winner_event(winner: felt) {
}

// Setter for L1 address
@external
func set_l1_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    l1_address.write(address);
    address_set.emit(address=address);
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
// create a pokemon for testing purposes
func createBisasam() -> Pokemon* {
    return (new Pokemon(id=5, hp=152, atk=111, init=106, def=111, type1=1, type2=99, atk1_type=13, atk1_damage=1000, atk2_type=13, atk2_damage=1000, name_id=1));
}
// create a pokemon for testing purposes
func createPikachu() -> Pokemon* {
    return (new Pokemon(id=6, hp=142, atk=117, init=156, def=101, type1=0, type2=99, atk1_type=13, atk1_damage=100, atk2_type=13, atk2_damage=100, name_id=25));
}
// Mapping to save the id of the winning pokemon for each fight_id
@storage_var
func winner(fight_id: felt) -> (winner_id: felt) {
}
// for testing purposes
@external
func no_param_fight{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    winner: felt
) {
    let (res) = fight(createBisasam(), createPikachu());

    return (winner=res);
}

@event
func fight_steps(step: felt) {
}

@external
func sendDummyMessage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (message_payload: felt*) = alloc();
    assert message_payload[0] = 98;
    let (l1_contract_address) = l1_address.read();
    send_message_to_l1(to_address=l1_contract_address, payload_size=1, payload=message_payload);
    return ();
}

// Takes the L1 address, the attributes for two pokemon, and a fight_id
// Saves the fight_id and winner as a mapping in func winner, sends the winner to L1 contract_address
@l1_handler
func pokemon_game_flat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_address: felt,
    id1: felt,
    hp1: felt,
    atk1: felt,
    init1: felt,
    def1: felt,
    type11: felt,
    type21: felt,
    atk1_type1: felt,
    atk1_damage1: felt,
    atk2_type1: felt,
    atk2_damage1: felt,
    name_id1: felt,
    id2: felt,
    hp2: felt,
    atk2: felt,
    init2: felt,
    def2: felt,
    type12: felt,
    type22: felt,
    atk1_type2: felt,
    atk1_damage2: felt,
    atk2_type2: felt,
    atk2_damage2: felt,
    name_id2: felt,
    fight_id: felt,
) {
    alloc_locals;
    fight_steps.emit(step=0);
    local pkmn1: Pokemon = Pokemon(id=id1, hp=hp1, atk=atk1, init=init1, def=def1,
        type1=type11, type2=type21, atk1_type=atk1_type1,
        atk1_damage=atk1_damage1, atk2_type=atk2_type1,
        atk2_damage=atk2_damage1, name_id=name_id1);

    local pkmn2: Pokemon = Pokemon(id=id2, hp=hp2, atk=atk2, init=init2, def=def2,
        type1=type12, type2=type22, atk1_type=atk1_type2,
        atk1_damage=atk1_damage2, atk2_type=atk2_type2,
        atk2_damage=atk2_damage2, name_id=name_id2);
    let (__fp__, _) = get_fp_and_pc();
    // TODO doesnt compile
    // let (l1_contract_address)= l1_address.read();
    // assert from_address = l1_contract_address;
    fight_steps.emit(step=1);
    let (res) = fight(&pkmn1, &pkmn2);
    fight_steps.emit(step=2);
    // save winner in map
    winner.write(fight_id, res);

    let (res) = winner.read(fight_id=fight_id);
    let (message_payload: felt*) = alloc();
    assert message_payload[0] = res;
    assert message_payload[1] = fight_id;
    let (l1_contract_address) = l1_address.read();
    send_message_to_l1(to_address=l1_contract_address, payload_size=2, payload=message_payload);
    fight_steps.emit(step=3);
    return ();
}
@l1_handler
func pokemon_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_address: felt, pkmn1: Pokemon, pkmn2: Pokemon, fight_id: felt
) {
    let (__fp__, _) = get_fp_and_pc();
    // TODO doesnt compile
    // let (l1_contract_address)= l1_address.read();
    // assert from_address = l1_contract_address;
    let (res) = fight(&pkmn1, &pkmn2);

    // save winner in map
    winner.write(fight_id, res);

    // send result to l1
    let (res) = winner.read(fight_id=fight_id);
    let (message_payload: felt*) = alloc();
    assert message_payload[0] = res;
    assert message_payload[1] = fight_id;
    let (l1_contract_address) = l1_address.read();
    send_message_to_l1(to_address=l1_contract_address, payload_size=2, payload=message_payload);

    return ();
}
@event
func get_winner_called(winner: felt) {
}

// Takes a fight_id
// Returns the winner of that fight
@view
func get_winner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fight_id: felt
) -> (winner: felt) {
    let (res) = winner.read(fight_id=fight_id);
    get_winner_called.emit(winner=res);
    return (winner=res);
}

// Takes two pokemon to fight
// Pokemon take turns to deal damage to eachother, until one of them has 0 HP
// Returns the ID of the winning pokemon
func fight{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pkmn1: Pokemon*, pkmn2: Pokemon*
) -> (res: felt) {
    alloc_locals;
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
    let coinflip = get_random(2);
    local atk_damage_fast: felt;
    local atk_type_fast: felt;
    local atk_damage_slow: felt;
    local atk_type_slow: felt;
    if (coinflip == 1) {
        atk_damage_fast = faster_pkmn.atk1_damage;
        atk_type_fast = faster_pkmn.atk1_type;
        atk_damage_slow = slower_pkmn.atk1_damage;
        atk_type_slow = slower_pkmn.atk1_type;
    } else {
        atk_damage_fast = faster_pkmn.atk2_damage;
        atk_type_fast = faster_pkmn.atk2_type;
        atk_damage_slow = slower_pkmn.atk1_damage;
        atk_type_slow = slower_pkmn.atk1_type;
    }

    let _dmgx = attackAndGetDamage(faster_pkmn, atk_type_fast, atk_damage_fast, slower_pkmn);

    local dmg = _dmgx;

    // calculate new HP
    local pkmn2_hp = slower_pkmn.hp - dmg;
     let (z) = getEfficiency(atk_type_fast, slower_pkmn.type1, slower_pkmn.type2, 1);
 if(z==0){
          pkmn2_hp = pkmn2_hp - 1;
     }
    let newPok_: Pokemon* = updateHP(slower_pkmn, pkmn2_hp);
    local newPok: Pokemon* = newPok_;

    // if new HP value less 0 -> dead

    if (is_le(newPok.hp, 0) == 1) {
        return (res=faster_pkmn.id);
    } else {

        let _dmgSecondFight = attackAndGetDamage(
            slower_pkmn, atk_type_slow, atk_damage_slow, faster_pkmn
        );
        local dmgSecondFight = _dmgSecondFight;

        local pkmn1_hp = faster_pkmn.hp - dmg;

        let newPok_2: Pokemon* = updateHP(faster_pkmn, pkmn1_hp);
        local newPok2: Pokemon* = newPok_2;

        if (is_le(newPok2.hp, 0) == 1) {
            return (res=slower_pkmn.id);
        } else {
            let (res) = fight(newPok, newPok2);
            return (res=res);
        }
    }
}

// Takes an attacking pokemon, attack type, attack damage and a defending pokemon
// Returns the damage dealt to the defending pokemon
func attackAndGetDamage{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
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
    let (z) = getEfficiency(atk_type, pkmn2.type1, pkmn2.type2, e);
    let g = z * (f + 205);
    let (h, r) = unsigned_div_rem(g, 255);
    let (final, r) = unsigned_div_rem(h, 1000);
    return (final);
}
func getEfficiency{range_check_ptr}(atk_type: felt, type1: felt, type2: felt, e: felt) -> (
    res: felt
) {
    alloc_locals;
    local z: felt;
    let (data) = get_data();
    let index = atk_type * 18 + type1;
    let efficiency1 = data[index];
    local efficiency2: felt;
    if (type2 != 99) {
        let index2 = atk_type * 18 + type2;
        let efficiency2temp = data[index2];
        if (efficiency2temp == 0) {
            efficiency2 = 0;
        }
        if (efficiency2temp == 2) {
            efficiency2 = 2;
        }
        if (efficiency2temp == 3) {
            efficiency2 = 3;
        } else {
            efficiency2 = 1;
        }
    } else {
        efficiency2 = 1;
    }
    local total_efficiency: felt;
    if (efficiency1 != 3) {
        if (efficiency2 != 3) {
            local total_efficiency = efficiency1 * efficiency2;
            z = e * total_efficiency;
        }
    }
    let (quotient_four, remain) = unsigned_div_rem(e, 4);
    let (quotient_two, remain) = unsigned_div_rem(e, 2);
    if (efficiency1 == 3) {
        if (efficiency2 == 3) {
            // durch 4
            z = quotient_four;
        }
        if (efficiency2 == 0) {
            // mal 0
            z = 0;
        }
        if (efficiency2 == 2) {
            // mal 1
            z = e;
        }
        if (efficiency2 == 1) {
            // durch 2
            z = quotient_two;
        }
    }
    if (efficiency2 == 3) {
        if (efficiency1 == 3) {
            // durch 4
            z = quotient_four;
        }
        if (efficiency1 == 0) {
            // mal 0
            z = 0;
        }
        if (efficiency1 == 2) {
            // mal 1
            z = e;
        }
        if (efficiency1 == 1) {
            // durch 2
            z = quotient_two;
        }
    }
    return (res=z);
}

// Takes a pokemon and a new HP value
// return a new pokemon with the attributes of the old pokemon and the new HP value
func updateHP(pkmn: Pokemon*, hp_: felt) -> Pokemon* {
    return (new Pokemon(id=pkmn.id, hp=hp_, atk=pkmn.atk, init=pkmn.init, def=pkmn.def,
        type1=pkmn.type1, type2=pkmn.type2, atk1_type=pkmn.atk1_type,
        atk1_damage=pkmn.atk1_damage, atk2_type=pkmn.atk2_type,
        atk2_damage=pkmn.atk2_damage, name_id=pkmn.name_id));
}

// Takes a max number as a range
// creates a number (r) based on the hash of the current block_timestamp and transaction hash
// returns a (pseudo)random number (r) between 1 and range 1<=r<=range
func get_random{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    range: felt
) -> felt {
    alloc_locals;
    let (n) = nonce.read();

    let (transaction_hash) = get_tx_transaction_hash();
    let (block_timestamp) = get_block_timestamp();
    let x = block_timestamp + n;
    let (rng_hash) = hash2{hash_ptr=pedersen_ptr}(transaction_hash, x);
    nonce.write(value=n + 1);
    let (high, low) = split_felt(rng_hash);
    let (res, r) = unsigned_div_rem(low, range);
    return (r + 1);
}
// Returns the transaction hash

func get_tx_transaction_hash{syscall_ptr: felt*}() -> (transaction_hash: felt) {
    let (tx_info) = get_tx_info();

    return (transaction_hash=tx_info.transaction_hash);
}

// my_dict has key:val pairs {5: 8, 12: 35, 33: 198}.

func get_data() -> (data: felt*) {
    let (data_address) = get_label_location(data_start);
    return (data=cast(data_address, felt*));

    data_start:
    // line 1 normal
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 0;
    dw 1;
    dw 1;
    dw 3;
    dw 1;
    // line 2 fire
    dw 1;
    dw 3;
    dw 3;
    dw 2;
    dw 1;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 3;
    dw 1;
    dw 3;
    dw 1;
    dw 2;
    dw 1;
    // line 3 water
    dw 1;
    dw 2;
    dw 3;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    // line 4 plant
    dw 1;
    dw 3;
    dw 2;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 2;
    dw 3;
    dw 1;
    dw 3;
    dw 2;
    dw 1;
    dw 3;
    dw 1;
    dw 3;
    dw 1;
    // line 5 electro
    dw 1;
    dw 1;
    dw 2;
    dw 3;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    dw 0;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    // line 6 ice
    dw 1;
    dw 3;
    dw 3;
    dw 2;
    dw 1;
    dw 3;
    dw 1;
    dw 1;
    dw 2;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 3;
    dw 1;
    // line 7 fighting
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 3;
    dw 1;
    dw 3;
    dw 3;
    dw 3;
    dw 2;
    dw 0;
    dw 1;
    dw 2;
    dw 2;
    dw 3;
    // line 8 poison
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 3;
    dw 1;
    dw 1;
    dw 0;
    dw 2;
    // line 9 ground
    dw 1;
    dw 2;
    dw 1;
    dw 3;
    dw 2;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 0;
    dw 1;
    dw 3;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    // line 10 flying
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 3;
    dw 1;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 1;
    // line 10 psycho
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 2;
    dw 1;
    dw 1;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 0;
    dw 3;
    dw 1;
    // line 11 bug
    dw 1;
    dw 3;
    dw 1;
    dw 2;
    dw 1;
    dw 1;
    dw 3;
    dw 3;
    dw 1;
    dw 3;
    dw 2;
    dw 1;
    dw 1;
    dw 3;
    dw 1;
    dw 2;
    dw 3;
    dw 3;
    // line 12 rock
    dw 1;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 3;
    dw 1;
    dw 3;
    dw 2;
    dw 1;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 1;
    // line 13 ghost
    dw 0;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 3;
    dw 1;
    dw 1;
    // line 14 dragon
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 3;
    dw 0;
    // line 15 dark
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 3;
    dw 1;
    dw 3;
    // line 16 steel
    dw 1;
    dw 3;
    dw 3;
    dw 1;
    dw 3;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 2;
    // line 16 fairy
    dw 1;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 3;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 1;
    dw 2;
    dw 2;
    dw 3;
    dw 1;
}
@external
func testdw(x: felt) -> (res: felt) {
    let (data) = get_data();

    let value = data[x];

    return (res=value);
}
