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


    IStarknetCore starknetCore;
    uint256 nonce = 0;
    uint256 L2_CONTRACT = 0x31c59f9319f22b2dc9271b18bfe67ec3d5464ff8327705891a931875f89b148; //random fixed, with msg to l1 in pokemon_game_flat
    uint256 constant SELECTOR = 1625440424450498852892950090004073452274266572863945925863133186904237482575; // pokemon_game_flat as a selector encoded


    uint256 fightIDCounter = 0;

    Pokemon[] public pokemons; // List of all Pokemon

    mapping(uint256 => Pokemon) public fightIDToWinnerPokemon; // mapping of fight ID to Winner Pokemon
    mapping(uint256 => Fight) public fightIDToFighters;


    // EVENTS
    event startFight(address indexed _from, uint256 _pok1, uint256 _pok2, uint256 l2Contract, uint _value);

    event startFightMessage(uint message);

    event gettingWinnerEntered(uint message);

    event gettingWinnerFinished(uint256 l2contract, uint256 _winnerPok, uint256 _fightID);

    event enteredFunc(uint message);

    event createdRandomPkmn(uint uuid, uint hp, uint atk, uint init, uint def);






    constructor() ERC721("NFT", "CC") {
        starknetCore = IStarknetCore(address(0xde29d060D45901Fb19ED6C6e959EB22d8626708e));
        // https://docs.starknet.io/documentation/Ecosystem/ref_operational_info/
    }



    function mint(uint256 _name_id) public {
        require(_name_id > 0 && _name_id < 650, "Only valid dex numbers. Must be between 1 and 649");

        uint256 _uuid = pokemons.length;
        // TODO: create UUID for unique ID
        Pokemon memory newPok = createPokemonByNameId(_name_id, _uuid);
        pokemons.push(newPok);

        emit createdRandomPkmn(_uuid,newPok.hp,newPok.atk,newPok.init,newPok.def);

        // create Pokemon from json

        // _safeMint method from openzeppelin
        //TODO safe all data in nft
        _safeMint(msg.sender, _uuid);
    }


    // TODO: get data from json
    function createPokemonByNameId(uint256 _name_id, uint256 _id) internal returns (Pokemon memory) {


        if (_name_id == 1) {
            return (createPokemon(_id, 152, 111, 106, 111, 3, 99, 3, 30, getType(), getDamage(), _name_id));
        }
        if (_name_id == 2) {
            return (createPokemon(_id, 167, 125, 123, 126, 3, 7, 3, 40, getType(), getDamage(), _name_id));
        }
        if (_name_id == 3) {
            return (createPokemon(_id, 187, 167, 145, 192, 3, 7, 3, 50, getType(), getDamage(), _name_id));
        }
        if (_name_id == 4) {
            return (createPokemon(_id, 146, 114, 128, 104, 1, 99, 1, 40, getType(), getDamage(), _name_id));
        }
        if (_name_id == 5) {
            return (createPokemon(_id, 165, 127, 145, 121, 1, 99, 1, 40, getType(), getDamage(), _name_id));
        }
        if (_name_id == 6) {
            return (createPokemon(_id, 185, 200, 167, 179, 1, 9, 1, 50, getType(), getDamage(), _name_id));
        }
        if (_name_id == 7) {
            return (createPokemon(_id, 151, 110, 104, 128, 2, 99, 2, 30, getType(), getDamage(), _name_id));
        }
        if (_name_id == 8) {
            return (createPokemon(_id, 166, 126, 121, 145, 2, 99, 2, 40, getType(), getDamage(), _name_id));
        }
        if (_name_id == 9) {
            return (createPokemon(_id, 186, 148, 143, 167, 2, 99, 2, 50, getType(), getDamage(), _name_id));
        }
        if (_name_id == 10) {
            return (createPokemonOther(_id, 11, 99, _name_id, 1));
        }
        if (_name_id == 11) {
            return (createPokemonOther(_id, 11, 99, _name_id, 2));
        }
        if (_name_id == 12) {
            return (createPokemonOther(_id, 11, 9, _name_id, 3));
        }
        if (_name_id == 13) {
            return (createPokemonOther(_id, 11, 7, _name_id,1));
        }
        if (_name_id == 14) {
            return (createPokemonOther(_id, 11, 7, _name_id, 2));
        }
        if (_name_id == 15) {
            return (createPokemonOther(_id, 11, 7, _name_id, 3));
        }
        if (_name_id == 16) {
            return (createPokemonOther(_id, 0, 9, _name_id, 1));
        }
        if (_name_id == 17) {
            return (createPokemonOther(_id, 0, 9, _name_id,2));
        }
        if (_name_id == 18) {
            return (createPokemonOther(_id, 0, 9, _name_id,3));
        }
        if (_name_id == 19) {
            return (createPokemonOther(_id, 0, 99, _name_id,1));
        }
        if (_name_id == 20) {
            return (createPokemonOther(_id, 0, 99, _name_id,2));
        }
        if (_name_id == 21) {
            return (createPokemonOther(_id, 0, 9, _name_id,1));
        }
        if (_name_id == 22) {
            return (createPokemonOther(_id, 0, 9, _name_id,2));
        }
        if (_name_id == 23) {
            return (createPokemonOther(_id, 7, 99, _name_id,1));
        }
        if (_name_id == 24) {
            return (createPokemonOther(_id, 7, 99, _name_id,2));
        }
        if (_name_id == 25) {
            return (createPokemonOther(_id, 4, 99, _name_id,2));
        }
        if (_name_id == 26) {
            return (createPokemonOther(_id, 4, 99, _name_id,3));
        }
        if (_name_id == 27) {
            return (createPokemonOther(_id, 8, 99, _name_id,1));
        }
        if (_name_id == 28) {
            return (createPokemonOther(_id, 8, 99, _name_id,2));
        }
        if (_name_id == 29) {
            return (createPokemonOther(_id, 7, 99, _name_id,1));
        }
        if (_name_id == 30) {
            return (createPokemonOther(_id, 7, 99, _name_id,1));
        }
        if (_name_id == 31) {
            return (createPokemonOther(_id, 7, 8, _name_id,3));
        }
        if (_name_id == 32) {
            return (createPokemonOther(_id, 7, 99, _name_id,1));
        }
        if (_name_id == 33) {
            return (createPokemonOther(_id, 7, 99, _name_id,2));
        }
        if (_name_id == 34) {
            return (createPokemonOther(_id, 7, 8, _name_id,3));
        }
        if (_name_id == 35) {
            return (createPokemonOther(_id, 17, 99, _name_id,1));
        }
        if (_name_id == 36) {
            return (createPokemonOther(_id, 17, 99, _name_id,2));
        }
        if (_name_id == 37) {
            return (createPokemonOther(_id, 1, 99, _name_id,2));
        }
        if (_name_id == 38) {
            return (createPokemonOther(_id, 1, 99, _name_id,3));
        }
        if (_name_id == 39) {
            return (createPokemonOther(_id, 0, 17, _name_id,1));
        }
        if (_name_id == 40) {
            return (createPokemonOther(_id, 0, 17, _name_id,2));
        }
        if (_name_id == 41) {
            return (createPokemonOther(_id, 7, 9, _name_id,1));
        }
        if (_name_id == 42) {
            return (createPokemonOther(_id, 7, 9, _name_id,2));
        }
        if (_name_id == 43) {
            return (createPokemonOther(_id, 3, 7, _name_id,1));
        }
        if (_name_id == 44) {
            return (createPokemonOther(_id, 3, 7, _name_id,2));
        }
        if (_name_id == 45) {
            return (createPokemonOther(_id, 3, 7, _name_id,3));
        }
        if (_name_id == 46) {
            return (createPokemonOther(_id, 11, 3, _name_id,1));
        }
        if (_name_id == 47) {
            return (createPokemonOther(_id, 11, 3, _name_id,2));
        }
        if (_name_id == 48) {
            return (createPokemonOther(_id, 11, 7, _name_id,1));
        }
        if (_name_id == 49) {
            return (createPokemonOther(_id, 11, 7, _name_id,3));
        }
        if (_name_id == 50) {
            return (createPokemonOther(_id, 8, 99, _name_id,2));
        }
        if (_name_id == 51) {
            return (createPokemonOther(_id, 8, 99, _name_id,3));
        }
        if (_name_id == 52) {
            return (createPokemonOther(_id, 0, 99, _name_id,2));
        }
        else {
            return (createPokemonOther(_id, 0, 99, _name_id, getStrength()));
        }

    }


    function getType() internal returns (uint) {
        return random(17);
    }

    function getDamage() internal returns (uint) {
        return random(50) + 40;
    }
    function getStrength() internal returns (uint) {
        return random(2) + 1;
    }

    //Every pokemon gets random bonus stats on every stat
    function createPokemon(uint256 id, uint256 hp, uint256 atk, uint256 init, uint256 def, uint256 type1, uint256 type2, uint256 atk1_type, uint256 atk1_damage, uint256 atk2_type, uint256 atk2_damage, uint256 name_id) internal returns (Pokemon memory){
        return Pokemon(id, hp + getDv(), atk + getDv(), init + getDv(), def + getDv(), type1, type2, atk1_type, atk1_damage, atk2_type, atk2_damage, name_id);
    }

    //Every pokemon gets random bonus stats on every stat
    function createPokemonOther(uint256 id, uint256 strength ,uint256 type1, uint256 type2, uint256 name_id) internal returns (Pokemon memory){
        uint256 base_stat = 100;

        if (strength == 2){
            base_stat += 20;
        }
        if (strength == 3){
            base_stat += 50;
        }
        if (strength == 4){
            base_stat += 70;
        }

        return Pokemon(id, base_stat + getDv(), base_stat + getDv(), base_stat + getDv(), base_stat + getDv(), type1, type2, type1, getDamage(), getType(), getDamage(), name_id);
    }

    function getDv() internal returns (uint) {
        return random(20);
    }

    function random(uint _interval) internal returns (uint) {
        nonce++;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce))) % _interval;
    }

    // override method from ERC721, ERC721Enumerable
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override (ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // override method from ERC721, ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override (ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }




    // L1 L2 Handlers



    // L1 -> L2. Send 2 pokemon to fight to L2
    function sendPokemonsToL2(
        uint256 myPok,
        uint256 enemyPok
    ) external payable {

        require(ownerOf(myPok) == msg.sender); // myPok has to be from the sender
        assert(myPok < totalSupply());
        assert(enemyPok < totalSupply());


        emit startFightMessage(1);

        Pokemon memory pok1 = pokemons[myPok];
        Pokemon memory pok2 = pokemons[enemyPok];
        uint256 fight_ID = createFightID();

        emit startFightMessage(2);

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

        emit startFightMessage(3);

        // Send the message to the StarkNet core contract, passing any value that was
        // passed to us as message fee.
        starknetCore.sendMessageToL2{value : msg.value}(
            L2_CONTRACT,
            SELECTOR,
            payload
        );

        fightIDToFighters[fight_ID] = Fight(pok1,pok2);
        emit startFight(msg.sender, pok1.id, pok2.id, L2_CONTRACT, msg.value);
    }


    function createFightID() private returns (uint256) {
        return fightIDCounter++;
    }



    // L2 -> L1. Recieve winner from L2
    function get_winner(
        uint256 pokemonWinnerID,
        uint256 fightID
    ) external {

        emit gettingWinnerEntered(11111);

        uint256[] memory payload = new uint256[](2);
        payload[0] = pokemonWinnerID;
        payload[1] = fightID;


        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(L2_CONTRACT, payload);

        // Update the L1 balance.
        fightIDToWinnerPokemon[fightID] = pokemons[pokemonWinnerID];

        emit gettingWinnerFinished(L2_CONTRACT, pokemonWinnerID, fightID);


    }

}