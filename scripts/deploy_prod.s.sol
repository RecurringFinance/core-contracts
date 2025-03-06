pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DistributorFactory} from "../src/DistributorFactory.sol";

contract Deploy is Script {
    DistributorFactory distributorFactory;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        distributorFactory = new DistributorFactory();
        console.log("DistributorFactory: ", address(distributorFactory));

        vm.stopBroadcast();
    }
}
