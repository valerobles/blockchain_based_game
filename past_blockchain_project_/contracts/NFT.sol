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


    IStarknetCore starknetCore;
    uint256 nonce = 0;
    uint256 L2_CONTRACT = 0x23dffb3e5bd1ebba20bf94b5fe7d6eedd205b505275353a91c7090c3d47c2d5; //random fixed, with msg to l1 in pokemon_game_flat
    uint256 constant SELECTOR = 1625440424450498852892950090004073452274266572863945925863133186904237482575; // pokemon_game_flat as a selector encoded


    uint256 fightIDCounter = 0;

    Pokemon[] public pokemons; // List of all Pokemon

    mapping(uint256 => Pokemon) public fightIDToWinnerPokemon; // mapping of fight ID to Winner Pokemon


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
            return (createPokemon(_id, 152, 111, 106, 111, 8, 0, 8, 30, 11, 40, _name_id));
        }
        if (_name_id == 2) {
            return (createPokemon(_id, 167, 125, 123, 126, 8, 12, 8, 40, 12, 50, _name_id));
        }
        if (_name_id == 3) {
            return (createPokemon(_id, 187, 167, 145, 192, 8, 12, 8, 50, 12, 60, _name_id));
        }
        if (_name_id == 4) {
            return (createPokemon(_id, 146, 114, 128, 104, 5, 0, 5, 40, 12, 50, _name_id));
        }
        if (_name_id == 5) {
            return (createPokemon(_id, 165, 127, 145, 121, 5, 0, 5, 40, 12, 50, _name_id));
        }
        if (_name_id == 6) {
            return (createPokemon(_id, 185, 200, 167, 179, 5, 6, 5, 50, 6, 60, _name_id));
        }
        if (_name_id == 7) {
            return (createPokemon(_id, 151, 110, 104, 128, 15, 0, 15, 30, 11, 40, _name_id));
        }
        if (_name_id == 8) {
            return (createPokemon(_id, 166, 126, 121, 145, 15, 0, 15, 40, 11, 50, _name_id));
        }
        if (_name_id == 9) {
            return (createPokemon(_id, 186, 148, 143, 167, 15, 0, 15, 50, 10, 60, _name_id));
        }
        else {
            return (createPokemon(_id, 142, 117, 156, 101, 3, 0, 3, 30, 11, 35, _name_id));
        }

    }
    //Every pokemon gets random bonus stats on every stat
    function createPokemon(uint256 id, uint256 hp, uint256 atk, uint256 init, uint256 def, uint256 type1, uint256 type2, uint256 atk1_type, uint256 atk1_damage, uint256 atk2_type, uint256 atk2_damage, uint256 name_id) internal returns (Pokemon memory){
        return Pokemon(id, hp + getDv(), atk + getDv(), init + getDv(), def + getDv(), type1, type2, atk1_type, atk1_damage, atk2_type, atk2_damage, name_id);
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



    // L2 -> L1 test
    function sendDummyMessage(uint256 test_num) external {

        emit enteredFunc(777);

        uint256[] memory payload = new uint256[](1);
        payload[0] = test_num;


        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(L2_CONTRACT, payload);

        emit enteredFunc(test_num);


    }
}