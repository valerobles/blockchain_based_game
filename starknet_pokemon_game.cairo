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
from starkware.cairo.common.pow import pow
from starkware.cairo.common.registers import get_label_location

// ------------------------------------------------------------------------------------------------------------------------
// Storage vars

@storage_var
func l1_address() -> (felt,) {
}
@storage_var
func nonce() -> (felt,) {
}

// Mapping to save the id of the winning pokemon for each fight_id
@storage_var
func winner(fight_id: felt) -> (winner_id: felt) {
}


// ------------------------------------------------------------------------------------------------------------------------
// Setter for L1 address
@external
func set_l1_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    l1_address.write(address);
    return ();
}

// ------------------------------------------------------------------------------------------------------------------------
// Struct

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
}

// ------------------------------------------------------------------------------------------------------------------------
// Functions for testing

// create a pokemon for testing purposes
func createBisasam() -> Pokemon* {
    return (
        new Pokemon(
            id=2,
            hp=152,
            atk=111,
            init=106,
            def=111,
            type1=1,
            type2=2,
            atk1_type=1,
            atk1_damage=40,
            atk2_type=1,
            atk2_damage=40,
            name_id=1,
        )
    );
}
// create a pokemon for testing purposes
func createPikachu() -> Pokemon* {
    return (
        new Pokemon(
            id=3,
            hp=142,
            atk=117,
            init=156,
            def=101,
            type1=1,
            type2=2,
            atk1_type=1,
            atk1_damage=40,
            atk2_type=1,
            atk2_damage=40,
            name_id=25,
        )
    );
}
// create a pokemon for testing purposes
func createKakuna() -> Pokemon* {
    return (
        new Pokemon(
            id=0,
            hp=154,
            atk=159,
            init=167,
            def=157,
            type1=11,
            type2=9,
            atk1_type=11,
            atk1_damage=61,
            atk2_type=1,
            atk2_damage=44,
            name_id=12,
        )
    );
}
// create a pokemon for testing purposes
func createFearow() -> Pokemon* {
    return (
        new Pokemon(
            id=1,
            hp=116,
            atk=111,
            init=113,
            def=105,
            type1=7,
            type2=9,
            atk1_type=7,
            atk1_damage=75,
            atk2_type=14,
            atk2_damage=54,
            name_id=41,
        )
    );
}
// create a pokemon for testing purposes
func createBisasamZero() -> Pokemon* {
    return (
        new Pokemon(
            id=4,
            hp=152,
            atk=111,
            init=106,
            def=111,
            type1=0,
            type2=99,
            atk1_type=13,
            atk1_damage=40,
            atk2_type=13,
            atk2_damage=40,
            name_id=1,
        )
    );
}
// create a pokemon for testing purposes
func createPikachuZero() -> Pokemon* {
    return (
        new Pokemon(
            id=5,
            hp=142,
            atk=117,
            init=156,
            def=101,
            type1=0,
            type2=99,
            atk1_type=0,
            atk1_damage=40,
            atk2_type=0,
            atk2_damage=40,
            name_id=25,
        )
    );
}

// fight without params, returns history of winner
@external
func no_param_fight{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    winner: felt
) {
    let (res, e1, e2, counter) = fight(createKakuna(), createFearow(), 0, 0, -1);


    return (winner=res);
}
// fight with pokemon that can do zero damage (dmg) to eachother -> type1 & atk_dmg = 0
@external
func no_param_fight_zerodmg{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    winner: felt
) {
    let (res, e1, e2, counter) = fight(createBisasamZero(), createPikachuZero(), 0, 0, -1);

    return (winner=res);
}

// ------------------------------------------------------------------------------------------------------------------------
// Functions to interact with l1

// Takes the L1 address, the attributes for two pokemon, and a fight_id
// Saves the fight_id and winner as a mapping in func winner, sends the winner to L1 contract_address
@l1_handler
func pokemon_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_address: felt, pkmn1: Pokemon, pkmn2: Pokemon, fight_id: felt
) {
    // Get values of the fp register.
    let (__fp__, _) = get_fp_and_pc();

    let (l1_contract_address) = l1_address.read();
    assert from_address = l1_contract_address;
    let (res, e1, e2, counter) = fight(&pkmn1, &pkmn2, 0, 0, -1);
    // save winner in map
    winner.write(fight_id, res);
    // reading storage vars for l1 payload
    let (res) = winner.read(fight_id=fight_id);
    // Filling payload to send to L1
    let (message_payload: felt*) = alloc();
    assert message_payload[0] = res;
    assert message_payload[1] = fight_id;
    assert message_payload[2] = e1;
    assert message_payload[3] = e2;
    let (l1_contract_address) = l1_address.read();
    send_message_to_l1(to_address=l1_contract_address, payload_size=4, payload=message_payload);

    return ();
}

