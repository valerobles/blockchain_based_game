// This import is automatically injected by Remix
import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/2_NFT.sol";


contract testSuite is NFT {


    constructor() public NFT() {

    }

    function mintTest() public {

        mint(4);
        Assert.equal( msg.sender,ownerOf(0), "owner same");
        Assert.equal( 1,totalSupply(), "there is only one nft");
        mint(40);
        Assert.equal( 2,totalSupply(), "there are two");

    }

    function readingStruct() public {
        Assert.equal( 4,pokemons[0].name_id, "has to be name_id 4");
        Assert.equal( 40,pokemons[1].name_id, "has to be name_id 40");
    }

}
