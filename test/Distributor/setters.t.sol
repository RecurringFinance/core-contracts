// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Distributor} from "../../src/Distributor.sol";
import {IDistributor} from "../../src/interfaces/IDistributor.sol";
import {MockERC20} from "./Distributor.t.sol";
import {CronLibrary} from "../../src/libraries/CronLibrary.sol";

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

        CronLibrary.CronSchedule[] memory periodIntervals = new CronLibrary.CronSchedule[](1);
        periodIntervals[0] = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

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

    function test_setEndTime() public {
        uint256 newEndTime = block.timestamp + 7 days;

        distributor.setEndTime(0, newEndTime);

        (, uint256 endTime, , , , , , , ) = distributor.getRecurringPayment(0);

        assertEq(endTime, newEndTime);
    }

    function test_setEndTime_RevertIfNotOwner() public {
        uint256 newEndTime = block.timestamp + 7 days;

        vm.prank(address(0xdead));
        vm.expectRevert();
        distributor.setEndTime(0, newEndTime);
    }

    function test_setEndTime_RevertIfBeforeCurrentTime() public {
        uint256 newEndTime = block.timestamp - 1;

        vm.expectRevert("New end time must be in the future");
        distributor.setEndTime(0, newEndTime);
    }

    function test_setEndTime_RevertIfInvalidDistributionId() public {
        uint256 newEndTime = block.timestamp + 7 days;

        vm.expectRevert("Invalid recurring payment id");
        distributor.setEndTime(999, newEndTime);
    }
}
