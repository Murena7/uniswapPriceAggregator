import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-web3";
import "hardhat-abi-exporter";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

export default {
  solidity: "0.8.0",
  networks: {
    hardhat: {
      forking: {
        url: process.env.NETWORK_URL
      }
    },
    ganacheTest: {
      url: "http://127.0.0.1:7555",
      accounts: [process.env.ACCOUNT],
    }
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: true,
    spacing: 2
  }
};
