// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BaseIntegration, IERC20, IERC4626 } from "../BaseIntegration.t.sol";

contract MoonwellUSDCBaseIntegrationTest is BaseIntegration {
    uint256 fork;
    uint256 forkBlock = 14196582;
    uint256 forkBlockTimestamp = 1715182511;

    address internal _asset = address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    address internal _assetWhale = address(0xd5c41FD4a31Eaaf5559FfCC60Ec051fcB8eCC375);
    address internal _yieldVault = address(0x370E0EEEE6f4fa0cc1B818134186Cee6BcE4801d);
    address internal _mAsset = address(0xEdc817A28E8B93B03976FBd4a3dDBc9f7D176c22);
    address internal _mAssetWhale = address(0x11a020d80b0a4468BF45888a0AB33cf4169F520A);

    /* ============ setup ============ */

    function setUpUnderlyingAsset() public virtual override returns (IERC20 asset, uint8 decimals, uint256 approxAssetUsdExchangeRate) {
        return (IERC20(_asset), 6, 1e18);
    }

    function setUpYieldVault() public virtual override returns (IERC4626) {
        return IERC4626(_yieldVault);
    }

    function setUpFork() public virtual override {
        fork = vm.createFork(vm.rpcUrl("base"), forkBlock);
        vm.selectFork(fork);
        vm.warp(forkBlockTimestamp);
    }

    function beforeSetup() public virtual override {
        lowGasPriceEstimate = 0.05 gwei; // just L2 gas, we ignore L1 costs for a super low estimate
    }

    function afterSetup() public virtual override { }

    /* ============ helpers to override ============ */

    /// @dev The max amount of assets than can be dealt.
    function maxDeal() public virtual override returns (uint256) {
        return underlyingAsset.balanceOf(_assetWhale);
    }

    /// @dev May revert if the amount requested exceeds the amount available to deal.
    function dealAssets(address to, uint256 amount) public virtual override prankception(_assetWhale) {
        underlyingAsset.transfer(to, amount);
    }

    /// @dev Accrues yield by sending assets to the yield vault
    function _accrueYield() internal virtual override prankception(_assetWhale) {
        IERC20(_asset).transfer(_yieldVault, 100e6);
        _mAsset.call("accrueInterest()");
        vm.warp(block.timestamp + 1 days);
        _mAsset.call("accrueInterest()");
    }

    /// @dev Simulates loss by transferring some mAsset tokens out of the yield vault
    function _simulateLoss() internal virtual override prankception(_yieldVault) {
        IERC20(_mAsset).transfer(_mAssetWhale, IERC20(_mAsset).balanceOf(_yieldVault) / 2);
    }

}