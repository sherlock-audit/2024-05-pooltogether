// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import { IWitnetRandomness } from "witnet/interfaces/IWitnetRandomness.sol";
import { RngWitnet } from "../../src/RngWitnet.sol";

contract RngWitnetForkTest is Test {

    IWitnetRandomness witnetRandomness;
    RngWitnet rngWitnet;

    uint256 fork;

    function setUp() public {
        fork = vm.createFork("optimism-sepolia", 9791733);
        vm.selectFork(fork);
        witnetRandomness = IWitnetRandomness(0xc0ffee84FD3B533C3fA408c993F59828395319A1);
        rngWitnet = new RngWitnet(witnetRandomness);
        vm.deal(address(this), 1000e18);
    }

    function testRequestRandomNumberFromFork() external {
        uint fee = 0.00002e18;
        (uint32 requestId, uint256 lockBlock, uint256 cost) = rngWitnet.requestRandomNumber{value: fee}(fee);
        assertEq(requestId, 1, "request id");
        assertEq(lockBlock, block.number, "block number");
        assertGt(cost, 0, "cost");
    }

    receive() external payable {}
}
