
# PoolTogether contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

# Audit scope


[pt-v5-prize-pool @ 768fa642eb31cfff0fe929da0929a9bb4dea0b2d](https://github.com/GenerationSoftware/pt-v5-prize-pool/tree/768fa642eb31cfff0fe929da0929a9bb4dea0b2d)
- [pt-v5-prize-pool/src/PrizePool.sol](pt-v5-prize-pool/src/PrizePool.sol)
- [pt-v5-prize-pool/src/abstract/TieredLiquidityDistributor.sol](pt-v5-prize-pool/src/abstract/TieredLiquidityDistributor.sol)
- [pt-v5-prize-pool/src/libraries/DrawAccumulatorLib.sol](pt-v5-prize-pool/src/libraries/DrawAccumulatorLib.sol)
- [pt-v5-prize-pool/src/libraries/TierCalculationLib.sol](pt-v5-prize-pool/src/libraries/TierCalculationLib.sol)

[pt-v5-draw-manager @ f04edd938f0ce3d6bbaf5db2748319d6ebf6b078](https://github.com/GenerationSoftware/pt-v5-draw-manager/tree/f04edd938f0ce3d6bbaf5db2748319d6ebf6b078)
- [pt-v5-draw-manager/src/DrawManager.sol](pt-v5-draw-manager/src/DrawManager.sol)
- [pt-v5-draw-manager/src/libraries/RewardLib.sol](pt-v5-draw-manager/src/libraries/RewardLib.sol)

[pt-v5-claimer @ a3619aa13c19beb25210ddb6474cd51aac794706](https://github.com/GenerationSoftware/pt-v5-claimer/tree/a3619aa13c19beb25210ddb6474cd51aac794706)
- [pt-v5-claimer/src/Claimer.sol](pt-v5-claimer/src/Claimer.sol)
- [pt-v5-claimer/src/ClaimerFactory.sol](pt-v5-claimer/src/ClaimerFactory.sol)
- [pt-v5-claimer/src/libraries/LinearVRGDALib.sol](pt-v5-claimer/src/libraries/LinearVRGDALib.sol)

[pt-v5-tpda-liquidator @ 2f7aeb0ebc88a650791e7e56dee33e9981f3ed14](https://github.com/GenerationSoftware/pt-v5-tpda-liquidator/tree/2f7aeb0ebc88a650791e7e56dee33e9981f3ed14)
- [pt-v5-tpda-liquidator/src/TpdaLiquidationPair.sol](pt-v5-tpda-liquidator/src/TpdaLiquidationPair.sol)
- [pt-v5-tpda-liquidator/src/TpdaLiquidationPairFactory.sol](pt-v5-tpda-liquidator/src/TpdaLiquidationPairFactory.sol)
- [pt-v5-tpda-liquidator/src/TpdaLiquidationRouter.sol](pt-v5-tpda-liquidator/src/TpdaLiquidationRouter.sol)

[pt-v5-rng-witnet @ ac310b9deb1e53a547e53d69861495888d322ac3](https://github.com/GenerationSoftware/pt-v5-rng-witnet/tree/ac310b9deb1e53a547e53d69861495888d322ac3)
- [pt-v5-rng-witnet/src/Requestor.sol](pt-v5-rng-witnet/src/Requestor.sol)
- [pt-v5-rng-witnet/src/RngWitnet.sol](pt-v5-rng-witnet/src/RngWitnet.sol)

[pt-v5-twab-controller @ 827255118b0de751bc797de6bf6ed042496aea4d](https://github.com/GenerationSoftware/pt-v5-twab-controller/tree/827255118b0de751bc797de6bf6ed042496aea4d)
- [pt-v5-twab-controller/src/TwabController.sol](pt-v5-twab-controller/src/TwabController.sol)
- [pt-v5-twab-controller/src/libraries/ObservationLib.sol](pt-v5-twab-controller/src/libraries/ObservationLib.sol)
- [pt-v5-twab-controller/src/libraries/TwabLib.sol](pt-v5-twab-controller/src/libraries/TwabLib.sol)

[pt-v5-vault @ 436b06fbe33d7c4616dea4dbdb262237c1436cb6](https://github.com/GenerationSoftware/pt-v5-vault/tree/436b06fbe33d7c4616dea4dbdb262237c1436cb6)
- [pt-v5-vault/src/PrizeVault.sol](pt-v5-vault/src/PrizeVault.sol)
- [pt-v5-vault/src/PrizeVaultFactory.sol](pt-v5-vault/src/PrizeVaultFactory.sol)
- [pt-v5-vault/src/TwabERC20.sol](pt-v5-vault/src/TwabERC20.sol)
- [pt-v5-vault/src/abstract/Claimable.sol](pt-v5-vault/src/abstract/Claimable.sol)
- [pt-v5-vault/src/abstract/HookManager.sol](pt-v5-vault/src/abstract/HookManager.sol)
- [pt-v5-vault/src/interfaces/IPrizeHooks.sol](pt-v5-vault/src/interfaces/IPrizeHooks.sol)
