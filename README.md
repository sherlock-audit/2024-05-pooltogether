
# PoolTogether contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
The contracts are deployed on Optimism and Base.

We also plan on deploying to:

- Arbitrum
- Ethereum
- Gnosis
- Blast
- Linea
- Scroll
- zkSync
- Avalanche
- Polygon
- Zerion

We're interested to know if there will be any issues deploying the code as-is to any of these chains, and whether their opcodes fully support our application.
___

### Q: If you are integrating tokens, are you allowing only whitelisted tokens to work with the codebase or any complying with the standard? Are they assumed to have certain properties, e.g. be non-reentrant? Are there any types of <a href="https://github.com/d-xo/weird-erc20" target="_blank" rel="noopener noreferrer">weird tokens</a> you want to integrate?
The protocol supports any standard ERC20 that does not have reentrancy or fee on transfer. USDT is also in scope.
___

### Q: Are the admins of the protocols your contracts integrate with (if any) TRUSTED or RESTRICTED? If these integrations are trusted, should auditors also assume they are always responsive, for example, are oracles trusted to provide non-stale information, or VRF providers to respond within a designated timeframe?
The core protocol integration is the random number generator, Witnet. This is a trusted integration and you can assume they are always responsive.

Prize vaults can be created by anyone, and our intention is to encourage them. Under normal conditions, a good actor will use a trustworthy 4626 yield source, the standard PT prize claimer contract, and a standard Liquidation Pair. We want the Sherlock auditors to ensure that the contract behaves as expected.

That being said, prize vaults can be created by anyone. We understand that a bad actor could create a vault and steal all of the yield or prizes, or even use a malicious yield source. We do not expect to prevent that scenario.

We are not gatekeeping prize vault creation; instead the front-ends will curate what vaults are shown.
___

### Q: Are there any protocol roles? Please list them and provide whether they are TRUSTED or RESTRICTED, or provide a more comprehensive description of what a role can and can't do/impact.
The only permissioned role in the codebase is the Prize Vault owner. They can create new Prize Vaults permissionlessly. As explained above, we do not expect to gatekeep the creation of new prize vaults. However, we do want the logic of the prize vault to be sound for good actors.
___

### Q: For permissioned functions, please list all checks and requirements that will be made before calling the function.
The Prize Vault has four permissioned setters for the claimer, liquidation pair, yield fee percentage, and yield fee recipient.  Each one requires that the caller is the owner of the vault.
___

### Q: Is the codebase expected to comply with any EIPs? Can there be/are there any deviations from the specification?
PrizeVaults are expected to strictly comply with the ERC4626 standard.
___

### Q: Are there any off-chain mechanisms or off-chain procedures for the protocol (keeper bots, arbitrage bots, etc.)?
There are three bots:

- Draw Bots that take advantage of the two phase dutch auction that is used to trigger the RNG request.
- Liquidation Bots that swap yield for WETH on the prize vaults
- Claimer Bots that earn fees by claiming prizes for users

We expect them to be always online.  If they are not then draws may be skipped and prizes may be missed, but no prize vault or prize pool funds should be at risk.

___

### Q: Are there any hardcoded values that you intend to change before (some) deployments?
No
___

### Q: If the codebase is to be deployed on an L2, what should be the behavior of the protocol in case of sequencer issues (if applicable)? Should Sherlock assume that the Sequencer won't misbehave, including going offline?
If the sequencer skips forward in time, it may result in inefficient auctions and missed draws.  The protocol is intended to easily recover from this scenario so Sherlock should assume that the Sequencer won't misbehave.
___

### Q: Should potential issues, like broken assumptions about function behavior, be reported if they could pose risks in future integrations, even if they might not be an issue in the context of the scope? If yes, can you elaborate on properties/invariants that should hold?
There will be many custom prize vaults created by various builders in the future (internal to GenerationSoftware and external). The protocol requires that any integrations they create are not be able to manipulate their chances of winning unfairly.
___

### Q: Please list any known issues/acceptable risks that should not result in a valid finding.
The Witnet RNG is generated via a RANDAO process, but the result is bridged.  Their next upgrade will make the bridging trustless.
___

### Q: Please provide links to previous audits (if any).
https://code4rena.com/reports/2024-03-pooltogether
https://0xmacro.com/library/audits/pooltogether-1
https://code4rena.com/reports/2023-08-pooltogether
https://code4rena.com/reports/2023-07-pooltogether
https://code4rena.com/reports/2022-12-pooltogether
___

### Q: Please list any relevant protocol resources.
https://dev.pooltogether.com
___



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
