import os
import pytest

from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "starknet_pokemon_game.cairo")

@pytest.mark.asyncio
async def test_efficiency():
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

   # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    fight = await contract.no_param_fight().call()
    assert fight.result[0] == 1111
    zeroDmgFight = await contract.no_param_fight_zerodmg().call()
    assert zeroDmgFight.result[0] == 1111111111
