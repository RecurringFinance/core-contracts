// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../src/DistributorFactory.sol";
import "../../src/interfaces/IDistributor.sol";
import "../../src/libraries/DateTimeLibrary.sol";
import {MockERC20} from "./Distributor.t.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DistributeRecurringPaymentsTest is Test {
    address public owner;
    Distributor public distributor;
    MockERC20 public tokenToDistribute;
    MockERC20 public rewardToken;

    function setUp() public {
        owner = address(this);

        // Deploy mock tokens
        tokenToDistribute = new MockERC20("Distribute Token", "DST", 1_000_000 ether);
        rewardToken = new MockERC20("Reward Token", "RWT", 1_000_000 ether);

        // Deploy Distributor with the owner address
        distributor = new Distributor(owner);

        // Transfer tokens to Distributor contract
        tokenToDistribute.transfer(address(distributor), 500_000 ether);
        rewardToken.transfer(address(distributor), 500_000 ether);
    }

    // Helper function to create a basic recurring payment
    function create_basic_recurring_payment() internal returns (uint256) {
        address[] memory beneficiaries = new address[](2);
        beneficiaries[0] = address(0x1);
        beneficiaries[1] = address(0x2);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10 ether;
        amounts[1] = 15 ether;

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;
        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 30 days;

        CronLibrary.CronSchedule[] memory intervals = new CronLibrary.CronSchedule[](1);

        // every day at 00:00 = 0 * * *
        intervals[0] = CronLibrary.CronSchedule({
            hrs: new uint8[](1),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });
        intervals[0].hrs[0] = 0;

        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;
        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = amounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);
        address[] memory rewardTokensArray = new address[](1);
        rewardTokensArray[0] = address(rewardToken);
        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = 1 ether;

        distributor.createRecurringPayments(
            startTimes,
            endTimes,
            intervals,
            beneficiariesArray,
            amountsArray,
            tokens,
            rewardTokensArray,
            rewardAmounts
        );

        return distributor.recurringPaymentCounter() - 1;
    }

    function test_distributeRecurringPayments_should_fail_if_not_started() public {
        uint256 recurringPaymentId = create_basic_recurring_payment();

        vm.expectRevert("Recurring payment period did not start yet");
        distributor.distribute(recurringPaymentId, 10);
    }

    function test_distributeRecurringPayments_should_distribute_successfully_after_start_time() public {
        uint256 recurringPaymentId = create_basic_recurring_payment();

        console.log("block.timestamp", block.timestamp);

        // Move forward 24 hours
        vm.warp(block.timestamp + 24 hours);
        console.log("AFTER warp block.timestamp", block.timestamp);

        (, uint256 nextDistributionStartTime) = distributor.periodsToDistribute(recurringPaymentId, 10);
        console.log("nextDistributionStartTime", nextDistributionStartTime);

        assertEq(nextDistributionStartTime + 1 seconds, block.timestamp + 24 hours);

        distributor.distribute(recurringPaymentId, 10);

        (, , , uint256 distributedUpToTime, uint256 lastDistributionTime, , , , ) = distributor.getRecurringPayment(
            recurringPaymentId
        );
        console.log("lastDistributionTime", lastDistributionTime);
        console.log("distributed up to time", distributedUpToTime);
        assertEq(lastDistributionTime, block.timestamp);
        assertEq(distributedUpToTime + 1 seconds, block.timestamp);

        (uint256 periodsToDistribute1, uint256 nextDistributionStartTime1) = distributor.periodsToDistribute(
            recurringPaymentId,
            10
        );
        console.log("nextDistributionStartTime1", nextDistributionStartTime1);
        console.log("periodsToDistribute1", periodsToDistribute1);

        // assertEq(nextDistributionStartTime1 + 1 seconds, block.timestamp + 48 hours);
        assertEq(periodsToDistribute1, 0);

        vm.warp(block.timestamp + 2 hours);

        (uint256 periodsToDistribute2, uint256 nextDistributionStartTime2) = distributor.periodsToDistribute(
            recurringPaymentId,
            10
        );
        console.log("nextDistributionStartTime2", nextDistributionStartTime2);
        console.log("periodsToDistribute2", periodsToDistribute2);
    }

    function test_distributeRecurringPayments_should_fail_if_no_period_passed_since_last_distribution() public {
        uint256 recurringPaymentId = create_basic_recurring_payment();

        // Move forward 2 days
        vm.warp(block.timestamp + 2 days);

        // distribute the first period
        distributor.distribute(recurringPaymentId, 10);

        // Move forward 1 hour
        vm.warp(block.timestamp + 1 hours);

        vm.expectRevert("No periods have passed since last distribution");
        distributor.distribute(recurringPaymentId, 10);
    }

    function test_distributeRecurringPayments_should_fail_if_distributed_a_second_time_in_the_same_hour() public {
        uint256 recurringPaymentId = create_basic_recurring_payment();

        // Move forward 2 days
        vm.warp(block.timestamp + 2 days);

        // distribute the first period
        distributor.distribute(recurringPaymentId, 10);

        vm.expectRevert("No periods have passed since last distribution");
        distributor.distribute(recurringPaymentId, 10);
    }

    function test_distributeRecurringPayments_should_work_even_if_end_time_is_in_the_past() public {
        uint256 recurringPaymentId = create_basic_recurring_payment();

        // Move forward 31 days
        vm.warp(block.timestamp + 31 days);

        distributor.distribute(recurringPaymentId, 100);
        (uint256 periodsToDistribute, uint256 nextDistributionStartTime) = distributor.periodsToDistribute(
            recurringPaymentId,
            100
        );

        (, , , , uint256 lastDistributionTime, , , , ) = distributor.getRecurringPayment(recurringPaymentId);
        console.log("lastDistributionTime", lastDistributionTime);
        console.log("nextDistributionStartTime", nextDistributionStartTime);
        console.log("periodsToDistribute", periodsToDistribute);
        console.log("block.timestamp", block.timestamp);

        assertEq(nextDistributionStartTime + 1 days + 1 seconds, block.timestamp);
    }

    function test_distributeRecurringPayments_should_fail_if_distribution_is_after_end_time() public {
        uint256 recurringPaymentId = create_basic_recurring_payment();

        // Move forward 30 days
        vm.warp(block.timestamp + 30 days);

        // distribute all the periods
        distributor.distribute(recurringPaymentId, 30);

        // Move forward 1 day
        vm.warp(block.timestamp + 1 days);

        // no more periods to distribute and payment has ended
        vm.expectRevert("Recurring payment has ended");
        distributor.distribute(recurringPaymentId, 10);
    }
}
