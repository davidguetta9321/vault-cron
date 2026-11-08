// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Vault} from "../src/Vault.sol";
import {Scheduler} from "../src/Scheduler.sol";

interface Vm {
    function warp(uint256) external;
}

/// Minimal harness -- no forge-std import, so the tree has no submodules and
/// `forge test` works on a fresh clone with nothing else installed.
contract VaultTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    Vault v;

    function setUp() public {
        v = new Vault();
    }

    function test_Deposit() public {
        v.deposit{value: 1 ether}();
        require(v.balanceOf(address(this)) == 1 ether, "balance");
        require(v.totalSupply() == 1 ether, "supply");
    }

    function test_DepositTwiceReverts() public {
        v.deposit{value: 1 ether}();
        (bool ok,) = address(v).call{value: 1 ether}(
            abi.encodeWithSignature("deposit()")
        );
        require(!ok, "should revert");
    }

    function test_ScheduleSetsRelease() public {
        v.deposit{value: 1 ether}();
        v.schedule();
        require(v.releaseAt(address(this)) != 0, "not scheduled");
    }

    function test_WithdrawBeforeDelayReverts() public {
        v.deposit{value: 1 ether}();
        v.schedule();
        (bool ok,) = address(v).call(abi.encodeWithSignature("withdraw()"));
        require(!ok, "should revert before delay");
    }

    function test_WithdrawAfterDelay() public {
        v.deposit{value: 1 ether}();
        v.schedule();
        vm.warp(block.timestamp + 2 hours);
        v.withdraw();
        require(v.balanceOf(address(this)) == 0, "not cleared");
        require(v.totalSupply() == 0, "supply not cleared");
    }

    function test_WithdrawWithoutScheduleReverts() public {
        v.deposit{value: 1 ether}();
        (bool ok,) = address(v).call(abi.encodeWithSignature("withdraw()"));
        require(!ok, "should revert");
    }

    receive() external payable {}
}

contract SchedulerTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    Vault v;
    Scheduler s;

    function setUp() public {
        v = new Vault();
        s = new Scheduler(v);
    }

    function test_ArmDepositsAndMirrorsDeadline() public {
        s.arm{value: 1 ether}();
        require(s.armedAt(address(this)) != 0, "not armed");
        require(v.balanceOf(address(s)) == 1 ether, "scheduler did not deposit");
        require(!s.ready(address(this)), "should not be ready yet");
    }

    function test_FireTooEarlyReverts() public {
        s.arm{value: 1 ether}();
        (bool ok,) = address(s).call(abi.encodeWithSignature("fire()"));
        require(!ok, "should revert");
    }

    function test_FireAfterDelay() public {
        s.arm{value: 1 ether}();
        vm.warp(block.timestamp + 2 hours);
        require(s.ready(address(this)), "should be ready");
        s.fire();
        require(v.balanceOf(address(s)) == 0, "vault not drained");
        require(s.armedAt(address(this)) == 0, "not reset");
    }

    receive() external payable {}
}
