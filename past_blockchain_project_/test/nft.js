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
    const results = await contract.mint("Valeria");


    let student = await contract.students(0);

    assert.equal(student.name, "Valeria");
  })

  // it("check price...", async () => {
  //   const results = await contract.mint("Valeria");
  //
  //   let price = await contract.getPrice.call("Valeria");
  //
  //   assert(price, 5);
  // })

});
