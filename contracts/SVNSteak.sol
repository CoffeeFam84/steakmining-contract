// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SVNSteakhouse is Ownable {

    uint256 private EGGS_TO_HATCH_1MINERS = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 4;
    uint256 private marketingFeeVal = 1;
    bool private initialized = false;
    address payable private devWallet;
    address payable private marketWallet = payable(0xcBd3E8B401F659C4037074cF2946f359de1c12e4);
    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) private claimedSteak;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    uint256 private marketSteak;
    IERC20 private svnToken = IERC20(0x654bAc3eC77d6dB497892478f854cF6e8245DcA9);
        
    constructor() {
        devWallet = payable(msg.sender);
    }
    
    function reGrill(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsUsed = getMySteak(msg.sender);
        uint256 newMiners = eggsUsed / EGGS_TO_HATCH_1MINERS;
        hatcheryMiners[msg.sender] = hatcheryMiners[msg.sender] + newMiners;
        claimedSteak[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        
        //send referral eggs
        claimedSteak[referrals[msg.sender]] = claimedSteak[referrals[msg.sender]] + eggsUsed/12;
        
        //boost market to nerf miners hoarding
        marketSteak=marketSteak + eggsUsed / 5;
    }
    
    function eatSteak() public {
        require(initialized);
        uint256 hasEggs = getMySteak(msg.sender);
        uint256 eggValue = calculateSteakSell(hasEggs);
        uint256 fee = devFee(eggValue);
        uint256 mfee = marketingFee(eggValue);
        claimedSteak[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketSteak = marketSteak + hasEggs;
        svnToken.transfer(devWallet, fee);
        svnToken.transfer(marketWallet, mfee);
        svnToken.transfer(msg.sender, eggValue-fee-mfee);
    }
    
    function beanRewards(address adr) public view returns(uint256) {
        uint256 hasEggs = getMySteak(adr);
        uint256 eggValue = calculateSteakSell(hasEggs);
        return eggValue;
    }
    
    function grillSteak(address ref, uint256 amount) public {
        require(initialized);
        uint256 contractBalance = svnToken.balanceOf(address(this));
        svnToken.transferFrom(msg.sender, address(this), amount);
        uint256 eggsBought = calculateSteakBuy(amount, contractBalance);
        eggsBought = eggsBought - devFee(eggsBought) - marketingFee(eggsBought);
        uint256 fee = devFee(amount);
        uint256 mfee = marketingFee(amount);
        svnToken.transfer(devWallet, fee);
        svnToken.transfer(marketWallet, mfee);
        claimedSteak[msg.sender] = claimedSteak[msg.sender] + eggsBought;
        reGrill(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return (PSN * bs) / (PSNH + (((PSN*rs) + (PSNH*rt)) / rt));
    }
    
    function calculateSteakSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketSteak,svnToken.balanceOf(address(this)));
    }
    
    function calculateSteakBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketSteak);
    }
    
    function calculateSteakBuySimple(uint256 eth) public view returns(uint256) {
        return calculateSteakBuy(eth,svnToken.balanceOf(address(this)));
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return amount*devFeeVal/100;
    }

    function marketingFee(uint256 amount) private view returns(uint256) {
        return amount*marketingFeeVal/100;
    }
    
    function seedMarket(uint256 amount) public onlyOwner {
        require(marketSteak == 0);
        if (amount > 0) {
            svnToken.transferFrom(msg.sender, address(this), amount);
        }
        initialized = true;
        marketSteak = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return svnToken.balanceOf(address(this));
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return hatcheryMiners[adr];
    }
    
    function getMySteak(address adr) public view returns(uint256) {
        return claimedSteak[adr] + getSteakSinceLastHatch(adr);
    }
    
    function getSteakSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS, block.timestamp - lastHatch[adr]);
        return secondsPassed * hatcheryMiners[adr];
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}