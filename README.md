<img align="right" width="150" height="150" top="100" src="./assets/gobbler.png">

# Art Gobblers • [![CI](https://github.com/artgobblers/art-gobblers/actions/workflows/tests.yml/badge.svg)](https://github.com/artgobblers/art-gobblers/actions/workflows/tests.yml)

Art Gobblers is an experimental decentralized art factory by Justin Roiland and Paradigm.

## Background

Art Gobblers is a decentralized art factory owned by aliens. As artists make cool art, Gobblers gains cultural relevance, making collectors want the art more, incentivizing artists to make cooler art. It's also an on-chain game.

See our [overview of the system](https://www.paradigm.xyz/2022/09/artgobblers), as well as deep dives into some of the mechanisms used in the project, like [GOO](https://www.paradigm.xyz/2022/09/goo) and [VRGDAs](https://www.paradigm.xyz/2022/08/vrgda).

## Deployments

TBD

## State Diagrams


![Gobbler Lifecycle](assets/state-machines/gobbler-lifecycle.png)
![Legendary Gobbler Auctions](assets/state-machines/legendary-gobbler-auctions.png)
![Page Auctions](assets/state-machines/page-auctions.png)


## Usage

You will need a copy of [Foundry](https://github.com/foundry-rs/foundry) installed before proceeding. See the [installation guide](https://github.com/foundry-rs/foundry#installation) for details.

To build contracts:

```sh
git clone https://github.com/artgobblers/art-gobblers.git
cd art-gobblers
forge build
```

### Run Tests

In order to run unit tests, run: 

```sh
forge test
```

For longer fuzz campaigns, run: 

```sh
FOUNDRY_PROFILE="intense" forge test
```

For differential fuzzing against a python implementation, see [here](./analysis/README.md).

### Update Gas Snapshots

To update the gas snapshot, run: 

```sh
forge snapshot
```

## Audits

Art Gobblers engaged Spearbit and C4 to evaluate the security of these contracts. 

## License

[MIT](LICENSE) Copyright 2022 Art Gobblers