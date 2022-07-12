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

    uint256 private STEAK_TO_HATCH_1cheffs = 1080000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 2;
    uint256 private burnFeeVal = 2;
    bool private initialized = false;
    address payable private devWallet;
    address payable private burnWallet = payable(0x000000000000000000000000000000000000dEaD);
    mapping (address => uint256) private GrillingCheffs;
    mapping (address => uint256) private claimedSteak;
    mapping (address => uint256) private lastGrill;
    mapping (address => address) private referrals;
    uint256 private marketSteak;
    IERC20 private miningToken = IERC20(0x654bAc3eC77d6dB497892478f854cF6e8245DcA9);
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
        
        uint256 MeatGrilled = getMySteak(msg.sender);
        uint256 newCheffs = MeatGrilled / STEAK_TO_HATCH_1cheffs;
        GrillingCheffs[msg.sender] = GrillingCheffs[msg.sender] + newCheffs;
        claimedSteak[msg.sender] = 0;
        lastGrill[msg.sender] = block.timestamp;
        
        //send referral 
        claimedSteak[referrals[msg.sender]] = claimedSteak[referrals[msg.sender]] + MeatGrilled/12;
        
        //boost market 
        marketSteak=marketSteak + MeatGrilled / 5;
    }
    
    function eatSteak() public {
        require(initialized);
        require(lastSell[msg.sender] + WITHDRAW_COOLDOWN <= block.timestamp, "You can't withdraw for a while");
        uint256 hasMeat = getMySteak(msg.sender);
        uint256 meatValue = calculateSteakSell(hasMeat);
        uint256 fee = devFee(meatValue);
        uint256 bfee = burnFee(meatValue);
        claimedSteak[msg.sender] = 0;
        lastGrill[msg.sender] = block.timestamp;
        marketSteak = marketSteak + hasMeat;
        miningToken.transfer(devWallet, fee);
        miningToken.transfer(burnWallet, bfee);
        miningToken.transfer(msg.sender, meatValue-fee);
        lastSell[msg.sender] = block.timestamp;
    }
    
    function steakRewards(address adr) public view returns(uint256) {
        uint256 hasMeat = getMySteak(adr);
        uint256 meatValue = calculateSteakSell(hasMeat);
        return meatValue;
    }
    
    function grillSteak(address ref, uint256 amount) public {
        require(initialized);
        uint256 contractBalance = miningToken.balanceOf(address(this));
        miningToken.transferFrom(msg.sender, address(this), amount);
        uint256 meatBought = calculateSteakBuy(amount, contractBalance);
        meatBought = meatBought - devFee(meatBought) - burnFee(meatBought);
        uint256 fee = devFee(amount);
        uint256 bfee = burnFee(amount);
        miningToken.transfer(devWallet, fee);
        miningToken.transfer(burnWallet, bfee);
        claimedSteak[msg.sender] = claimedSteak[msg.sender] + meatBought;
        if (GrillingCheffs[msg.sender] == 0) {
            chefCount += 1;
        }
        reGrill(ref);
        lastSell[msg.sender] = block.timestamp;
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return (PSN * bs) / (PSNH + (((PSN*rs) + (PSNH*rt)) / rt));
    }
    
    function calculateSteakSell(uint256 meats) public view returns(uint256) {
        return calculateTrade(meats,marketSteak,miningToken.balanceOf(address(this)));
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
        return GrillingCheffs[adr];
    }
    
    function getMySteak(address adr) public view returns(uint256) {
        return claimedSteak[adr] + getSteakSinceLastHatch(adr);
    }
    
    function getSteakSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(STEAK_TO_HATCH_1cheffs, block.timestamp - lastGrill[adr]);
        return secondsPassed * GrillingCheffs[adr];
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