// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Vault} from "./Vault.sol";

/// @title Scheduler
/// @notice Deposits into the vault and arms a withdrawal, tracking the
///         deadline locally so a caller can poll `ready(who)`.
/// @dev Calls the vault from this contract, so the vault sees the scheduler
///      as the depositor. The local timer mirrors the vault's constant and is
///      advisory -- the vault still reverts if fired early.
contract Scheduler {
    error NotArmed();
    error TooEarly();

    event Armed(address indexed who, uint256 releaseAt);

    Vault public immutable vault;

    /// @notice Deadline per caller. Keyed by the original caller, not by
    ///         address(this), so several users can share one scheduler.
    mapping(address => uint256) public armedAt;

    constructor(Vault _vault) {
        vault = _vault;
    }

    /// @notice Arm a withdrawal on behalf of the caller.
    /// @dev The vault has one slot per depositor; since this contract is the
    ///      depositor on its own books, the local map only tracks deadlines.
    function arm() external payable {
        if (armedAt[msg.sender] == 0) {
            vault.deposit{value: msg.value}();
        }
        vault.schedule();
        armedAt[msg.sender] = block.timestamp + 1 hours;
        emit Armed(msg.sender, armedAt[msg.sender]);
    }

    function ready(address who) external view returns (bool) {
        return armedAt[who] != 0 && block.timestamp >= armedAt[who];
    }

    function fire() external {
        uint256 t = armedAt[msg.sender];
        if (t == 0) revert NotArmed();
        if (block.timestamp < t) revert TooEarly();
        vault.withdraw();
        armedAt[msg.sender] = 0;
    }

    receive() external payable {}
}
