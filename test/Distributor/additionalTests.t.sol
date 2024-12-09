// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../src/Distributor.sol";
import {MockERC20} from "./Distributor.t.sol";
import {CronLibrary} from "../../src/libraries/CronLibrary.sol";

contract AdditionalDistributorTests is Test {
    Distributor public distributor;
    MockERC20 public tokenToDistribute;
    MockERC20 public rewardToken;
    address public owner;

    function setUp() public {
        owner = address(this);
        distributor = new Distributor(owner);
        tokenToDistribute = new MockERC20("Distribute Token", "DST", 1_000_000 ether);
        rewardToken = new MockERC20("Reward Token", "RWT", 1_000_000 ether);

        tokenToDistribute.transfer(address(distributor), 500_000 ether);
        rewardToken.transfer(address(distributor), 500_000 ether);
    }

    // Constructor Tests
    function test_constructor_zero_address() public {
        vm.expectRevert("Owner address cannot be 0x0");
        new Distributor(address(0));
    }

    // Edge Cases for createRecurringPayments
    function test_createRecurringPayments_with_max_beneficiaries() public {
        // Test with a very large number of beneficiaries
        address[] memory beneficiaries = new address[](100);
        uint256[] memory amounts = new uint256[](100);

        for (uint256 i = 0; i < 100; i++) {
            beneficiaries[i] = address(uint160(i + 1));
            amounts[i] = 1 ether;
        }

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 30 days;

        CronLibrary.CronSchedule[] memory intervals = new CronLibrary.CronSchedule[](1);
        intervals[0] = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;

        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = amounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(rewardToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = 1 ether;

        distributor.createRecurringPayments(
            startTimes,
            endTimes,
            intervals,
            beneficiariesArray,
            amountsArray,
            tokens,
            distributionFeeTokens,
            distributionFeeAmounts
        );

        // Verify all beneficiaries were added
        (, , , , , , address[] memory storedBeneficiaries, , ) = distributor.getRecurringPayment(0);
        assertEq(storedBeneficiaries.length, 100);
    }

    // Distribution Edge Cases
    function test_distribute_with_insufficient_balance() public {
        // Setup payment with amount greater than contract balance
        address[] memory beneficiaries = new address[](1);
        beneficiaries[0] = address(0x1);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1_000_000 ether; // More than contract balance

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 30 days;

        CronLibrary.CronSchedule[] memory intervals = new CronLibrary.CronSchedule[](1);
        intervals[0] = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;

        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = amounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(rewardToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = 1 ether;

        distributor.createRecurringPayments(
            startTimes,
            endTimes,
            intervals,
            beneficiariesArray,
            amountsArray,
            tokens,
            distributionFeeTokens,
            distributionFeeAmounts
        );

        vm.warp(block.timestamp + 1 hours);

        vm.expectRevert("Insufficient token balance for distribution");
        distributor.distribute(0, 1);
    }

    // Distribution Fee Tests
    function test_distribution_with_zero_fee_token() public {
        address[] memory beneficiaries = new address[](1);
        beneficiaries[0] = address(0x1);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 30 days;

        CronLibrary.CronSchedule[] memory intervals = new CronLibrary.CronSchedule[](1);
        intervals[0] = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;

        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = amounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(0); // Zero address for fee token

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = 1 ether;

        distributor.createRecurringPayments(
            startTimes,
            endTimes,
            intervals,
            beneficiariesArray,
            amountsArray,
            tokens,
            distributionFeeTokens,
            distributionFeeAmounts
        );

        vm.warp(block.timestamp + 1 hours);
        distributor.distribute(0, 1);

        // Distribution should succeed without sending fee
        (address feeToken, uint256 feeAmount) = distributor.getDistributionFee(0);
        assertEq(feeToken, address(0));
        assertEq(feeAmount, 1 ether);
    }

    // Fallback Tests
    function test_receive_function() public {
        vm.expectRevert("This contract does not accept ETH, use WETH instead");
        payable(address(distributor)).transfer(1 ether);
    }

    function test_fallback_function() public {
        vm.expectRevert("This contract does not accept ETH, use WETH instead");
        (bool success, ) = address(distributor).call{value: 1 ether}("");
        console.log("success: %s", success);
    }

    // Complex Cron Schedule Tests
    function test_complex_cron_schedule() public {
        // Setup a complex schedule: Every Monday and Wednesday at 9am and 5pm in January and July
        uint8[] memory hrs = new uint8[](2);
        hrs[0] = 9; // 9am
        hrs[1] = 17; // 5pm

        uint8[] memory daysOfWeek = new uint8[](2);
        daysOfWeek[0] = 1; // Monday
        daysOfWeek[1] = 3; // Wednesday

        uint8[] memory months = new uint8[](2);
        months[0] = 1; // January
        months[1] = 7; // July

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: hrs,
            daysOfMonth: new uint8[](0),
            months: months,
            daysOfWeek: daysOfWeek
        });

        vm.warp(1704067200); // Monday, January 1, 2024, 12:00 AM

        // Create payment with this schedule
        address[] memory beneficiaries = new address[](1);
        beneficiaries[0] = address(0x1);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 365 days;

        CronLibrary.CronSchedule[] memory intervals = new CronLibrary.CronSchedule[](1);
        intervals[0] = schedule;

        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;

        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = amounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(rewardToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = 1 ether;

        distributor.createRecurringPayments(
            startTimes,
            endTimes,
            intervals,
            beneficiariesArray,
            amountsArray,
            tokens,
            distributionFeeTokens,
            distributionFeeAmounts
        );

        // Test distribution at various times
        vm.warp(1704110400); // Monday, January 1, 2024, 9:00:00 AM
        assertTrue(distributor.canDistribute(0));

        distributor.distribute(0, 1);

        vm.warp(1704146400); // Monday, January 1, 2024, 7:00:00 PM
        assertTrue(distributor.canDistribute(0));

        distributor.distribute(0, 1);

        vm.expectRevert("No periods have passed since last distribution");
        distributor.canDistribute(0);
    }
}
