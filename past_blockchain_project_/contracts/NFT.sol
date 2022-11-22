// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";


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
    Pokemon[] public pokemons;

    IStarknetCore starknetCore;

    uint256 L2_CONTRACT = 0x65ca4f13a991313394d97395bed9e06e80270a0078a9b9a39c841db4a066bed; // TODO: change to l2 contract address

    uint256 fightIDCounter = 0;



    uint256 constant SELECTOR =
    1625440424450498852892950090004073452274266572863945925863133186904237482575; // pokemon_game_flat

    //mapping (uint256 => address) public pokemonToOwner; // Check openzeppelin contract for method
    mapping (uint256 => bool) _PokemonsExists; //only names not in this list can be added new. every name is unique
    mapping (uint256 => Pokemon) public fightIDToWinnerPokemon; // mapping of fight ID to Winner Pokemon

    constructor() ERC721("NFT","CC") {
        starknetCore = IStarknetCore(address(0xde29d060D45901Fb19ED6C6e959EB22d8626708e)); // TODO
    }



    function mint(uint256  _name_id) public {
       // require(!_PokemonsExists[_name_id]);
        uint256 _uuid = pokemons.length; // TODO: create UUID for unique ID

        pokemons.push(getStatsByNameID(_name_id,_uuid ));

        //pokemonToOwner[_uuid] = msg.sender;

        // _mint method from openzeppelin
        _safeMint(msg.sender, _uuid); // save_mint in openzeppelin?
        //_PokemonsExists[_uuid] = true;
    }


    // TODO: get data from json
    function getStatsByNameID(uint256  _name_id, uint256 _id) public pure returns ( Pokemon memory) {
        if (_name_id == 1){
            return(Pokemon(_id,152,111,106,111,8,0,8,30,11,40,_name_id));
        } else {
            return(Pokemon(_id,142,117,156,101,3,0,3,30,11,35,_name_id));
        }

    }


    /**
        function _transferNFT(address _to, uint256 _id) private {
            pokemonToOwner[_id] = _to;
            pokemons[_id].price = 0;
        }

        function buyNFT(uint _id) public payable {
            require(msg.sender != pokemonToOwner[_id], "Seller cannot be buyer");
            require(pokemons[_id].price > 0, "only Pokemons with a price can be bought. FREE does not exist");
            require(msg.value >= (pokemons[_id].price), "Insufficient funds");
            payable(pokemonToOwner[_id]).transfer(pokemons[_id].price);
            _transferNFT(msg.sender, _id);
        }
        */

    // override method from ERC721, ERC721Enumerable


    // override method from ERC721, ERC721Enumerable
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




    // L1 L2 Handlers


    // L2 -> L1. Transfer funds from layer 2  back to Layer 1
    function get_winner(
        uint256 l2ContractAddress,
        uint256 pokemonWinnerID,
        uint256 fightID
    ) external {

        uint256[] memory payload = new uint256[](2);
        payload[0] = pokemonWinnerID;
        payload[1] = fightID;


        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // Update the L1 balance.
        fightIDToWinnerPokemon[fightID] = pokemons[pokemonWinnerID];
    }

    // L1 -> L2
    function sendPokemonsToL2(
        uint256 l2ContractAddress,
        Pokemon memory pok1,
        Pokemon memory pok2,
        uint256 fight_ID
    ) public payable {


        // Construct the deposit message's payload.
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
        // passed to us as message fee.
        starknetCore.sendMessageToL2{value: msg.value}(
            l2ContractAddress,
            SELECTOR,
            payload
        );
    }


    function startFight(uint256 myPok, uint256 enemyPok) public {
        sendPokemonsToL2(L2_CONTRACT, pokemons[myPok], pokemons[enemyPok], createFightID());
    }


    function createFightID() private returns (uint256) {
        return fightIDCounter++;
    }



}
