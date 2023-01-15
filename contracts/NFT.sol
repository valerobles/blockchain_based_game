pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";

// Starknet Interface
interface IStarknetCore {
    /**
      Sends a message to an L2 contract.
      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external payable returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.
      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
    external
    returns (bytes32);

}


contract NFT is ERC721, ERC721Enumerable {

    // Structs

    struct Pokemon {
        uint256 id;
        uint256 hp;
        uint256 atk;
        uint256 init;
        uint256 def;
        uint256 type1;
        uint256 type2;
        uint256 atk1_type;
        uint256 atk1_damage;
        uint256 atk2_type;
        uint256 atk2_damage;
        uint256 name_id;

    }

    struct Fight{
        Pokemon pok1;
        Pokemon pok2;
    }

    // ______________________________________________________________________________________________________________________________

    // Variables

    IStarknetCore starknetCore;

    // Variables needed for L2 interaction
    uint256 L2_CONTRACT = 0x00b19ed1fb6e07d84d9b879743cac13c79b344777ca7e6393c9612b214886ded; // L2 contract address
    uint256 constant SELECTOR= 1287792748861478314957917789548421785918690629705705918786662048852425233154; //pokemon_game method as a selector encoded


    uint256 fightIDCounter = 0;
    uint256 nonce = 0; // needed for creating random numbers
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    Pokemon[] public pokemons; // List of all Pokemon
    // ______________________________________________________________________________________________________________________________
    // Pokemon types

    uint256 constant NORMAL = 0;
    uint256 constant FIRE = 1;
    uint256 constant WATER = 2;
    uint256 constant GRASS = 3;
    uint256 constant ELECTRO = 4;
    uint256 constant ICE = 5;
    uint256 constant FIGHTING = 6;
    uint256 constant POISON = 7;
    uint256 constant GROUND = 8;
    uint256 constant FLYING = 9;
    uint256 constant PSYCHO = 10;
    uint256 constant BUG = 11;
    uint256 constant ROCK = 12;
    uint256 constant GHOST = 13;
    uint256 constant DRAGON = 14;
    uint256 constant DARK = 15;
    uint256 constant STEEL = 16;
    uint256 constant FAIRY = 17;
    uint256 constant NONE = 99;


    // ______________________________________________________________________________________________________________________________

    // Mappings

    mapping(uint256 => Pokemon) public fightIDToWinnerPokemon; // mapping of fight ID to Winner Pokemon
    mapping(uint256 => Fight) public fightIDToFighters; //  mapping of fight ID to Fight struct (two fighting pokemon)
    mapping(uint256 => uint256) public pokemonIDToFightsWon; // mapping of pokemon ID to number of rounds won

    // ______________________________________________________________________________________________________________________________


    //NFT name and Symbol
    constructor() ERC721("PokemonNFT", "PKMN") {
        // setting StarknetCore Contract address
        starknetCore = IStarknetCore(address(0xde29d060D45901Fb19ED6C6e959EB22d8626708e));
    }

    // _________________________________________________________________________________________________________________________________
    // method that need to be overriden for ERC721, ERC721Enumerable

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override (ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override (ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    // _________________________________________________________________________________________________________________________________
    // Creating Pokemon methods


    // Mint function. Recieves name_id of pokemon
    function mint(uint256 _name_id) public {

        require(_name_id > 0 && _name_id < 53, "Only valid dex numbers. Must be between 1 and 52");

        uint256 _id = _tokenIds.current();

        // create pokemon struct from name_id
        Pokemon memory newPok = createPokemonByNameId(_name_id, _id);
        pokemons.push(newPok);


        // _safeMint method from openzeppelin
        // makes sure that NFT is of ERC721 standard
        _safeMint(msg.sender, _id);

        _tokenIds.increment();
    }


    // Create Pokemon depending on given name_id
    function createPokemonByNameId(uint256 _name_id, uint256 _id) internal returns (Pokemon memory) {

        if (_name_id == 1) {
            return (createPokemon(_id, 152, 111, 106, 111, GRASS, POISON, GRASS, 30, getType(), getDamage(), _name_id));
        }
        if (_name_id == 2) {
            return (createPokemon(_id, 167, 125, 123, 126, GRASS, POISON, GRASS, 40, getType(), getDamage(), _name_id));
        }
        if (_name_id == 3) {
            return (createPokemon(_id, 187, 167, 145, 192, GRASS, POISON, GRASS, 50, getType(), getDamage(), _name_id));
        }
        if (_name_id == 4) {
            return (createPokemon(_id, 146, 114, 128, 104, FIRE, NONE, FIRE, 40, getType(), getDamage(), _name_id));
        }
        if (_name_id == 5) {
            return (createPokemon(_id, 165, 127, 145, 121, FIRE, NONE, FIRE, 40, getType(), getDamage(), _name_id));
        }
        if (_name_id == 6) {
            return (createPokemon(_id, 185, 200, 167, 179, FIRE, FLYING, FIRE, 50, getType(), getDamage(), _name_id));
        }
        if (_name_id == 7) {
            return (createPokemon(_id, 151, 110, 104, 128, WATER, NONE, WATER, 30, getType(), getDamage(), _name_id));
        }
        if (_name_id == 8) {
            return (createPokemon(_id, 166, 126, 121, 145, WATER, NONE, WATER, 40, getType(), getDamage(), _name_id));
        }
        if (_name_id == 9) {
            return (createPokemon(_id, 186, 148, 143, 167, WATER, NONE, WATER, 50, getType(), getDamage(), _name_id));
        }
        // Only types and strength are accurate
        if (_name_id == 10) {
            return (createPokemonOther(_id, BUG, NONE, _name_id, 1));
        }
        if (_name_id == 11) {
            return (createPokemonOther(_id, BUG, NONE, _name_id, 2));
        }
        if (_name_id == 12) {
            return (createPokemonOther(_id, BUG, FLYING, _name_id, 3));
        }
        if (_name_id == 13) {
            return (createPokemonOther(_id, BUG, POISON, _name_id, 1));
        }
        if (_name_id == 14) {
            return (createPokemonOther(_id, BUG, POISON, _name_id, 2));
        }
        if (_name_id == 15) {
            return (createPokemonOther(_id, BUG, POISON, _name_id, 3));
        }
        if (_name_id == 16) {
            return (createPokemonOther(_id, NORMAL, FLYING, _name_id, 1));
        }
        if (_name_id == 17) {
            return (createPokemonOther(_id, NORMAL, FLYING, _name_id, 2));
        }
        if (_name_id == 18) {
            return (createPokemonOther(_id, NORMAL, FLYING, _name_id, 3));
        }
        if (_name_id == 19) {
            return (createPokemonOther(_id, NORMAL, NONE, _name_id, 1));
        }
        if (_name_id == 20) {
            return (createPokemonOther(_id, NORMAL, NONE, _name_id, 2));
        }
        if (_name_id == 21) {
            return (createPokemonOther(_id, NORMAL, FLYING, _name_id, 1));
        }
        if (_name_id == 22) {
            return (createPokemonOther(_id, NORMAL, FLYING, _name_id, 2));
        }
        if (_name_id == 23) {
            return (createPokemonOther(_id, POISON, NONE, _name_id, 1));
        }
        if (_name_id == 24) {
            return (createPokemonOther(_id, POISON, NONE, _name_id, 2));
        }
        if (_name_id == 25) {
            return (createPokemonOther(_id, ELECTRO, NONE, _name_id, 2));
        }
        if (_name_id == 26) {
            return (createPokemonOther(_id, ELECTRO, NONE, _name_id, 3));
        }
        if (_name_id == 27) {
            return (createPokemonOther(_id, GROUND, NONE, _name_id, 1));
        }
        if (_name_id == 28) {
            return (createPokemonOther(_id, GROUND, NONE, _name_id, 2));
        }
        if (_name_id == 29) {
            return (createPokemonOther(_id, POISON, NONE, _name_id, 1));
        }
        if (_name_id == 30) {
            return (createPokemonOther(_id, POISON, NONE, _name_id, 1));
        }
        if (_name_id == 31) {
            return (createPokemonOther(_id, POISON, GROUND, _name_id, 3));
        }
        if (_name_id == 32) {
            return (createPokemonOther(_id, POISON, NONE, _name_id, 1));
        }
        if (_name_id == 33) {
            return (createPokemonOther(_id, POISON, NONE, _name_id, 2));
        }
        if (_name_id == 34) {
            return (createPokemonOther(_id, POISON, GROUND, _name_id, 3));
        }
        if (_name_id == 35) {
            return (createPokemonOther(_id, FAIRY, NONE, _name_id, 1));
        }
        if (_name_id == 36) {
            return (createPokemonOther(_id, FAIRY, NONE, _name_id, 2));
        }
        if (_name_id == 37) {
            return (createPokemonOther(_id, FIRE, NONE, _name_id, 2));
        }
        if (_name_id == 38) {
            return (createPokemonOther(_id, FIRE, NONE, _name_id, 3));
        }
        if (_name_id == 39) {
            return (createPokemonOther(_id, NORMAL, FAIRY, _name_id, 1));
        }
        if (_name_id == 40) {
            return (createPokemonOther(_id, NORMAL, FAIRY, _name_id, 2));
        }
        if (_name_id == 41) {
            return (createPokemonOther(_id, POISON, FLYING, _name_id, 1));
        }
        if (_name_id == 42) {
            return (createPokemonOther(_id, POISON, FLYING, _name_id, 2));
        }
        if (_name_id == 43) {
            return (createPokemonOther(_id, GRASS, POISON, _name_id, 1));
        }
        if (_name_id == 44) {
            return (createPokemonOther(_id, GRASS, POISON, _name_id, 2));
        }
        if (_name_id == 45) {
            return (createPokemonOther(_id, GRASS, POISON, _name_id, 3));
        }
        if (_name_id == 46) {
            return (createPokemonOther(_id, BUG, GRASS, _name_id, 1));
        }
        if (_name_id == 47) {
            return (createPokemonOther(_id, BUG, GRASS, _name_id, 2));
        }
        if (_name_id == 48) {
            return (createPokemonOther(_id, BUG, POISON, _name_id, 1));
        }
        if (_name_id == 49) {
            return (createPokemonOther(_id, BUG, POISON, _name_id, 3));
        }
        if (_name_id == 50) {
            return (createPokemonOther(_id, GROUND, NONE, _name_id, 2));
        }
        if (_name_id == 51) {
            return (createPokemonOther(_id, GROUND, NONE, _name_id, 3));
        }
        if (_name_id == 52) {
            return (createPokemonOther(_id, NORMAL, NONE, _name_id, 2));
        } else {
            revert();
        }


    }



    // Create pokemon struct
    //Every pokemon gets random bonus stats on every stat
    function createPokemon(uint256 id, uint256 hp, uint256 atk, uint256 init, uint256 def, uint256 type1, uint256 type2, uint256 atk1_type, uint256 atk1_damage, uint256 atk2_type, uint256 atk2_damage, uint256 name_id) internal returns (Pokemon memory){
        return Pokemon(id, hp + getDv(), atk + getDv(), init + getDv(), def + getDv(), type1, type2, atk1_type, atk1_damage, atk2_type, atk2_damage, name_id);
    }

    // Create pokemon struct from minimalized stats and adjusted depending on strength given
    //Every pokemon gets random bonus stats on every stat
    function createPokemonOther(uint256 id, uint256 type1, uint256 type2, uint256 name_id, uint256 strength) internal returns (Pokemon memory){
        uint256 base_stat = 100;

        if (strength == 2) {
            base_stat += 20;
        }
        if (strength == 3) {
            base_stat += 50;
        }
        if (strength == 4) {
            base_stat += 70;
        }

        return Pokemon(id, base_stat + getDv(), base_stat + getDv(), base_stat + getDv(), base_stat + getDv(), type1, type2, type1, getDamage(), getType(), getDamage(), name_id);
    }

    // _________________________________________________________________________________________________________________________________

    // Get random number methods

    function getDv() internal returns (uint) {
        return random(20);
    }

    function getType() internal returns (uint) {
        return random(17);
    }

    function getDamage() internal returns (uint) {
        return random(50) + 40;
    }


    function random(uint _interval) internal returns (uint) {
        nonce++;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce))) % _interval;
    }



    // _________________________________________________________________________________________________________________________________

    // L1 <-> L2 methods



    // L1 -> L2. Send two pokemon to fight to L2.
    // Is payable since the fee must be transferred to StarkNet to process this transaction
    function sendPokemonsToL2(
        uint256 myPok,
        uint256 enemyPok
    ) external payable {
        require(myPok != enemyPok);
        require(msg.value>= 20000000000000000);
        require(ownerOf(myPok) == msg.sender); // myPok has to be from the sender
        require(ownerOf(enemyPok) != address(0)); // check if NFT exists



        Pokemon memory pok1 = pokemons[myPok];
        Pokemon memory pok2 = pokemons[enemyPok];
        uint256 fight_ID = createFightID();


        // Construct the message's payload.
        uint256[] memory payload = new uint256[](25);
        payload[0] = pok1.id;
        payload[1] = pok1.hp;
        payload[2] = pok1.atk;
        payload[3] = pok1.init;
        payload[4] = pok1.def;
        payload[5] = pok1.type1;
        payload[6] = pok1.type2;
        payload[7] = pok1.atk1_type;
        payload[8] = pok1.atk1_damage;
        payload[9] = pok1.atk2_type;
        payload[10] = pok1.atk2_damage;
        payload[11] = pok1.name_id;

        payload[12] = pok2.id;
        payload[13] = pok2.hp;
        payload[14] = pok2.atk;
        payload[15] = pok2.init;
        payload[16] = pok2.def;
        payload[17] = pok2.type1;
        payload[18] = pok2.type2;
        payload[19] = pok2.atk1_type;
        payload[20] = pok2.atk1_damage;
        payload[21] = pok2.atk2_type;
        payload[22] = pok2.atk2_damage;
        payload[23] = pok2.name_id;

        payload[24] = fight_ID;


        // Send the message to the StarkNet core contract, passing any value that was
        // passed as message fee.
        starknetCore.sendMessageToL2{value : msg.value}(
            L2_CONTRACT,
            SELECTOR,
            payload
        );

        fightIDToFighters[fight_ID] = Fight(pok1,pok2);

    }


    // L2 -> L1. Consume winner from L2
    function consumeMessage(
        uint256 pokemonWinnerID,
        uint256 fightID,
        uint256 effFast,
        uint256 effSlow
    ) external {


        uint256[] memory payload = new uint256[](4);
        payload[0] = pokemonWinnerID;
        payload[1] = fightID;
        payload[2] = effFast;
        payload[3] = effSlow;


        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(L2_CONTRACT, payload);

        // Update the L1 states.
        fightIDToWinnerPokemon[fightID] = pokemons[pokemonWinnerID];

        pokemonIDToFightsWon[pokemonWinnerID] = pokemonIDToFightsWon[pokemonWinnerID] + 1;


    }


    // _________________________________________________________________________________________________________________________________

    // Helper methods

    function createFightID() private returns (uint256) {
        return fightIDCounter++;
    }

}




