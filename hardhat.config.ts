import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: "0.8.13",
  networks: {
    cronos : {
      url : "https://gateway.nebkas.ro/",
      chainId: 25,
      accounts: process.env.SIGNER !== undefined ? [process.env.SIGNER] : [],
      gasPrice: 5000000000000,
    },
    cronos_testnet : {
      url : "https://cronos-testnet-3.crypto.org:8545/",
      chainId : 338,
      accounts:  process.env.SIGNER !== undefined ? [process.env.SIGNER] : [],
      gasPrice: 5000000000000,
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
