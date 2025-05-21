# Glue V1

## Description

Glue V1 is a permissionless protocol that allows any ERC20 token or ERC721 Enumerable NFT to become a 'Sticky Token' by associating it with a unique Glue address. Once a token is 'sticky', any ERC20 tokens or ETH can be sent as collateral to its Glue address. Token holders can then burn their Sticky Tokens at any time to withdraw ('unglue') a proportional amount of the collateral assets stored in the Glue.


## Lore:

- 🧴 **Glue Stick**: is the factory contract that glues ERC20 or ERC721E tokens.
- 🍥 **Sticky Asset**: is an asset fueled by glue.
- 💦 **Glue Address**: is the address of the glue that is linked to a Sticky Token.
- 💰 **Glued Collaterals**: are the collateral glued to a Sticky Token (ERC20 and ETH).
- 🔄 **Apply the Glue**: is the action of infusing a token with glue, making it sticky by creating its Glue Address.
- 🔄 **Unglue**: is the action of burning the supply of a Sticky Token to withdraw the corresponding percentage of the collateral.
- 💸 **Glued Loan** is the action of borrowing collateral from multiple glues.
- 🦾 **Glued Hook** is a tool to expand the functionality of the protocol, via integrating the Sticky Asset Standard in your contract.
- 🟢 **Sticky Asset Standard** A common tools to implenet in your contract to expand the Glue functions and simplifying the development process.
- 👽 **Sticky Asset Native** SAN is an asset that is natively compatible with the Sticky Asset Standard.

## Structure:

Glue V1 is composed of 6 smart contracts:

