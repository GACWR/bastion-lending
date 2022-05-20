# Bastion Lending

Bastion Realms, a Hub-and-Spoke design enabling isolated pools and leveraged yield farming. Realms enable full-stack customizability of asset parameters, acts as a sandbox for experimentation with innovative oracle and interest-rate mechanisms, broaden the horizon for DAO-To-DAO partnerships with Bastion, and allows us to list the long-tail of assets.

Isolated pools are separate lending markets which support a set of assets that can be used as collateral to borrow loans against each other. Architecture-wise, think of it as deploying several Compound’s, each a microcosm with their own assets and parameters. This is in contrast to having a single, global cross-collateral pool in which any asset can be borrowed against any other (i.e. a single Compound).

[Read more](https://bastionprotocol.medium.com/introducing-realms-isolated-markets-and-leveraged-yield-farming-80bb88c61ac2)

## Contract Addresses

### Main Hub

| Name              | Address                                                                                                                 |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------- |
| Unitroller        | [0x6De54724e128274520606f038591A00C5E94a1F6](https://aurorascan.dev/address/0x6De54724e128274520606f038591A00C5E94a1F6) |
| Comptroller       | [0xc8f9A66134cAa6bB91c81eE114A0D355a613eA17](https://aurorascan.dev/address/0xc8f9A66134cAa6bB91c81eE114A0D355a613eA17) |
| Oracle            | [0x91A99a522D6fc3A424701B875497279C426C1D70](https://aurorascan.dev/address/0x91A99a522D6fc3A424701B875497279C426C1D70) |
| RewardDistributor | [0x98E8d4b4F53FA2a2d1b9C651AF919Fc839eE4c1a](https://aurorascan.dev/address/0x98E8d4b4F53FA2a2d1b9C651AF919Fc839eE4c1a) |
| CERC20Delegate    | [0xC2bfd8c17804358FA9F0Ad683D2029344180CE5F](https://aurorascan.dev/address/0xC2bfd8c17804358FA9F0Ad683D2029344180CE5F) |
| cWBTC             | [0xfa786baC375D8806185555149235AcDb182C033b](https://aurorascan.dev/address/0xfa786baC375D8806185555149235AcDb182C033b) |
| cETH              | [0x4E8fE8fd314cFC09BDb0942c5adCC37431abDCD0](https://aurorascan.dev/address/0x4E8fE8fd314cFC09BDb0942c5adCC37431abDCD0) |
| cNEAR             | [0x8C14ea853321028a7bb5E4FB0d0147F183d3B677](https://aurorascan.dev/address/0x8C14ea853321028a7bb5E4FB0d0147F183d3B677) |
| cUSDC             | [0xe5308dc623101508952948b141fD9eaBd3337D99](https://aurorascan.dev/address/0xe5308dc623101508952948b141fD9eaBd3337D99) |
| cUSDT             | [0x845E15A441CFC1871B7AC610b0E922019BaD9826](https://aurorascan.dev/address/0x845E15A441CFC1871B7AC610b0E922019BaD9826) |
| Maximillion       | [0x9ee25DE4C39CFFD97b3bc9975A25B92dD1489E6D](https://aurorascan.dev/address/0x9ee25DE4C39CFFD97b3bc9975A25B92dD1489E6D) |

### Aurora Realm

| Name              | Address                                                                                                                 |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------- |
| Unitroller        | [0xe1cf09BDa2e089c63330F0Ffe3F6D6b790835973](https://aurorascan.dev/address/0xe1cf09BDa2e089c63330F0Ffe3F6D6b790835973) |
| Comptroller       | [0xc8f9A66134cAa6bB91c81eE114A0D355a613eA17](https://aurorascan.dev/address/0xc8f9A66134cAa6bB91c81eE114A0D355a613eA17) |
| Oracle            | [0x4Fa59CaE2b1e0d3BBADB3385Ba29B0B35822e8aD](https://aurorascan.dev/address/0x4Fa59CaE2b1e0d3BBADB3385Ba29B0B35822e8aD) |
| RewardDistributor | [0xF9C3a8cF63154A5bD1a87b6f49575d47b7F713Bd](https://aurorascan.dev/address/0xF9C3a8cF63154A5bD1a87b6f49575d47b7F713Bd) |
| CERC20Delegate    | [0xC2bfd8c17804358FA9F0Ad683D2029344180CE5F](https://aurorascan.dev/address/0xC2bfd8c17804358FA9F0Ad683D2029344180CE5F) |
| cAURORA           | [0x94FA9979751a74e6b133Eb95Aeca8565c0809BaB](https://aurorascan.dev/address/0x94FA9979751a74e6b133Eb95Aeca8565c0809BaB) |
| cUSDC             | [0x8E9FB3f2cc8b08184CB5FB7BcDC61188E80C3cB0](https://aurorascan.dev/address/0x8E9FB3f2cc8b08184CB5FB7BcDC61188E80C3cB0) |
| cTRI              | [0x86538Ca055E7Fd992A26c5604F349e2ede3ce42D](https://aurorascan.dev/address/0x86538Ca055E7Fd992A26c5604F349e2ede3ce42D) |
| cBSTN             | [0x08Ac1236ae3982EC9463EfE10F0F320d9F5A9A4b](https://aurorascan.dev/address/0x08Ac1236ae3982EC9463EfE10F0F320d9F5A9A4b) |

### STNear Realm

| Name              | Address                                                                                                                 |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------- |
| Unitroller        | [0xE550A886716241AFB7ee276e647207D7667e1E79](https://aurorascan.dev/address/0xE550A886716241AFB7ee276e647207D7667e1E79) |
| Comptroller       | [0xc8f9A66134cAa6bB91c81eE114A0D355a613eA17](https://aurorascan.dev/address/0xc8f9A66134cAa6bB91c81eE114A0D355a613eA17) |
| NEAROracle        | [0x0617104180d049D2dda1349C6Aaad27087DD8A70](https://aurorascan.dev/address/0x0617104180d049D2dda1349C6Aaad27087DD8A70) |
| RewardDistributor | [0xd7A812a5d2CC96e78C83B0324c82269EE82aF1c8](https://aurorascan.dev/address/0xd7A812a5d2CC96e78C83B0324c82269EE82aF1c8) |
| CERC20Delegate    | [0xC2bfd8c17804358FA9F0Ad683D2029344180CE5F](https://aurorascan.dev/address/0xC2bfd8c17804358FA9F0Ad683D2029344180CE5F) |
| cSTNEAR           | [0xB76108eb764b4427505c4bb020A37D95b3ef5AFE](https://aurorascan.dev/address/0xB76108eb764b4427505c4bb020A37D95b3ef5AFE) |
| cNEAR             | [0x4A45075D3E752F3676610Fc427F5E6915Ce63A63](https://aurorascan.dev/address/0x4A45075D3E752F3676610Fc427F5E6915Ce63A63) |

### Multichain Realm

| Name              | Address                                                                                                                 |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------- |
| Unitroller        | [0xA195b3d7AA34E47Fb2D2e5A682DF2d9EFA2daF06](https://aurorascan.dev/address/0xA195b3d7AA34E47Fb2D2e5A682DF2d9EFA2daF06) |
| Comptroller       | [0xc8f9A66134cAa6bB91c81eE114A0D355a613eA17](https://aurorascan.dev/address/0xc8f9A66134cAa6bB91c81eE114A0D355a613eA17) |
| Oracle            | [0x71EbeA24B18f6ecF97c5a5bCaEf3e0639575f08C](https://aurorascan.dev/address/0x71EbeA24B18f6ecF97c5a5bCaEf3e0639575f08C) |
| RewardDistributor | [0xeCa5553ed50cF52aa34c1F9242aEcfD1e7A7667F](https://aurorascan.dev/address/0xeCa5553ed50cF52aa34c1F9242aEcfD1e7A7667F) |
| CERC20Delegate    | [0xC2bfd8c17804358FA9F0Ad683D2029344180CE5F](https://aurorascan.dev/address/0xC2bfd8c17804358FA9F0Ad683D2029344180CE5F) |
| cSTNEAR           | [0x30Fff4663A8DCDd9eD81e60acF505e6159f19BbC](https://aurorascan.dev/address/0x30Fff4663A8DCDd9eD81e60acF505e6159f19BbC) |
| cUSDC             | [0x10a9153A7b4da83Aa1056908C710f1aaCCB3Ef85](https://aurorascan.dev/address/0x10a9153A7b4da83Aa1056908C710f1aaCCB3Ef85) |

### Lockdrop Vault

| Name  | Duration | Address                                                                                                                 |
| :---- | :------- | :---------------------------------------------------------------------------------------------------------------------- |
| cUSDC | 1 Month  | [0x1d5BF719ba2B0650261EaC4C1d53C0FE23FDDCfC](https://aurorascan.dev/address/0x1d5BF719ba2B0650261EaC4C1d53C0FE23FDDCfC) |
| cUSDC | 3 Month  | [0xa76C8AaF73a1F78058F55fC871D147fa835Fdaeb](https://aurorascan.dev/address/0xa76C8AaF73a1F78058F55fC871D147fa835Fdaeb) |
| cUSDC | 6 Month  | [0xeC04363fe0f2D11637a68B5e2f2478B6f323d6c0](https://aurorascan.dev/address/0xeC04363fe0f2D11637a68B5e2f2478B6f323d6c0) |
| cUSDC | 9 Month  | [0x93606dE4b66B2995ee9C8fF609Efa18Aa2565a33](https://aurorascan.dev/address/0x93606dE4b66B2995ee9C8fF609Efa18Aa2565a33) |
| cUSDC | 12 Month | [0xcf5eCb7B6341DD8Db0315181E18A41E66a61bAFd](https://aurorascan.dev/address/0xcf5eCb7B6341DD8Db0315181E18A41E66a61bAFd) |
| cUSDT | 1 Month  | [0xc671266Df558c1af70a531B81c2323Eec46aB679](https://aurorascan.dev/address/0xc671266Df558c1af70a531B81c2323Eec46aB679) |
| cUSDT | 3 Month  | [0x4E38935Fa862f57420c9275F8C25EDf9daF79779](https://aurorascan.dev/address/0x4E38935Fa862f57420c9275F8C25EDf9daF79779) |
| cUSDT | 6 Month  | [0xd4Ad7D5D24464775926b32d8d67abd5B4b12F1c8](https://aurorascan.dev/address/0xd4Ad7D5D24464775926b32d8d67abd5B4b12F1c8) |
| cUSDT | 9 Month  | [0x10Aa3e77B449B5f784ecd0561e9a04dBacAC31B4](https://aurorascan.dev/address/0x10Aa3e77B449B5f784ecd0561e9a04dBacAC31B4) |
| cUSDT | 12 Month | [0x1f0121871aE965D9d1Df9b8FdB6f76ed61F56071](https://aurorascan.dev/address/0x1f0121871aE965D9d1Df9b8FdB6f76ed61F56071) |
| cETH  | 1 Month  | [0xF7c1695b2b0bab31a18E4f6d948E7b8d00610088](https://aurorascan.dev/address/0xF7c1695b2b0bab31a18E4f6d948E7b8d00610088) |
| cETH  | 3 Month  | [0x635fFD6161461A744ee28a402c31dC629AF4c711](https://aurorascan.dev/address/0x635fFD6161461A744ee28a402c31dC629AF4c711) |
| cETH  | 6 Month  | [0x571535E61Cc879a970f192256ca4ebd529B6fD9c](https://aurorascan.dev/address/0x571535E61Cc879a970f192256ca4ebd529B6fD9c) |
| cETH  | 9 Month  | [0xdc2c4360B0475a14069596C6507A113bDA57dAff](https://aurorascan.dev/address/0xdc2c4360B0475a14069596C6507A113bDA57dAff) |
| cETH  | 12 Month | [0x290E8883BaE736EaFaeDe08fFCc67715A5A0E9D8](https://aurorascan.dev/address/0x290E8883BaE736EaFaeDe08fFCc67715A5A0E9D8) |
| cNEAR | 1 Month  | [0x66BED5e5479f9bB94f5af4EEA7AB35e7EF73f3C1](https://aurorascan.dev/address/0x66BED5e5479f9bB94f5af4EEA7AB35e7EF73f3C1) |
| cNEAR | 3 Month  | [0x20e93F4Dd415442B05D8cDFdA52655B24d639838](https://aurorascan.dev/address/0x20e93F4Dd415442B05D8cDFdA52655B24d639838) |
| cNEAR | 6 Month  | [0x6891bC4858D70BDaD3d861d237aEA0D267053dBa](https://aurorascan.dev/address/0x6891bC4858D70BDaD3d861d237aEA0D267053dBa) |
| cNEAR | 9 Month  | [0xa087F3FE88626EFcA2262C86c39C59B2b47005Db](https://aurorascan.dev/address/0xa087F3FE88626EFcA2262C86c39C59B2b47005Db) |
| cNEAR | 12 Month | [0x6ff6c9c2EAe76138432f53022a9F801ed0165eca](https://aurorascan.dev/address/0x6ff6c9c2EAe76138432f53022a9F801ed0165eca) |
| cWBTC | 1 Month  | [0xaAbe4929501e970dE68056f521588Bf32eddde42](https://aurorascan.dev/address/0xaAbe4929501e970dE68056f521588Bf32eddde42) |
| cWBTC | 3 Month  | [0x8B6f30d513105b278281bBd3381E5F4BE59A3C56](https://aurorascan.dev/address/0x8B6f30d513105b278281bBd3381E5F4BE59A3C56) |
| cWBTC | 6 Month  | [0x2B836903c10482E6dD4D14E421c476c598a26722](https://aurorascan.dev/address/0x2B836903c10482E6dD4D14E421c476c598a26722) |
| cWBTC | 9 Month  | [0x2578AdE2442c08ac6F5D463CfBe0612ABeF93867](https://aurorascan.dev/address/0x2578AdE2442c08ac6F5D463CfBe0612ABeF93867) |
| cWBTC | 12 Month | [0xA15e2B3af919EE105Ff13715b1739ED9daD676F8](https://aurorascan.dev/address/0xA15e2B3af919EE105Ff13715b1739ED9daD676F8) |
