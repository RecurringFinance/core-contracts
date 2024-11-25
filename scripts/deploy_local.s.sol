pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DistributorFactory} from "../src/DistributorFactory.sol";
import "../test/tokens/USDC.sol";
import "../test/tokens/WrappedETH.sol";
import "../test/tokens/TestToken.sol";

contract Deploy is Script {
    uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 user1PrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    address user1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address user2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address user3 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address user4 = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;

    address deployer = vm.addr(deployerPrivateKey);

    DistributorFactory distributorFactory;
    USDC usdc;
    WrappedETH weth;
    TestToken testToken;

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        uint256 initialUSDCSupply = 1000000000000;
        uint256 initialWethAmount = 10000000000000000000000000000;

        distributorFactory = new DistributorFactory();
        usdc = new USDC(initialUSDCSupply);
        testToken = new TestToken(initialUSDCSupply);
        weth = new WrappedETH();
        weth.getFaucet(initialWethAmount);

        uint256 amount = 100000000;
        uint256 wethAmount = 10000000000000000000;

        usdc.transfer(user1, amount);
        weth.transfer(user1, wethAmount);

        usdc.transfer(user2, amount);
        weth.transfer(user2, wethAmount);

        usdc.transfer(user3, amount);
        weth.transfer(user3, wethAmount);

        usdc.transfer(user4, amount);
        weth.transfer(user4, wethAmount);

        vm.stopBroadcast();

        vm.startBroadcast(user1PrivateKey);
        distributorFactory.newDistributor(user1);
        vm.stopBroadcast();

        console.log("DistributorFactory: ", address(distributorFactory));
        console.log("USDC: ", address(usdc));
        console.log("WETH: ", address(weth));
        console.log("TestToken: ", address(testToken));
    }
}