// Takes a fight_id
// Returns the winner of that fight
@view
func get_winner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fight_id: felt
) -> (winner: felt) {
    let (res) = winner.read(fight_id=fight_id);
    return (winner=res);
}

// ------------------------------------------------------------------------------------------------------------------------
// Internal functions for fighting

// Takes two pokemon struct to fight
// Pokemon take turns to deal damage to eachother, until one of them has 0 HP
// Returns the ID of the winning pokemon
func fight{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pkmn1: Pokemon*, pkmn2: Pokemon*, fasterEfficiency: felt, slowerEfficiency: felt, counter: felt
) -> (res: felt, fasterEfficiency: felt, slowerEfficiency: felt, counter: felt) {
    alloc_locals;
    // Count attacks for testing & for calculating length of efficiency payload variable
    let n = counter + 1;

    // Check who is faster
    local faster_pkmn: Pokemon*;
    local slower_pkmn: Pokemon*;
    if (is_le(pkmn1.init, pkmn2.init) == 0) {
        faster_pkmn = pkmn1;
        slower_pkmn = pkmn2;
    } else {
        faster_pkmn = pkmn2;
        slower_pkmn = pkmn1;
    }
    // End if one Pokemon is below 0
    if (is_le(faster_pkmn.hp, 0) == 1) {
        return (
            res=slower_pkmn.id,
            fasterEfficiency=fasterEfficiency,
            slowerEfficiency=slowerEfficiency,
            counter=n,
        );
    }
    if (is_le(slower_pkmn.hp, 0) == 1) {
        return (
            res=faster_pkmn.id,
            fasterEfficiency=fasterEfficiency,
            slowerEfficiency=slowerEfficiency,
            counter=n,
        );
    }

    let (newPok, fasterEfficiencyOut) = dealDmgAndCalcEfficiency(
        faster_pkmn, slower_pkmn, fasterEfficiency, n
    );
    // if new HP value less 0 -> fight over
    if (is_le(newPok.hp, 0) == 1) {
        return (
            res=faster_pkmn.id,
            fasterEfficiency=fasterEfficiencyOut,
            slowerEfficiency=slowerEfficiency,
            counter=n,
        );
    } else {
        // Slower pkmn gets to attack
        let (newPok2, slowerEfficiencyOut) = dealDmgAndCalcEfficiency(
            slower_pkmn, faster_pkmn, slowerEfficiency, n
        );
        // if faster is dead end, else start new fight round
        if (is_le(newPok2.hp, 0) == 1) {
            return (
                res=slower_pkmn.id,
                fasterEfficiency=fasterEfficiencyOut,
                slowerEfficiency=slowerEfficiencyOut,
                counter=n,
            );
        } else {
            let (res, e1, e2, counterNew) = fight(
                newPok, newPok2, fasterEfficiencyOut, slowerEfficiencyOut, n
            );
            return (res=res, fasterEfficiency=e1, slowerEfficiency=e2, counter=counterNew);
        }
    }
}
func dealDmgAndCalcEfficiency{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    pkmn_attacking: Pokemon*, pkmn_defending: Pokemon*, attacking_efficiency: felt, counter: felt
) -> (Pokemon*, felt) {
    alloc_locals;
    // Coinflip for which attack to use for the faster pkmn
    let coinflip1 = get_random(2);
    local atk_damage_fast: felt;
    local atk_type_fast: felt;
    if (coinflip1 == 1) {
        atk_damage_fast = pkmn_attacking.atk1_damage;
        atk_type_fast = pkmn_attacking.atk1_type;
    } else {
        atk_damage_fast = pkmn_attacking.atk2_damage;
        atk_type_fast = pkmn_attacking.atk2_type;
    }
    // Calculate dmg of faster pkmn attacking slower pkmn
    let _dmgx = attackAndGetDamage(pkmn_attacking, atk_type_fast, atk_damage_fast, pkmn_defending);
    local dmg = _dmgx;
    // calculate new (health points) HP
    local pkmn2_hp: felt;
    // Get efficiency without previous dmg to save to fight history
    let (_, z) = getDmgAndEfficiency(atk_type_fast, pkmn_defending.type1, pkmn_defending.type2, 1);
    let (mul) = pow(10, counter);
    local mull = mul;
    local newEff: felt;
    local currentHPSlower = pkmn_defending.hp;
    if (z == 0) {
        // change 0 to 6 because can't multiply 0*10
        newEff = mull * 6;
        // -1 to prevent endless fights if dmg is 0
        pkmn2_hp = currentHPSlower - 1;
    } else {
        newEff = z * mull;
        pkmn2_hp = currentHPSlower - dmg;
    }
    // Save efficiency of attack history
    let efficiencyOut = attacking_efficiency + newEff;
    // Set new health points
    let newPok_: Pokemon* = updateHP(pkmn_defending, pkmn2_hp);
    local newPok: Pokemon* = newPok_;
    return (newPok, efficiencyOut);
}

