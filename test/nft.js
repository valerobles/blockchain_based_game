const NFT = artifacts.require("./NFT.sol");

contract("NFT", accounts => {

  let contract;
  before(async () => {
    contract = await NFT.deployed();
  })


  it("...should get deployed.", async () => {
    assert.notEqual(contract, "");

  });

  it("... get's minted and added", async () => {
    const results = await contract.mint("4");


    let pokemon = await contract.pokemons(0);

    assert.equal(pokemon.name_id, "4");
  })



});
