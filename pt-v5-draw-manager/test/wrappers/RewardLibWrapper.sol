// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { UD2x18 } from "prb-math/UD2x18.sol";

import { Allocation, RewardLib } from "../../src/libraries/RewardLib.sol";

// Note: Need to store the results from the library in a variable to be picked up by forge coverage
// See: https://github.com/foundry-rs/foundry/pull/3128#issuecomment-1241245086
contract RewardLibWrapper {
  function fractionalReward(
    uint48 _elapsedTime,
    uint48 _auctionDuration,
    UD2x18 _targetTimeFraction,
    UD2x18 _targetRewardFraction
  ) public pure returns (UD2x18) {
    UD2x18 result = RewardLib.fractionalReward(
      _elapsedTime,
      _auctionDuration,
      _targetTimeFraction,
      _targetRewardFraction
    );
    return result;
  }

  function rewards(
    Allocation[] memory _allocations,
    uint256 _reserve
  ) public pure returns (uint256[] memory) {
    uint256[] memory result = RewardLib.rewards(_allocations, _reserve);
    return result;
  }

  function reward(
    UD2x18 _fraction,
    uint256 _reserve
  ) public pure returns (uint256) {
    uint256 result = RewardLib.reward(_fraction, _reserve);
    return result;
  }
}
