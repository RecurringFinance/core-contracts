## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.
-   

### Start

```shell
$ anvil
$ ./deploy_local.sh
```


### Deploy script to local network

```shell
$ forge script scripts/deploy_local.s.sol --rpc-url=http://localhost:8545 --broadcast
```

## Documentation

https://book.getfoundry.sh/

## Usage

### Install Libs

```shell
$ forge install 
$ forge install OpenZeppelin/openzeppelin-contracts
$ forge install foundry-rs/forge-std
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
forge create --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY src/TimedWithdrawal.sol:TimedWithdrawal --constructor-args <BENEFICIARY_ADDRESS> <INTERVAL_IN_SECOND> <AMOUNT_IN_WEI>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

```shell
forge verify-contract <DEPLOYED_CONTRACT_ADDRESS> DistributorFactory --chain arbitrum --constructor-args $(cast abi-encode "constructor(address)" "<DEPLOYER_ADDRESS>") --compiler-version v0.8.27
```

you will need to have the following environment variables set:
ETHERSCAN_API_KEY - your Etherscan API key (replace the value with the one from the chain like arbiscan etc etc)
