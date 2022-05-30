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
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const usdcMock = await MockERC20.deploy();
  await usdcMock.deployed();
  const USDCSteakhouse = await ethers.getContractFactory("USDCSteakhouse");
  const usdcSteak = await USDCSteakhouse.deploy(usdcMock.address, '0xdDCB518ac5a11F92243AdA209951fcd6e0B18705');

  await usdcSteak.deployed();
  await usdcSteak.seedMarket(0);
  await usdcMock.mint('0xBBC6232725EAf504c53A09cFf63b1186BCAc6316', '100000000000000000000000000');

  const SVNSteakhouse = await ethers.getContractFactory("SVNSteakhouse");
  const svnSteak = await SVNSteakhouse.deploy(usdcMock.address);

  await svnSteak.deployed();
  await svnSteak.seedMarket(0);

  console.log("USDC deployed to:", usdcMock.address);
  console.log("USDCSteakhouse deployed to:", usdcSteak.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
