# Creates the selector for the function pokmemon_game
from starkware.starknet.compiler.compile import \
    get_selector_from_name

print(get_selector_from_name('pokemon_game'))