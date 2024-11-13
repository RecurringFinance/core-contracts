// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Distributor} from "../../src/Distributor.sol";
import {MockERC20} from "./Distributor.t.sol";

contract SettersTest is Test {
    Distributor public distributor;
    MockERC20 public token;
    MockERC20 public rewardToken;
    address public owner;
    address[] public beneficiaries;
    uint256[] public amounts;

    function setUp() public {
        owner = address(this);
        distributor = new Distributor(owner);
        token = new MockERC20("Distribute Token", "DST", 1_000_000 ether);
        rewardToken = new MockERC20("Reward Token", "RWT", 1_000_000 ether);

        // Setup initial recurring payment
        beneficiaries = new address[](2);
        beneficiaries[0] = address(0x1);
        beneficiaries[1] = address(0x2);

        amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 1 days;

        uint256[] memory periodIntervals = new uint256[](1);
        periodIntervals[0] = 1 days;

        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;

        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = amounts;

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = 10;

        distributor.createRecurringPayments(
            startTimes,
            endTimes,
            periodIntervals,
            beneficiariesArray,
            amountsArray,
            tokens,
            rewardTokens,
            rewardAmounts
        );
    }

    function test_setReward() public {
        address newRewardToken = address(0x5);
        uint256 newRewardAmount = 500;

        distributor.setDistributionFee(0, newRewardToken, newRewardAmount);

        (address updatedRewardToken, uint256 updatedRewardAmount) = distributor.getDistributionFee(0);

        assertEq(updatedRewardToken, newRewardToken);
        assertEq(updatedRewardAmount, newRewardAmount);
    }
}
