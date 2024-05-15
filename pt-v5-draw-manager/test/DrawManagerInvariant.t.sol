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

contract DrawManagerInvariantTest is Test {

    DrawManager drawManager;

    

}