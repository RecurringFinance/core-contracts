# Recurring Finance

A smart contract system for managing automated recurring token payments on EVM chains.

## Overview

This project implements a dead simple decentralized recurring payment system that allows:

- Creation of scheduled token distributions using cron expressions
- Multiple beneficiaries per payment schedule
- Pausable and revocable payments
- Distribution fee mechanisms
- Token withdrawal functionality

### Limitations

- Only supports ERC20 tokens
- The cron schedule is limited to hours

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Rust
- Git

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-name>
```

2. Install dependencies:
```bash
forge install
```

## Development

### Build
```bash
forge build
```

### Test
```bash
forge test
```

### Format Code
```bash
forge fmt
```

### Generate Gas Report
```bash
forge snapshot
```

## Local Development

1. Start local node:

```bash
anvil --block-time 1
```

2. Deploy contracts locally:

```bash
forge script scripts/deploy_local.s.sol --rpc-url=http://localhost:8545 --broadcast
```

> Don't forget to reset your metamask wallet nonce when you restart the node.

## Deployment

To deploy to a network:

```bash
forge create \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY \
  src/Distributor.sol:Distributor \
  --constructor-args $OWNER_ADDRESS
```

### Contract Verification


## Contract Verification for Distributor Factory
```bash
forge verify-contract CONTRACT_ADDRESS ./src/DistributorFactory.sol:DistributorFactory --verifier-url https://api.basescan.org/api --etherscan-api-key API_KEY --chain CHAIN_NAME --compiler-version v0.8.24 --watch
```

## Contract Verification for Distributor
```bash
forge verify-contract CONTRACT_ADDRESS ./src/Distributor.sol:Distributor --verifier-url https://api.basescan.org/api --etherscan-api-key API_KEY --chain CHAIN_NAME --compiler-version v0.8.24 --constructor-args $(cast abi-encode "constructor(address)" OWNER_ADDRESS) --watch
```


Required environment variables:
- `ETH_RPC_URL`: RPC endpoint
- `PRIVATE_KEY`: Deployer's private key
- `ETHERSCAN_API_KEY`: API key for contract verification (use appropriate explorer API key for the target chain)

## Documentation

For detailed contract documentation, see the comments in the Distributor contract:

```1:30:contracts/src/Distributor.sol
// ▗▄▄▖ ▗▄▄▄▖ ▗▄▄▖▗▖ ▗▖▗▄▄▖ ▗▄▄▖ ▗▄▄▄▖▗▖  ▗▖ ▗▄▄▖
// ▐▌ ▐▌▐▌   ▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌  █  ▐▛▚▖▐▌▐▌
// ▐▛▀▚▖▐▛▀▀▘▐▌   ▐▌ ▐▌▐▛▀▚▖▐▛▀▚▖  █  ▐▌ ▝▜▌▐▌▝▜▌
// ▐▌ ▐▌▐▙▄▄▖▝▚▄▄▖▝▚▄▞▘▐▌ ▐▌▐▌ ▐▌▗▄█▄▖▐▌  ▐▌▝▚▄▞▘

// https://recurring.finance

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// OpenZeppelin libraries
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Custom libraries
import "./libraries/DateTimeLibrary.sol";

// Interfaces
import "./interfaces/IDistributor.sol";

/**
 * @title Distributor
 * @notice Manages recurring token payments to multiple beneficiaries with optional rewards
 * @dev Implements reentrancy protection and ownership controls
 */
contract Distributor is ReentrancyGuard, AccessControl, IDistributor {
```


## License

MIT