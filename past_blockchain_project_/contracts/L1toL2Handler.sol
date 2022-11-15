// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

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

contract L1toL2Handler {
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    // mapping(uint256 => uint256) public NFTAttributes;


     constructor(IStarknetCore starknetCore_) public {
        starknetCore = starknetCore_;
    }


      // L2 -> L1. Transfer funds from layer 2  back to Layer 1
    function withdraw(
        uint256 l2ContractAddress,
        uint256 user,
        uint256 amount
    ) external {
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](3);
        payload[0] = MESSAGE_WITHDRAW;
        payload[1] = user;
        payload[2] = amount;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // Update the L1 balance.
        userBalances[user] += amount;
    }

    // L1 -> L2
    function sendPokemonsToL2(
        uint256 l2ContractAddress,
        NFT.Pokemon pok1,
        NFT.Pokemon pok2,
    ) external payable {
        //require(amount < 2**64, "Invalid amount.");
        //require(amount <= userBalances[user], "The user's balance is not large enough.");

        // Update the L1 balance.
        userBalances[user] -= amount;

        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](2);
        payload[0] = user;
        payload[1] = amount;

        // Send the message to the StarkNet core contract, passing any value that was
        // passed to us as message fee.
        starknetCore.sendMessageToL2{value: msg.value}(
            l2ContractAddress,
            DEPOSIT_SELECTOR,
            payload
        );
    }


}