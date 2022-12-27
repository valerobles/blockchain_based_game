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
    #Test quarter efficiency
    quarter = await contract.getDmgAndEfficiency(atk_type=0, type1=12, type2=16, dmg=1).call()
    assert  quarter.result[1] == 5
    #Test half efficiency
    half = await contract.getDmgAndEfficiency(atk_type=1, type1=1, type2=0, dmg=1).call()
    half2 = await contract.getDmgAndEfficiency(atk_type=6, type1=17, type2=1, dmg=1).call()
    assert half.result[1] == 3
    assert half2.result[1] == 3
    #Test zero efficiency
    zero = await contract.getDmgAndEfficiency(atk_type=8, type1=9, type2=99, dmg=1).call()
    assert  zero.result[1] == 0
    #Test neutral efficiency
    neutral1 = await contract.getDmgAndEfficiency(atk_type=0, type1=1, type2=2, dmg=1).call()
    assert  neutral1.result[1] == 1
    neutral2 = await contract.getDmgAndEfficiency(atk_type=2, type1=1, type2=2, dmg=1).call()
    #Test double efficiency
    assert  neutral2.result[1] == 1
    double = await contract.getDmgAndEfficiency(atk_type=2, type1=0, type2=1, dmg=1).call()
    assert  double.result[1] == 2
    #Test quadruple efficiency
    quadruple = await contract.getDmgAndEfficiency(atk_type=4, type1=2, type2=9, dmg=1).call()
    assert  quadruple.result[1] == 4

    fight = await contract.no_param_fight().call()
    assert fight.result == 0
