// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { UD2x18 } from "prb-math/UD2x18.sol";
import { UD60x18, convert } from "prb-math/UD60x18.sol";

import { IRng } from "../src/interfaces/IRng.sol";

import {
    DrawManager,
    StartDrawAuction,
    AuctionExpired,
    AuctionTargetTimeExceedsDuration,
    AuctionDurationGTDrawPeriodSeconds,
    RewardRecipientIsZero,
    DrawHasNotClosed,
    RngRequestNotComplete,
    AlreadyStartedDraw,
    DrawHasFinalized,
    RngRequestNotInSameBlock,
    TargetRewardFractionGTOne,
    StaleRngRequest,
    RetryLimitReached
} from "../src/DrawManager.sol";

contract DrawManagerTest is Test {

    event DrawStarted(
        address indexed sender,
        address indexed recipient,
        uint24 indexed drawId,
        uint48 elapsedTime,
        uint256 reward,
        uint32 rngRequestId,
        uint64 count
    );

    event DrawFinished(
        address indexed sender,
        address indexed recipient,
        uint24 indexed drawId,
        uint48 elapsedTime,
        uint256 reward,
        uint256 contributed
    );

    DrawManager drawManager;

    PrizePool prizePool = PrizePool(makeAddr("prizePool"));
    IRng rng = IRng(makeAddr("rng"));
    uint48 auctionDuration = 6 hours;
    uint48 auctionTargetTime = 1 hours;
    UD2x18 lastStartDrawFraction = UD2x18.wrap(0.1e18);
    UD2x18 lastFinishDrawFraction = UD2x18.wrap(0.2e18);
    uint256 maxRewards = 10e18;
    uint256 maxRetries = 3;
    address vaultBeneficiary = address(this);

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    function setUp() public {
        // ensure bad mock calls revert
        vm.etch(address(prizePool), "prizePool");
        vm.etch(address(rng), "rng");
        vm.roll(111);
        mockDrawPeriodSeconds(auctionDuration * 4);
        mockDrawIdToAwardAndClosingTime(1, 1 days);
        newDrawManager();
    }

    function test_constructor() public {
        assertEq(address(drawManager.prizePool()), address(prizePool), "prize pool");
        assertEq(address(drawManager.rng()), address(rng), "rng");
        assertEq(drawManager.auctionDuration(), auctionDuration, "auction duration");
        assertEq(drawManager.auctionTargetTime(), auctionTargetTime, "auction target time");
        assertEq(drawManager.maxRewards(), maxRewards, "max rewards");
        assertEq(drawManager.vaultBeneficiary(), vaultBeneficiary, "staking vault");
        assertEq(drawManager.lastStartDrawFraction().unwrap(), lastStartDrawFraction.unwrap(), "last start rng request fraction");
        assertEq(drawManager.lastFinishDrawFraction().unwrap(), lastFinishDrawFraction.unwrap(), "last award draw fraction");
    }

    function test_constructor_AuctionTargetTimeExceedsDuration() public {
        auctionTargetTime = auctionDuration + 1;
        vm.expectRevert(abi.encodeWithSelector(AuctionTargetTimeExceedsDuration.selector, auctionTargetTime, auctionDuration));
        newDrawManager();
    }

    function test_constructor_AuctionDurationGTDrawPeriodSeconds() public {
        mockDrawPeriodSeconds(auctionDuration / 2);
        vm.expectRevert(abi.encodeWithSelector(AuctionDurationGTDrawPeriodSeconds.selector, auctionDuration));
        newDrawManager();
    }

    function test_constructor_startRngRequest_TargetRewardFractionGTOne() public {
        lastStartDrawFraction = UD2x18.wrap(1.1e18);
        vm.expectRevert(abi.encodeWithSelector(TargetRewardFractionGTOne.selector));
        newDrawManager();
    }

    function test_constructor_awardDraw_TargetRewardFractionGTOne() public {
        lastFinishDrawFraction = UD2x18.wrap(1.1e18);
        vm.expectRevert(abi.encodeWithSelector(TargetRewardFractionGTOne.selector));
        newDrawManager();
    }

    function test_canStartDraw() public {
        vm.warp(1 days + auctionDuration / 2);
        assertTrue(drawManager.canStartDraw(), "can start draw");
    }

    function test_canStartDraw_auctionExpired() public {
        vm.warp(2 days);
        assertFalse(drawManager.canStartDraw(), "cannot start draw");
    }

    function test_canStartDraw_drawHasNotClosed() public {
        vm.warp(1 days - 1 hours);
        assertFalse(drawManager.canStartDraw(), "cannot start draw");
    }

    function test_startDrawReward() public {
        vm.warp(1 days);
        mockReserve(1e18, 0);
        // zero is not possible here; not sure why
        assertEq(drawManager.startDrawReward(), 28, "start draw fee");
    }

    function test_startDrawReward_cannotStart() public {
        vm.warp(2 days);
        assertEq(drawManager.startDrawReward(), 0, "start draw fee");
    }

    function test_startDrawReward_atTarget() public {
        vm.warp(1 days + auctionTargetTime);
        mockReserve(2e18, 0);
        assertEq(drawManager.startDrawReward(), 0.2e18, "start draw fee");
    }

    function test_startDrawReward_afterTarget() public {
        vm.warp(1 days + auctionTargetTime + (auctionDuration - auctionTargetTime) / 2);
        mockReserve(2e18, 0);
        assertEq(drawManager.startDrawReward(), 649999999999999996, "start draw fee");
    }

    function test_startDrawReward_onRetrySameDraw() public {
        startFirstDraw();
        mockRngFailure(99, true);
        vm.warp(1 days + auctionTargetTime + (auctionDuration - auctionTargetTime) / 2);
        mockReserve(2e18, 0);
        assertEq(drawManager.startDrawReward(), 649999999999999996, "start draw fee");
    }

    function test_startDrawReward_onTimeoutThenNextDraw() public {
        startFirstDraw();
        mockDrawIdToAwardAndClosingTime(2, 2 days);
        vm.warp(2 days + auctionTargetTime + (auctionDuration - auctionTargetTime) / 2);
        mockReserve(2e18, 0);
        assertEq(drawManager.startDrawReward(), 649999999999999996, "start draw fee");
    }

    function test_startDraw_success() public {
        vm.warp(1 days + auctionTargetTime);
        mockReserve(1e18, 0);
        mockRng(99, 0x1234);
        vm.expectEmit(true, true, true, true);
        emit DrawStarted(address(this), alice, 1, auctionTargetTime, 0.1e18, 99, 1);
        drawManager.startDraw(alice, 99);

        StartDrawAuction memory auction = drawManager.getLastStartDrawAuction();

        assertEq(auction.recipient, alice, "recipient");
        assertEq(auction.drawId, 1, "draw id");
        assertEq(auction.closedAt, 1 days + auctionTargetTime, "started at");
        assertEq(auction.rngRequestId, 99, "rng request id");
    }

    function test_startDraw_StaleRngRequest() public {
        startFirstDraw();
        mockRngFailure(99, true);
        vm.expectRevert(abi.encodeWithSelector(StaleRngRequest.selector));
        drawManager.startDraw(bob, 99);
    }

    function test_startDraw_retrySameDraw() public {
        startFirstDraw();

        vm.warp(1 days + auctionTargetTime);
        mockRngFailure(99, true);
        vm.roll(block.number + 1);
        mockRng(100, 0x1234);
        vm.expectEmit(true, true, true, true);
        emit DrawStarted(address(this), bob, 1, auctionTargetTime, 0.1e18, 100, 2);
        drawManager.startDraw(bob, 100);

        StartDrawAuction memory auction = drawManager.getLastStartDrawAuction();

        assertEq(auction.recipient, bob, "recipient");
        assertEq(auction.drawId, 1, "draw id");
        assertEq(auction.closedAt, block.timestamp, "started at");
        assertEq(auction.rngRequestId, 100, "rng request id");
    }

    function test_startDraw_skippedToNextDraw() public {
        startFirstDraw();
        mockDrawIdToAwardAndClosingTime(2, 2 days);
        vm.warp(2 days + auctionTargetTime);
        mockRng(100, 0x1234);
        vm.expectEmit(true, true, true, true);
        emit DrawStarted(address(this), bob, 2, auctionTargetTime, 0.1e18, 100, 1);
        drawManager.startDraw(bob, 100);
    }

    function test_startDraw_RetryLimitReached() public {
        vm.warp(1 days);
        mockReserve(1e18, 0);
        uint32 rngRequestId = 99;
        for (uint32 i = 0; i <= maxRetries; i++) {
            mockRng(rngRequestId, 0x1234);
            assertEq(drawManager.canStartDraw(), true);
            drawManager.startDraw(alice, rngRequestId);
            vm.roll(block.number + 1);
            mockRngFailure(rngRequestId, true);
            rngRequestId++;
        }

        mockRng(rngRequestId, 0x1234);
        vm.expectRevert(abi.encodeWithSelector(RetryLimitReached.selector));
        drawManager.startDraw(bob, rngRequestId);
    }

    function test_startDraw_clearOutOld() public {
        vm.warp(1 days);
        mockReserve(1e18, 0);
        mockRng(99, 0x1234);
        drawManager.startDraw(alice, 99);

        assertEq(drawManager.getStartDrawAuctionCount(), 1, "count is one");

        vm.warp(2 days);
        mockDrawIdToAwardAndClosingTime(2, 2 days);
        mockRng(100, 0x1234);
        drawManager.startDraw(bob, 100);

        assertEq(drawManager.getStartDrawAuctionCount(), 1, "count is still one");
    }

    function test_startDraw_RewardRecipientIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(RewardRecipientIsZero.selector));
        drawManager.startDraw(address(0), 99);
    }

    function test_startDraw_DrawHasNotClosed() public {
        mockDrawIdToAward(1);
        mockDrawIdToAwardAndClosingTime(1, 2 days);
        vm.expectRevert(abi.encodeWithSelector(DrawHasNotClosed.selector));
        drawManager.startDraw(alice, 99);
    }

    function test_startDraw_AlreadyStartedDraw() public {
        startFirstDraw();
        mockRng(100, 0x1234);
        mockRngFailure(99, false);
        vm.expectRevert(abi.encodeWithSelector(AlreadyStartedDraw.selector));
        drawManager.startDraw(alice, 100);
    }

    function test_startDraw_RngRequestNotInSameBlock() public {
        vm.warp(1 days);
        mockReserve(1e18, 0);
        mockRng(99, 0x1234);
        mockRequestedAtBlock(99, block.number - 1);

        vm.expectRevert(abi.encodeWithSelector(RngRequestNotInSameBlock.selector));
        drawManager.startDraw(alice, 99);
    }

    function test_startDraw_AuctionExpired() public {
        vm.warp(1 days + auctionDuration + 1);
        mockReserve(1e18, 0);
        mockRng(99, 0x1234);
        vm.expectRevert(abi.encodeWithSelector(AuctionExpired.selector));
        drawManager.startDraw(alice, 99);
    }

    function test_canFinishDraw() public {
        startFirstDraw();
        vm.warp(1 days + auctionTargetTime);
        assertTrue(drawManager.canFinishDraw(), "can award draw");
    }

    function test_canFinishDraw_rngNotComplete() public {
        startFirstDraw();
        mockRngComplete(99, false);
        vm.warp(1 days + auctionTargetTime);
        assertFalse(drawManager.canFinishDraw(), "can award draw");
    }

    function test_canFinishDraw_notCurrentDraw() public {
        startFirstDraw();
        vm.warp(2 days); // not strictly needed, but makes the test more clear
        mockDrawIdToAwardAndClosingTime(2, 2 days);
        assertFalse(drawManager.canFinishDraw(), "can no longer award draw");
    }

    function test_canFinishDraw_auctionElapsed() public {
        startFirstDraw();
        vm.warp(1 days + auctionDuration + 1); // not strictly needed, but makes the test more clear
        assertFalse(drawManager.canFinishDraw(), "auction has expired");
    }

    function test_finishDrawFee_zero() public {
        startFirstDraw();
        vm.warp(1 days);
        // not quite zero...tricky math gremlins here
        assertEq(drawManager.finishDrawReward(), 20, "award draw fee");
    }

    function test_finishDrawFee_targetTime() public {
        startFirstDraw();
        vm.warp(1 days + auctionTargetTime);
        assertEq(drawManager.finishDrawReward(), 0.2e18, "award draw fee");
    }

    function test_finishDrawFee_nextDraw() public {
        startFirstDraw();
        // current draw id to award is now 2
        mockDrawIdToAward(2);
        assertEq(drawManager.finishDrawReward(), 0, "award draw fee");
    }

    function test_finishDrawFee_afterAuctionEnded() public {
        startFirstDraw();
        vm.warp(1 days + auctionDuration * 2);
        assertEq(drawManager.finishDrawReward(), 0, "award draw fee");
    }

    function test_finishDraw() public {
        startFirstDraw();
        vm.warp(1 days + auctionTargetTime);

        mockFinishDraw(0x1234);
        vm.mockCall(
            address(prizePool),
            abi.encodeWithSelector(prizePool.contributePrizeTokens.selector, vaultBeneficiary, 1e18),
            abi.encode(1e18)
        );
        vm.expectEmit(true, true, true, true);
        emit DrawFinished(
            address(this),
            bob,
            1,
            auctionTargetTime,
            0.2e18,
            1e18
        );
        drawManager.finishDraw(bob);
    }

    function test_finishDraw_setLastValues() public {
        vm.warp(1 days + auctionTargetTime / 2);
        mockReserve(1e18, 0);
        mockRng(99, 0x1234);
        uint startReward = 75000000000000016;
        assertEq(drawManager.startDrawReward(), startReward, "start draw reward matches");
        vm.expectEmit(true, true, true, true);
        emit DrawStarted(address(this), alice, 1, auctionTargetTime / 2, startReward, 99, 1);
        drawManager.startDraw(alice, 99);

        mockFinishDraw(0x1234);
        vm.warp(1 days + auctionTargetTime*2);
        uint finishReward = 207999999999999997;
        mockAllocateRewardFromReserve(alice, startReward);
        mockAllocateRewardFromReserve(bob, finishReward);
        mockReserveContribution(1e18);
        assertEq(drawManager.finishDrawReward(), finishReward, "finish draw reward matches");
        vm.expectEmit(true, true, true, true);
        emit DrawFinished(
            address(this),
            bob,
            1,
            auctionTargetTime*2 - auctionTargetTime / 2,
            finishReward,
            1e18
        );
        drawManager.finishDraw(bob);

        assertEq(drawManager.lastStartDrawFraction().unwrap(), 75000000000000016, "last start draw fraction");
        assertEq(drawManager.lastFinishDrawFraction().unwrap(), 207999999999999997, "last finish draw fraction");
    }

    function test_finishDraw_multipleStarts() public {
        vm.warp(1 days + auctionTargetTime / 2);
        mockReserve(1e18, 0);
        mockRng(99, 0x1234);
        uint firstStartReward = 75000000000000016;
        assertEq(drawManager.startDrawReward(), firstStartReward, "start draw reward matches");
        vm.expectEmit(true, true, true, true);
        emit DrawStarted(address(this), alice, 1, auctionTargetTime / 2, firstStartReward, 99, 1);
        drawManager.startDraw(alice, 99);

        mockRngFailure(99, true);
        vm.warp(1 days + auctionTargetTime + auctionTargetTime / 2);
        vm.roll(block.number + 1);
        mockRng(100, 0x1234);
        uint secondStartReward = 0.1e18;
        assertEq(drawManager.startDrawReward(), secondStartReward, "start draw reward matches");
        vm.expectEmit(true, true, true, true);
        emit DrawStarted(address(this), bob, 1, auctionTargetTime, secondStartReward, 100, 2);
        drawManager.startDraw(bob, 100);

        mockFinishDraw(0x1234);
        vm.warp(1 days + auctionTargetTime*2);
        uint finishReward = 150000000000000032;
        mockAllocateRewardFromReserve(alice, firstStartReward);
        mockAllocateRewardFromReserve(bob, secondStartReward + finishReward);
        mockReserveContribution(1e18);
        assertEq(drawManager.finishDrawReward(), finishReward, "finish draw reward matches");
        vm.expectEmit(true, true, true, true);
        emit DrawFinished(
            address(this),
            bob,
            1,
            auctionTargetTime / 2,
            finishReward,
            1e18
        );
        drawManager.finishDraw(bob);
    }

    function test_finishDraw_zeroRewards() public {
        startFirstDraw();
        mockReserve(0, 0);
        vm.warp(1 days + auctionTargetTime);

        mockFinishDraw(0x1234);
        vm.expectEmit(true, true, true, true);
        emit DrawFinished(
            address(this),
            bob,
            1,
            auctionTargetTime,
            0,
            0
        );
        drawManager.finishDraw(bob);
    }

    function test_finishDraw_DrawHasFinalized() public {
        startFirstDraw();
        vm.warp(2 days);
        mockDrawIdToAward(2);
        vm.expectRevert(abi.encodeWithSelector(DrawHasFinalized.selector));
        drawManager.finishDraw(bob);
    }

    function test_finishDraw_RngRequestNotComplete() public {
        startFirstDraw();
        mockRngComplete(99, false);
        vm.expectRevert(abi.encodeWithSelector(RngRequestNotComplete.selector));
        drawManager.finishDraw(bob);
    }

    function test_finishDraw_AuctionExpired() public {
        startFirstDraw();
        vm.warp(1 days + auctionDuration + 1);
        vm.expectRevert(abi.encodeWithSelector(AuctionExpired.selector));
        drawManager.finishDraw(bob);
    }

    function test_finishDraw_RewardRecipientIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(RewardRecipientIsZero.selector));
        drawManager.finishDraw(address(0));
    }

    function test_getStartDrawAuction() public {
        startFirstDraw();
        StartDrawAuction memory auction = drawManager.getStartDrawAuction(0);
        assertEq(auction.recipient, alice, "recipient");
        assertEq(auction.drawId, 1, "draw id");
        assertEq(auction.closedAt, block.timestamp, "started at");
        assertEq(auction.rngRequestId, 99, "rng request id");
    }

    function startFirstDraw() public {
        vm.warp(1 days);
        mockReserve(1e18, 0);
        mockRng(99, 0x1234);
        vm.expectEmit(true, true, true, true);
        emit DrawStarted(address(this), alice, 1, 0, 28, 99, 1);
        drawManager.startDraw(alice, 99);
    }

    function mockReserveContribution(uint256 amount) public {
        mockAllocateRewardFromReserve(address(drawManager), amount);
        vm.mockCall(
            address(prizePool),
            abi.encodeWithSelector(prizePool.withdrawRewards.selector, address(prizePool), amount),
            abi.encode("")
        );
        vm.mockCall(
            address(prizePool),
            abi.encodeWithSelector(prizePool.contributePrizeTokens.selector, vaultBeneficiary, amount),
            abi.encode(32)
        );
    }

    function mockFinishDraw(uint randomNumber) public {
        uint24 drawIdToAward = prizePool.getDrawIdToAward();
        vm.mockCall(address(prizePool), abi.encodeWithSelector(prizePool.awardDraw.selector, randomNumber), abi.encode(drawIdToAward));
    }

    function mockAllocateRewardFromReserve(address recipient, uint amount) public {
        vm.mockCall(address(prizePool), abi.encodeWithSelector(prizePool.allocateRewardFromReserve.selector, recipient, amount), abi.encode());
    }

    function mockRequestedAtBlock(uint32 rngRequestId, uint256 blockNumber) public {
        vm.mockCall(address(rng), abi.encodeWithSelector(rng.requestedAtBlock.selector, rngRequestId), abi.encode(blockNumber));
    }

    function mockRng(uint32 rngRequestId, uint256 randomness) public {
        mockRequestedAtBlock(rngRequestId, block.number);
        vm.mockCall(address(rng), abi.encodeWithSelector(rng.randomNumber.selector, rngRequestId), abi.encode(randomness));
        mockRngComplete(rngRequestId, true);
    }

    function mockRngComplete(uint32 rngRequestId, bool isComplete) public {
        vm.mockCall(address(rng), abi.encodeWithSelector(rng.isRequestComplete.selector, rngRequestId), abi.encode(isComplete));
    }

    function mockRngFailure(uint32 rngRequestId, bool isFailure) public {
        vm.mockCall(address(rng), abi.encodeWithSelector(rng.isRequestFailed.selector, rngRequestId), abi.encode(isFailure));
    }

    function mockDrawPeriodSeconds(uint256 amount) public {
        vm.mockCall(address(prizePool), abi.encodeWithSelector(prizePool.drawPeriodSeconds.selector), abi.encode(amount));
    }

    function mockDrawIdToAward(uint24 drawId) public {
        vm.mockCall(address(prizePool), abi.encodeWithSelector(prizePool.getDrawIdToAward.selector), abi.encode(drawId));
    }

    function mockDrawIdToAwardAndClosingTime(uint24 drawId, uint256 closingAt) public {
        mockDrawIdToAward(drawId);
        vm.mockCall(address(prizePool), abi.encodeWithSelector(prizePool.drawClosesAt.selector, drawId), abi.encode(closingAt));
    }

    function mockReserve(uint reserve, uint pendingReserve) public {
        vm.mockCall(address(prizePool), abi.encodeWithSelector(prizePool.reserve.selector), abi.encode(reserve));
        vm.mockCall(address(prizePool), abi.encodeWithSelector(prizePool.pendingReserveContributions.selector), abi.encode(pendingReserve));
    }

    function newDrawManager() public {
        drawManager = new DrawManager(
            prizePool,
            rng,
            auctionDuration,
            auctionTargetTime,
            lastStartDrawFraction,
            lastFinishDrawFraction,
            maxRewards,
            maxRetries,
            vaultBeneficiary
        );
    }
}