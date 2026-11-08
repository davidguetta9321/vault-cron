// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Vault
/// @notice One deposit per user, one scheduled withdrawal.
/// @dev Deliberately small. No proxy, no governance.
contract Vault {
    error NotOwner();
    error AlreadyDeposited();
    error NothingToWithdraw();
    error NotScheduled();
    error SendFailed();

    event Deposited(address indexed who, uint256 amount);
    event Scheduled(address indexed who, uint256 releaseAt);
    event Withdrawn(address indexed who, uint256 amount);

    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public releaseAt;

    uint256 public totalSupply;

    uint256 public constant DELAY = 1 hours;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        if (balanceOf[msg.sender] != 0) revert AlreadyDeposited();
        balanceOf[msg.sender] = msg.value;
        totalSupply += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function schedule() external {
        if (balanceOf[msg.sender] == 0) revert NothingToWithdraw();
        releaseAt[msg.sender] = block.timestamp + DELAY;
        emit Scheduled(msg.sender, releaseAt[msg.sender]);
    }

    function withdraw() external {
        uint256 amt = balanceOf[msg.sender];
        if (amt == 0) revert NothingToWithdraw();
        uint256 rel = releaseAt[msg.sender];
        if (rel == 0 || block.timestamp < rel) revert NotScheduled();

        balanceOf[msg.sender] = 0;
        releaseAt[msg.sender] = 0;
        totalSupply -= amt;

        (bool ok,) = msg.sender.call{value: amt}("");
        if (!ok) revert SendFailed();

        emit Withdrawn(msg.sender, amt);
    }
}
