import os
import pytest

from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "starknet_pokemon_game.cairo")


@pytest.mark.asyncio
async def test_increase_balance():
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    # Invoke increase_balance() twice.
   # await contract.increase_balance(amount=10).execute()
   # await contract.increase_balance(amount=20).execute()

    # Check the result of get_balance().
   # execution_info = await contract.pokemon_game([id=1, hp=152, atk=111, init=106, def=111, type1=1, type2=0, atk1_type=1, atk1_damage=30, atk2_type=2, atk1_damage=40]).call()
    #new Pokemon(id=1, hp=152, atk=111, init=106, def=111, type1=1, type2=0, atk1_type=1, atk1_damage=30, atk2_type=2, atk2_damage=40)), (new Pokemon(id=2, hp=152, atk=111, init=106, def=111, type1='grass', type2='', atk1_type='grass', atk1_damage=30, atk2_type='normal', atk2_damage=40)
   # execution_info = await contract.pokemon_game( pkmn1.id=1, pkmn1.hp=152, pkmn1.atk=111, pkmn1.init=106, pkmn1.def=111, pkmn1.type1=1, pkmn1.type2=0, pkmn1.atk1_type=1, pkmn1.atk1_damage=30, pkmn1.atk2_type=2, pkmn1.atk1_damage=40, pkmn2.id=25, pkmn2.hp=142, pkmn2.atk=117, pkmn2.init=156, pkmn2.def=101, pkmn2.type1=3, pkmn2.type2=0, pkmn2.atk1_type=3, pkmn2.atk1_damage=30, pkmn2.atk2_type=2, pkmn2.atk2_damage=35).call()

    execution_info = await contract.no_param_fight().call()
    assert execution_info.result == (2,)