// Takes an attacking pokemon, it's attack type, it's attack damage and a defending pokemon
// Returns the damage dealt to the defending pokemon
func attackAndGetDamage{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    pkmn1: Pokemon*, atk_type: felt, atk_damage: felt, pkmn2: Pokemon*
) -> felt {
    alloc_locals;
    // Damage formula = (((2* 50000 *crit) / 5  * AttackDamage * Attack.Pok1 / Defense.Pok2) / 50 )
    // * STAB * effeciency * random
    // Apply above formula
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
    // increase level by 1000 to prevent rounding issues
    let level = 50*1000;
    let rand1 = get_random(2);
    let a = 2 * level * rand1;
    let (crit, r) = unsigned_div_rem(a, 5);
    let b = crit * atk_damage * pkmn1.atk;
    let (c, r) = unsigned_div_rem(b, pkmn2.def);
    let (d, r) = unsigned_div_rem(c, 50);
    let e = d * stab;
    let f = get_random(50);
    let (z, _) = getDmgAndEfficiency(atk_type, pkmn2.type1, pkmn2.type2, e);
    let g = z * (f + 205);
    let (h, r) = unsigned_div_rem(g, 255);

    // divide by 1000 again to get correct number
    let (final, r) = unsigned_div_rem(h, 1000);
    return (final);
}
// return dmg multiplied by efficiency, external for testing
@external
func getDmgAndEfficiency{syscall_ptr: felt*, range_check_ptr}(
    atk_type: felt, type1: felt, type2: felt, dmg: felt
) -> (res: felt, efficiency: felt) {
    alloc_locals;
    local z: felt;
    let (data) = get_data();
    let index = (atk_type) * 18 + type1;
    let efficiency1 = data[index];
    local efficiency2: felt;
    // if type2 is not "none"
    if (type2 != 99) {
        let index2 = (atk_type) * 18 + type2;
        let efficiency2temp = data[index2];
        if (efficiency2temp == 0) {
            efficiency2 = 0;
        }
        if (efficiency2temp == 2) {
            efficiency2 = 2;
        } else {
            if (efficiency2temp == 3) {
                efficiency2 = 3;
            } else {
                efficiency2 = 1;
            }
        }
    } else {
        efficiency2 = 1;
    }
    local total_efficiency: felt;
    if (efficiency1 != 3) {
        if (efficiency2 != 3) {
            total_efficiency = efficiency1 * efficiency2;
            z = dmg * total_efficiency;
        }
    }
    // calculate previous dmg divided by 4 or 2
    let (quotient_four, remain) = unsigned_div_rem(dmg, 4);
    let (quotient_two, remain) = unsigned_div_rem(dmg, 2);
    if (efficiency1 == 3) {
        if (efficiency2 == 3) {
            // divided by 4
            total_efficiency = 5;
            z = quotient_four;
        }
        if (efficiency2 == 0) {
            // times 0
            total_efficiency = 0;
            z = 0;
        }
        if (efficiency2 == 2) {
            // times 1
            total_efficiency = 1;
            z = dmg;
        }
        if (efficiency2 == 1) {
            // divided by 2
            total_efficiency = 3;
            z = quotient_two;
        }
    }
    if (efficiency2 == 3) {
        if (efficiency1 == 0) {
            // times 0
            total_efficiency = 0;
            z = 0;
        }
        if (efficiency1 == 2) {
            // times 1
            total_efficiency = 1;
            z = dmg;
        }
        if (efficiency1 == 1) {
            // divided by  2
            total_efficiency = 3;
            z = quotient_two;
        }
    }
    return (res=z, efficiency=total_efficiency);
}

// Takes a pokemon and a new HP value
// return a new pokemon with the attributes of the old pokemon and the new HP value
func updateHP(pkmn: Pokemon*, hp_: felt) -> Pokemon* {
    return (
        new Pokemon(
            id=pkmn.id,
            hp=hp_,
            atk=pkmn.atk,
            init=pkmn.init,
            def=pkmn.def,
            type1=pkmn.type1,
            type2=pkmn.type2,
            atk1_type=pkmn.atk1_type,
            atk1_damage=pkmn.atk1_damage,
            atk2_type=pkmn.atk2_type,
            atk2_damage=pkmn.atk2_damage,
            name_id=pkmn.name_id,
        )
    );
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
// Table for efficiency, line 1: normal attacks vs all others, line 2: fire attacks vs all others, etc.
// 1: normal eff, 2: double, 0: zero, 3: half
func get_data() -> (data: felt*) {
    let (data_address) = get_label_location(data_start);
    return (data=cast(data_address, felt*));

    data_start:
    // row 1 of 18 normal attacking all types
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
    // line 4 grass
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
    // line 11 psycho
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
    // line 12 bug
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
    // line 13 rock
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
    // line 14 ghost
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
    // line 15 dragon
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
    // line 16 dark
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
    // line 17 steel
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
    // line 18 fairy
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
