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
    Pokemon[] public pokemons; // List of all Pokemon

    IStarknetCore starknetCore;

    uint256 L2_CONTRACT_POK = 0x8cac48be6861cc5546931905f41c3ef65cd4ad5891c3812846f8a7b9188b47; // only 1 l1 handler on pokemon_game_flat
    uint256 L2_CONTRACT_POK_LOW_PARAM = 0x29d6211b17db87104988e19865f0bc32fee6340a4a03126eb5cd40f520aa9a3; // low param pok
    uint256 L2_CONTRACT_ALL_L1_HANDLER = 0x5e4150fb681061ad2b5144e56f806bda709fbbb87ef0ff49946d1a280b444b7;




    uint256 fightIDCounter = 0;



    uint256 constant SELECTOR = 1625440424450498852892950090004073452274266572863945925863133186904237482575; // pokemon_game_flat as a selector encoded
    uint256 constant SELECTORSHORT = 20708754562186431156644569844516723735906655576666629544789946317872496633; // low param as a selector encoded
    // uint256 constant SELECTOR_NOPARAM = 1011393743699566059363786613911706806670630810185176199006738004708002761258;  // testfunc selector
    // uint256 constant SELECTOR_ADRESS = 207422004790897179769944665920910064499841236648852597806335524014759737548; // testfunc2 selector




    mapping (uint256 => Pokemon) public fightIDToWinnerPokemon; // mapping of fight ID to Winner Pokemon


    event startFight(address indexed _from, uint256 _pok1, uint256 _pok2, uint256 l2Contract, uint _value);

    event startFightMessage(uint message);

    event gettingWinnerEntered(uint message);

    event gettingWinnerFinished(uint256 l2contract, uint256 _winnerPok, uint256 _fightID);

    event enteredFunc(uint message);






    constructor() ERC721("NFT","CC") {
        starknetCore = IStarknetCore(address(0xde29d060D45901Fb19ED6C6e959EB22d8626708e)); // https://docs.starknet.io/documentation/Ecosystem/ref_operational_info/
    }



    function mint(uint256  _name_id) public {
        uint256 _uuid = pokemons.length; // TODO: create UUID for unique ID

        pokemons.push(getStatsByNameID(_name_id,_uuid )); // create Pokemon from json

        // _safeMint method from openzeppelin
        _safeMint(msg.sender, _uuid);
    }


    // TODO: get data from json
    function getStatsByNameID(uint256  _name_id, uint256 _id) public pure returns ( Pokemon memory) {
        if (_name_id == 1){
            return(Pokemon(_id,152,111,106,111,8,0,8,30,11,40,_name_id));
        } else {
            return(Pokemon(_id,142,117,156,101,3,0,3,30,11,35,_name_id));
        }

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


    // L2 -> L1. Recieve winner from L2
    function get_winner(
        uint256 l2ContractAddress,
        uint256 pokemonWinnerID,
        uint256 fightID
    ) external {

        emit gettingWinnerEntered(11111);

        uint256[] memory payload = new uint256[](2);
        payload[0] = pokemonWinnerID;
        payload[1] = fightID;


        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // Update the L1 balance.
        fightIDToWinnerPokemon[fightID] = pokemons[pokemonWinnerID];

        emit gettingWinnerFinished(l2ContractAddress, pokemonWinnerID, fightID);


    }





    // L1 -> L2. Send 2 pokemon to fight to L2
    function sendPokemonsToL2(
        uint256 myPok,
        uint256 enemyPok
    ) external payable {

        emit startFightMessage(1);

        Pokemon memory pok1 = pokemons[myPok];
        Pokemon memory pok2 = pokemons[enemyPok];
        uint256 fight_ID = createFightID();

        //require(balanceOf(msg.sender) >= msg.value, "Insufficient funds");

        // payable(ownerOf(pok1.id)).transfer(msg.value);

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
        starknetCore.sendMessageToL2{value: msg.value}(
            L2_CONTRACT_POK,
            SELECTOR,
            payload
        );

        emit startFight(msg.sender, pok1.id, pok2.id, L2_CONTRACT_POK, msg.value);
    }


    function sendPokemonsToL2Short(
    ) external payable {

        emit startFightMessage(1);

        uint256 fight_ID = createFightID();

        // require(balanceOf(msg.sender) >= msg.value, "Insufficient funds");

        // payable(msg.sender).transfer(msg.value);

        emit startFightMessage(2);

        // Construct the message's payload.
        uint256[] memory payload = new uint256[](1);

        payload[0] = fight_ID;

        emit startFightMessage(3);

        // Send the message to the StarkNet core contract, passing any value that was
        // passed to us as message fee.
        starknetCore.sendMessageToL2{value: msg.value}(
            L2_CONTRACT_POK_LOW_PARAM,
            SELECTORSHORT,
            payload
        );

        emit startFightMessage(fight_ID);
    }














    // WITH HANDLERS




    function sendPokemonsToL2_withHandlers(
        uint256 myPok,
        uint256 enemyPok
    ) external payable {

        emit startFightMessage(1);

        Pokemon memory pok1 = pokemons[myPok];
        Pokemon memory pok2 = pokemons[enemyPok];
        uint256 fight_ID = createFightID();

        //require(balanceOf(msg.sender) >= msg.value, "Insufficient funds");

        // payable(ownerOf(pok1.id)).transfer(msg.value);

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
        starknetCore.sendMessageToL2{value: msg.value}(
            L2_CONTRACT_ALL_L1_HANDLER,
            SELECTOR,
            payload
        );

        emit startFight(msg.sender, pok1.id, pok2.id, L2_CONTRACT_POK, msg.value);
    }


    function sendPokemonsToL2Short_withHandlers(
    ) external payable {

        emit startFightMessage(1);

        uint256 fight_ID = createFightID();

        // require(balanceOf(msg.sender) >= msg.value, "Insufficient funds");

        // payable(msg.sender).transfer(msg.value);

        emit startFightMessage(2);

        // Construct the message's payload.
        uint256[] memory payload = new uint256[](1);

        payload[0] = fight_ID;

        emit startFightMessage(3);

        // Send the message to the StarkNet core contract, passing any value that was
        // passed to us as message fee.
        starknetCore.sendMessageToL2{value: msg.value}(
            L2_CONTRACT_ALL_L1_HANDLER,
            SELECTORSHORT,
            payload
        );

        emit startFightMessage(fight_ID);
    }


    // Method to be called from UI
    //function startFight(uint256 myPok, uint256 enemyPok) public {
    //    sendPokemonsToL2(L2_CONTRACT, pokemons[myPok], pokemons[enemyPok], createFightID());
    // }


    function createFightID() private returns (uint256) {
        return fightIDCounter++;
    }

    // // testfunc
    // function testL1NoParams() external payable{

    //     uint256[] memory payload = new uint256[](1);

    //     payload[0] = 1234;

    //     emit enteredFunc(888);

    //     starknetCore.sendMessageToL2{value: msg.value}(
    //         L2_CONTRACT_TEST,
    //         SELECTOR_NOPARAM,
    //         payload
    //     );

    //     emit enteredFunc(payload[0]);

    // }

    // // testfunc 2
    // function testL1Address() external payable{


    //     uint256[] memory payload = new uint256[](0);

    //     emit enteredFunc(999);


    //     starknetCore.sendMessageToL2{value: msg.value}(
    //         L2_CONTRACT_ADDRESS,
    //         SELECTOR_ADRESS,
    //         payload
    //     );

    // }

    function sendDummyMessage(uint256 test_num) external {

        emit enteredFunc(777);

        uint256[] memory payload = new uint256[](1);
        payload[0] = test_num;


        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(L2_CONTRACT_POK, payload);

        emit enteredFunc(test_num);


    }




}