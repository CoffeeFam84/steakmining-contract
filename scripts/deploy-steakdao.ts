// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const SteakDAO = await ethers.getContractFactory("SteakDAO");
  const steakDAO = await SteakDAO.deploy("https://ipfs.io/ipfs/abcdaeaer");
  await steakDAO.deployed();

  await steakDAO.setWhitelistAddresses(['0x2aE099ee1a9725389A0e824d2A865b425E0936d1', '0x7A0b8D56DDBAa1B4b2B51B634714348897108792']);
  
  console.log("DAO deployed to:", steakDAO.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
