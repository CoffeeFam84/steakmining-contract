// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITOKEN {
    function balanceOf(address) external view returns (uint256);
}

contract SVNSteakhouse is Ownable {

    struct DISCOUNT_INFO {
        address tokenAddress;
        uint256 fee;
        uint256 minimumHolding;
        uint256 tokenType;
    }

    uint256 private EGGS_TO_HATCH_1MINERS = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 2;
    uint256 private burnFeeVal = 2;
    bool private initialized = false;
    address payable private devWallet;
    address payable private burnWallet = payable(0x000000000000000000000000000000000000dEaD);
    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) private claimedSteak;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    uint256 private marketSteak;
    IERC20 private miningToken = IERC20(0xc21223249CA28397B4B6541dfFaEcC539BfF0c59);
    mapping(address => uint256) private lastSell;
    uint256 public WITHDRAW_COOLDOWN = 6 days;
    DISCOUNT_INFO[] private discountTokens;
    mapping(address => uint256) discountTokenIndex;
    uint256 private chefCount;
        
    constructor(address _token) {
        devWallet = payable(msg.sender);
        miningToken = IERC20(_token);
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
        require(lastSell[msg.sender] + WITHDRAW_COOLDOWN <= block.timestamp, "You can't withdraw for a while");
        uint256 hasEggs = getMySteak(msg.sender);
        uint256 eggValue = calculateSteakSell(hasEggs);
        uint256 fee = devFee(eggValue);
        uint256 bfee = burnFee(eggValue);
        claimedSteak[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketSteak = marketSteak + hasEggs;
        miningToken.transfer(devWallet, fee);
        miningToken.transfer(burnWallet, bfee);
        miningToken.transfer(msg.sender, eggValue-fee);
        lastSell[msg.sender] = block.timestamp;
    }
    
    function beanRewards(address adr) public view returns(uint256) {
        uint256 hasEggs = getMySteak(adr);
        uint256 eggValue = calculateSteakSell(hasEggs);
        return eggValue;
    }
    
    function grillSteak(address ref, uint256 amount) public {
        require(initialized);
        uint256 contractBalance = miningToken.balanceOf(address(this));
        miningToken.transferFrom(msg.sender, address(this), amount);
        uint256 eggsBought = calculateSteakBuy(amount, contractBalance);
        eggsBought = eggsBought - devFee(eggsBought) - burnFee(eggsBought);
        uint256 fee = devFee(amount);
        uint256 bfee = burnFee(amount);
        miningToken.transfer(devWallet, fee);
        miningToken.transfer(burnWallet, bfee);
        claimedSteak[msg.sender] = claimedSteak[msg.sender] + eggsBought;
        if (hatcheryMiners[msg.sender] == 0) {
            chefCount += 1;
        }
        reGrill(ref);
        lastSell[msg.sender] = block.timestamp;
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return (PSN * bs) / (PSNH + (((PSN*rs) + (PSNH*rt)) / rt));
    }
    
    function calculateSteakSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketSteak,miningToken.balanceOf(address(this)));
    }
    
    function calculateSteakBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketSteak);
    }
    
    function calculateSteakBuySimple(uint256 eth) public view returns(uint256) {
        return calculateSteakBuy(eth,miningToken.balanceOf(address(this)));
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        uint256 discountFee = getDevFee();

        return amount*discountFee/100;
    }

    function getDevFee() public view returns(uint256) {
        uint256 discountFee = devFeeVal;
        for (uint256 i = 0; i < discountTokens.length; i++) {
            DISCOUNT_INFO storage info = discountTokens[i];
            ITOKEN token = ITOKEN(info.tokenAddress);
            if (token.balanceOf(msg.sender) >= info.minimumHolding) {
                if (info.fee < discountFee)
                    discountFee = info.fee;
            }
        }
        return discountFee;
    }

    function burnFee(uint256 amount) private view returns(uint256) {
        return amount*burnFeeVal/100;
    }
    
    function seedMarket(uint256 amount) public onlyOwner {
        require(marketSteak == 0);
        if (amount > 0) {
            miningToken.transferFrom(msg.sender, address(this), amount);
        }
        initialized = true;
        marketSteak = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return miningToken.balanceOf(address(this));
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

    function addOrUpdateDiscountToken(address _address, uint256 _fee, uint256 _minimum, uint256 _type) external onlyOwner {
        if (discountTokenIndex[_address] == 0) {
            discountTokens.push(DISCOUNT_INFO(_address, _fee, _minimum, _type));
            discountTokenIndex[_address] = discountTokens.length;
        }
        else {
            uint256 tokenIndex = discountTokenIndex[_address] - 1;
            discountTokens[tokenIndex] = DISCOUNT_INFO(_address, _fee, _minimum, _type);
        }
    }

    function removeDiscountToken(address _address) external onlyOwner {
        require(discountTokenIndex[_address] > 0, "Invalid Address");
        uint256 tokenIndex = discountTokenIndex[_address] - 1;
        uint256 lastIndex = discountTokens.length - 1;
        discountTokens[tokenIndex] = discountTokens[lastIndex];
        discountTokens.pop();
        delete discountTokenIndex[_address];
    }

    function getInvestorCount() external view returns (uint256) {
        return chefCount;
    }
}