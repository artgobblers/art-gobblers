<img align="right" width="150" height="150" top="100" src="./assets/gobbler.png">

# Art Gobblers (Smart Contracts) • [![CI](https://github.com/FrankieIsLost/art-gobblers/actions/workflows/CI.yml/badge.svg)](https://github.com/FrankieIsLost/art-gobblers/actions/workflows/CI.yml)

Art Gobblers scan the cosmos in search of art producing life.

![Gobbler Lifecycle](assets/state-machines/gobbler-lifecycle.png)
![Leader Gobbler Auctions](assets/state-machines/leader-gobbler-auctions.png)
![Page Auctions](assets/state-machines/page-auctions.png)

## Contributing

You will need a copy of [Foundry](https://github.com/gakonst/foundry) installed before proceeding. See the [installation guide](https://github.com/gakonst/foundry#installation) for details.

### Setup

```sh
git clone https://github.com/FrankieIsLost/art-gobblers.git
cd art-gobblers
```

### Run Tests

```sh
forge test
```

### Update Gas Snapshots

```sh
forge snapshot
```