- [**GlueStickERC20**](https://github.com/glue-finance/glue/blob/main/contracts/GlueERC20.sol): is the factory contract that glues ERC20 tokens.
- **GlueStickERC721**: is the factory contract that glues ERC721E tokens.
- **GlueERC20**: is the contract that creates the Glue Address for a Sticky Token.
- **GlueERC721**: is the contract that creates the Glue Address for a Sticky Token.
- **GluedSettings**: is the contract that manages the settings of the protocol.
- **GluedMath**: is the library that contains the math functions used by the protocol.
- **StickyAsset.sol**: is a minimal abstract contract for Glue Protocol Native Assets integration

Glue V1 is composed of 7 interfaces:

- **IGlueStickERC20**: is the interface for the GlueStickERC20 contract.
- **IGlueStickERC721**: is the interface for the GlueStickERC721 contract.
- **IGlueERC20**: is the interface for the GlueERC20 contract.
- **IGlueERC721**: is the interface for the GlueERC721 contract.
- **IGluedSettings**: is the interface for the GluedSettings contract.
- **IGluedLoanReceiver**: is the interface for interacting with Glued Loans and Flash Loans from glues.
- **IGluedHooks**: is the interface that defines callback mechanisms for Sticky Assets to interact with the Glue Protocol.
- **IStickyAsset.sol**: is the xtension interface that defines callback mechanisms for Sticky Assets to interact with the Glue Protocol

## Deployments:

Glue V1 Smart Contracts are originally deployed and verified on:

- 🔷 **Ethereum Mainnet**
- 🔹 **Ethereum Sepolia**
- 🔴 **Optimism Mainnet**
- 🟥 **Optimism Sepolia**
- 🔵 **Base Mainnet**
- 🟦 **Base Sepolia**

We're working on deploying the contracts on more networks, you can check the updated deployments [here](https://todo.com).

The factory contract addresses remain consistent across all supported networks:

| Contract Name      | Address |
|--------------------|---------|
| GlueStickERC20     | 0x49fc990E2E293D5DeB1BC0902f680A3b526a6C60 |
| GlueStickERC721    | 0x049A5F502Fd740E004526fb74ef66b7a6615976B |

## License:

Glue V1 is licensed under the [Business Source License 1.1](https://github.com/glue-finance/glue/blob/main/LICENCE.txt). With an end date of 2029-02-29 or a date specified at [v1-license-date.gluefinance.eth](https://v1-license-date.gluefinance.eth).

The protocol is permissionless, you can both use it and build on top of it, both as a form of public good or for profit. But you can't fork it and deploy it on your own.

**Glue V1** is referred to the entire invention and logic of the protocol, including the deployed contracts, the interfaces, the libraries, the extensions and the documentation. Glue Labs Inc. (Delaware) is the exclusive owner of all intellectual property rights, copyrights, and licensing rights for Glue V1 and its software components, while Glue Labs LTD (BVI) is responsible for the development of smart contracts, their deployment, on-chain royalty enforcement mechanisms, and all future protocol development on the blockchain.

Our Licence enables:

- ✅ Expanding deployed contracts by building applications on top.
- ✅ Earn money by expanding deployed contracts by building applications on top.
- ✅ Build interfaces, applications, and tools that interact with deployed Glue functionalities.
- ✅ Earn money by building interfaces, applications, and tools that interact with deployed Glue functionalities.
- ✅ Develop smart contracts of any kind that interact with deployed Glue functionalities.
- ✅ Earn money by developing smart contracts of any kind that interact with deployed Glue functionalities.
- ✅ Integrate existing protocols and platforms with deployed Glue functionalities.
- ✅ Earn money by integrating existing protocols and platforms with deployed Glue functionalities.
- ✅ Empower the economy of your token or NFT by enabling stickiness.
- ✅ Earn money by empowering the economy of your token or NFT by enabling stickiness.
- ✅ Deploy factory contracts, platforms, smart contracts or any tools that implement StickyAssets.sol while preserving the official GLUE_STICK_20 and GLUE_STICK_721 addresses and maintaining the intended functionality of Glue V1.
- ✅ Earn money by creating factory contracts, platforms, smart contracts or any tools that implement StickyAssets.sol while preserving the official GLUE_STICK_20 and GLUE_STICK_721 addresses and maintaining the intended functionality of Glue V1.
- ✅ Using or customizing StickyAsset for your assets ONLY IF you strictly maintain the original GLUE_STICK_20 and GLUE_STICK_721 addresses and do not alter or bypass the protocol's intended functionality or security measures.
- ✅ Creating customized versions of StickyAsset while preserving the official GLUE_STICK_20 and GLUE_STICK_721 addresses and ensuring proper integration with the official Glue deployment (no counterfeit implementations).
- ✅ Building custom hooks for StickyAsset or your own integrations, provided that these implementations exclusively reference the official GLUE_STICK_20 and GLUE_STICK_721 addresses and never interact with counterfeit or unauthorized deployments of Glue.
- ✅ Earn money by developing and deploying custom hooks that properly integrate with the official Glue protocol addresses and maintain the integrity of the system.

Our Licence doesn't permit:

- ❌ Any uses not listed above.
- ❌ Forking the deployed contracts.
- ❌ Deploying your own identical or customized version of the Glue V1.
- ❌ Deploying your own identical or customized version of the Glue V1 and it's logic written in another programming language.
- ❌ Deploying Glue V1 in not supported chains.
- ❌ Using the Glue V1 name, logo, or branding without permission.
- ❌ Earn money by deploying your own version of the Glue V1.
- ❌ Earn money by using Glue V1 in not supported chains.
- ❌ Earn money by deploying your identical or customized version of Glue V1.
- ❌ Modifying, altering or replacing the GLUE_STICK_20 and GLUE_STICK_721 original addresses in any implementation, or creating StickyAsset variants that bypass or interfere with the intended functionality of the official Glue deployment.
- ❌ Creating hooks, interfaces, or any integration components that reference counterfeit Glue deployments or that circumvent, modify, or bypass the official protocol's security measures or intended behavior.

For details on enforcement rights, license transition timeline, and collaboration opportunities, please refer to the full [license](https://github.com/glue-finance/glue/blob/main/LICENCE.txt).

Have a brilliant idea that pushes beyond our license boundaries? Go to [Licence and Partnerships](http://glue.finance/legal#license) to explore collaboration opportunities.

## BUIDL:

Glue V1 is designed to be expanded to build an entire new DeFi ecosystem empowered by its capabilities.

## Resources:

- [Glue V1 Wiki](https://wiki.glue.finance)
- [Glue V1 License](https://github.com/glue-finance/glue/blob/main/LICENCE.txt)
- [Glue Labs on Discord](https://discord.com/invite/glue-fi)
- [Glue Labs on X](https://x.com/Glue_fi)
- [Glue Labs on Farcaster](https://warpcast.com/~/channel/glue)
- [Glue Interface](https://glue.finance/)
