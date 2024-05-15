// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import { IWitnetRandomness } from "witnet/interfaces/IWitnetRandomness.sol";
import { Requestor, NotCreator } from "../src/Requestor.sol";

contract RequestorTest is Test {

    Requestor requestor;
    IWitnetRandomness witnetRandomness;
    address alice;

    function setUp() public {
        alice = makeAddr("Alice");
        requestor = new Requestor();
        witnetRandomness = IWitnetRandomness(makeAddr("WitnetRandomness"));
        vm.etch(address(witnetRandomness), "witnetRandomness" );
    }

    function test_randomize() public {
        vm.mockCall(address(witnetRandomness), 1e18, abi.encodeWithSelector(IWitnetRandomness.randomize.selector), abi.encode(0.5e18));
        assertEq(requestor.randomize{value: 1e18}(1e18, witnetRandomness), 0.5e18);
    }

    function test_randomize_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(NotCreator.selector));
        vm.prank(alice);
        requestor.randomize(1, witnetRandomness);
    }

    function test_withdraw() public {
        vm.deal(address(requestor), 1000e18);
        uint beforeBalance = address(this).balance;
        requestor.withdraw(payable(address(this)));
        uint delta = address(this).balance - beforeBalance;
        assertEq(delta, 1000e18);
    }

    function test_withdraw_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(NotCreator.selector));
        vm.prank(alice);
        requestor.withdraw(payable(address(this)));
    }

    /// @notice Allows receive of ether
    receive() payable external {}
}
