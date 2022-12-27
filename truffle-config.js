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
    }
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
