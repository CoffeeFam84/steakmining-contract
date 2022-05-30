// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor () ERC20 ("Test", "TT") {
        
    }

    function mint(address sender, uint256 amount) public {
      _mint(sender, amount);
    }
}