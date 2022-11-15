const path = require("path");
var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "copper pair deputy tent thunder survey hero about blast pyramid cash ozone";
    module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    // kovan: {
    //   provider: function () {
    //     return new HDWalletProvider(mnemonic, "https://kovan.infura.io/v3/9f9522ee2dc944e5823d4fe51f86d1c4");
    //   },
    //   network_id: 42
    // }
  },
  compilers: {
    solc: {
      version: "0.8.11",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};
