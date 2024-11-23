// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../src/Distributor.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 Token for testing
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

// Helper contract to test contract-to-contract calls
contract CallerContract {
    function callDistribute(Distributor _distributor, uint256 _recurringPaymentId) public {
        _distributor.distribute(_recurringPaymentId, 100);
    }
}
