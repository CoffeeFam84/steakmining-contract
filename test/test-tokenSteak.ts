import { expect } from "chai";
import { ethers } from "hardhat";

describe("USDC Steakhouse", function () {
  let usdcSteak : any;
  let usdcToken : any;
  let discountToken: any;
  let accounts: any;
  before(async () => {
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    usdcToken = await MockERC20.deploy();
    await usdcToken.deployed();

    discountToken = await MockERC20.deploy();
    await discountToken.deployed();

    accounts = await ethers.getSigners();

    const USDCSteak = await ethers.getContractFactory("USDCSteakhouse");
    usdcSteak = await USDCSteak.deploy(usdcToken.address, accounts[1].address);
    await usdcSteak.deployed();
    await usdcSteak.seedMarket(0);
    
  })
  it("Should return the default dev fee", async function () {
    expect(await usdcSteak.getDevFee()).to.be.equal(2);
  });

  it("Should return discount dev fee", async () => {
    await usdcSteak.addOrUpdateDiscountToken(discountToken.address, 1, 10, 1);
    await discountToken.mint(accounts[0].address, 100);
    expect(await usdcSteak.getDevFee()).to.be.equal(1);
    await usdcSteak.removeDiscountToken(discountToken.address);
    expect(await usdcSteak.getDevFee()).to.be.equal(2);
  });

  it("Should feed marketing wallet", async () => {
    await usdcToken.mint(accounts[0].address, 10000);
    await usdcToken.approve(usdcSteak.address, 1000);
    await usdcSteak.grillSteak(accounts[2].address, 100);
    expect(await usdcToken.balanceOf(accounts[1].address)).to.be.equal(1);
    expect(await usdcToken.balanceOf(accounts[0].address)).to.be.equal(9902)
  });
});
