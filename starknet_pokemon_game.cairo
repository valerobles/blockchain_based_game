%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_nn
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import get_tx_info
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.hash import hash2

@storage_var
func l1_address() -> (felt,) {
}
@event
func address_set(address: felt) {
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
    return (new Pokemon(id=1, hp=152, atk=111, init=106, def=111, type1='grass', type2='', atk1_type='grass', atk1_damage=30, atk2_type='normal', atk2_damage=40, name_id=1));
}
// create a pokemon for testing purposes
func createPikachu() -> Pokemon* {
    return (new Pokemon(id=2, hp=142, atk=117, init=156, def=101, type1='electro', type2='', atk1_type='electro', atk1_damage=30, atk2_type='normal', atk2_damage=35, name_id=25));
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

func low_param_fight{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_address: felt, fight_id: felt
) {
    alloc_locals;
    fight_steps.emit(step=0);
    local pkmn1: Pokemon* = createBisasam();

    local pkmn2: Pokemon* = createPikachu();
    let (__fp__, _) = get_fp_and_pc();
    fight_steps.emit(step=1);
    let (res) = fight(pkmn1, pkmn2);

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
@event
func fight_steps(step: felt) {
}

// Takes the L1 address, the attributes for two pokemon, and a fight_id
// Saves the fight_id and winner as a mapping in func winner, sends the winner to L1 contract_address

func testfunc{syscall_ptr: felt*, range_check_ptr}(from_address: felt) {
    fight_steps.emit(step=99);
    return ();
}

func testfunc2{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_address: felt
) {
    fight_steps.emit(step=99);
    let (l1_contract_address) = l1_address.read();
    assert from_address = l1_contract_address;
    return ();
}

@external
func sendDummyMessage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (message_payload: felt*) = alloc();
    assert message_payload[0] = 98;
    let (l1_contract_address) = l1_address.read();
    send_message_to_l1(to_address=l1_contract_address, payload_size=1, payload=message_payload);
    return ();
}

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

    //let (res) = winner.read(fight_id=fight_id);
    //let (message_payload: felt*) = alloc();
   // assert message_payload[0] = res;
   // assert message_payload[1] = fight_id;
   // let (l1_contract_address) = l1_address.read();
   // send_message_to_l1(to_address=l1_contract_address, payload_size=2, payload=message_payload);
   // fight_steps.emit(step=3);
    return ();
}

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
        return (res=slower_pkmn.id);
    }

    let (res) = fight(newPok, newPok2);

    return (res=res);
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
    let g = e * (f + 205);
    let (h, r) = unsigned_div_rem(g, 255);
    let (final, r) = unsigned_div_rem(h, 1000);
    return (final);
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
// returns a (pseudo)random number (r) between 1 and range
func get_random{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    range: felt
) -> felt {
    let (transaction_hash) = get_tx_transaction_hash();
    let (block_timestamp) = get_block_timestamp();
    let (rng_hash) = hash2{hash_ptr=pedersen_ptr}(transaction_hash, block_timestamp);
    let (res, r) = unsigned_div_rem(rng_hash, range);
    return (r + 1);
}
// Returns the transaction hash
func get_tx_transaction_hash{syscall_ptr: felt*}() -> (transaction_hash: felt) {
    let (tx_info) = get_tx_info();

    return (transaction_hash=tx_info.transaction_hash);
}
