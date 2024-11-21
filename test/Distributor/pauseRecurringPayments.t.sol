// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../src/DistributorFactory.sol";
import "../../src/interfaces/IDistributor.sol";
import {MockERC20} from "./Distributor.t.sol";
import {console2} from "forge-std/console2.sol"; // Change this import
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract PauseRecurringPaymentsTest is Test {
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
    function createBasicRecurringPayment() internal returns (uint256) {
        address[] memory beneficiaries = new address[](1);
        beneficiaries[0] = address(0x1);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10 ether;

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp;
        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 30 days;

        CronLibrary.CronSchedule[] memory intervals = new CronLibrary.CronSchedule[](1);
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
        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);
        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = 1 ether;

        distributor.createRecurringPayments(
            startTimes,
            endTimes,
            intervals,
            beneficiariesArray,
            amountsArray,
            tokens,
            rewardTokens,
            rewardAmounts
        );

        return distributor.recurringPaymentCounter() - 1;
    }

    function test_pauseRecurringPayments_pause_recurring_payment() public {
        uint256 paymentId = createBasicRecurringPayment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        distributor.pausePayments(paymentIds);

        (, , , , , , , , uint256 pausedAt, , ) = distributor.getRecurringPayment(paymentId);
        assertEq(pausedAt, block.timestamp);
    }

    function test_pauseRecurringPayments_pause_multiple_recurring_payments() public {
        // Create first payment
        uint256 firstPaymentId = createBasicRecurringPayment();

        // Create second payment
        uint256 secondPaymentId = createBasicRecurringPayment();

        uint256[] memory paymentIds = new uint256[](2);
        paymentIds[0] = firstPaymentId;
        paymentIds[1] = secondPaymentId;

        distributor.pausePayments(paymentIds);

        // Check both payments are paused
        (, , , , , , , , uint256 firstPausedAt, , ) = distributor.getRecurringPayment(firstPaymentId);
        (, , , , , , , , uint256 secondPausedAt, , ) = distributor.getRecurringPayment(secondPaymentId);

        assertEq(firstPausedAt, block.timestamp);
        assertEq(secondPausedAt, block.timestamp);
    }

    function test_pauseRecurringPayments_cannot_distribute_when_paused() public {
        uint256 paymentId = createBasicRecurringPayment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        distributor.pausePayments(paymentIds);

        vm.expectRevert("Recurring payment is paused");
        distributor.distribute(paymentId, 10);
    }

    function test_pauseRecurringPayments_cannot_pause_already_paused_payment() public {
        uint256 paymentId = createBasicRecurringPayment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        distributor.pausePayments(paymentIds);

        vm.expectRevert("Payment already paused");
        distributor.pausePayments(paymentIds);
    }

    function test_pauseRecurringPayments_unpause_recurring_payment() public {
        uint256 paymentId = createBasicRecurringPayment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        distributor.pausePayments(paymentIds);

        // Wait some time
        vm.warp(block.timestamp + 1 days);

        distributor.unpausePayments(paymentIds);

        (, , , , , , , , uint256 pausedAt, uint256 pausedDuration, ) = distributor.getRecurringPayment(paymentId);
        assertEq(pausedAt, 0);
        assertEq(pausedDuration, 1 days + 1 seconds);
    }

    function test_pauseRecurringPayments_cannot_unpause_non_paused_payment() public {
        uint256 paymentId = createBasicRecurringPayment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        vm.expectRevert("Payment not paused");
        distributor.unpausePayments(paymentIds);
    }

    function test_pauseRecurringPayments_pause_and_unpause_multiple_times() public {
        uint256 paymentId = createBasicRecurringPayment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        // First pause for 1 day
        distributor.pausePayments(paymentIds);
        vm.warp(block.timestamp + 1 days);
        distributor.unpausePayments(paymentIds);

        // Second pause for 2 days
        distributor.pausePayments(paymentIds);
        vm.warp(block.timestamp + 2 days);
        distributor.unpausePayments(paymentIds);

        (, , , , , , , , uint256 pausedAt, uint256 unPausedAt, ) = distributor.getRecurringPayment(paymentId);
        console2.log("Paused at :", pausedAt);
        console2.log("Unpaused at :", unPausedAt);
        assertEq(pausedAt, 0);
        // total paused time should be 3 days
        assertEq(unPausedAt, 3 days + 1 seconds);
    }

    function test_pauseRecurringPayments_pause_and_unpause_multiple_times_with_distribution() public {
        uint256 paymentId = createBasicRecurringPayment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        // Move forward 1 day, so 2 periods has passed since we start at 0
        vm.warp(vm.getBlockTimestamp() + 1 days);

        // 1 period can be distributed
        (uint256 periods, ) = distributor.periodsToDistribute(paymentId, 10);
        assertEq(periods, 2);

        // First pause for 1 day
        distributor.pausePayments(paymentIds);
        vm.warp(vm.getBlockTimestamp() + 1 days);
        distributor.unpausePayments(paymentIds);

        (, , , , , , , , , uint256 unPausedAt0, ) = distributor.getRecurringPayment(paymentId);

        console2.log("unPausedAt 0 :", unPausedAt0);

        assertEq(unPausedAt0, 2 days + 1 seconds);

        // only 1 period can be distributed
        (periods, ) = distributor.periodsToDistribute(paymentId, 10);
        assertEq(periods, 1);

        // distribute the payment for the first period
        distributor.distribute(paymentId, 10);

        // no more periods to distribute
        (periods, ) = distributor.periodsToDistribute(paymentId, 10);
        assertEq(periods, 0);

        // Second pause for 2 days
        distributor.pausePayments(paymentIds);
        vm.warp(vm.getBlockTimestamp() + 2 days);
        distributor.unpausePayments(paymentIds);

        (, , , , , , , , uint256 pausedAt, uint256 unPausedAt1, ) = distributor.getRecurringPayment(paymentId);

        console2.log("unPausedAt 1 :", unPausedAt1);
        assertEq(pausedAt, 0);
        // total paused time should be 2 days
        assertEq(unPausedAt1, 4 days + 1 seconds);
        // only 1 period can be distributed
        (periods, ) = distributor.periodsToDistribute(paymentId, 10);
        assertEq(periods, 1);
    }

    function test_pauseRecurringPayments_only_owner_can_pause() public {
        uint256 paymentId = createBasicRecurringPayment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        address nonOwner = address(0x123);
        vm.prank(nonOwner);
        vm.expectRevert();
        // abi.encodeWithSelector(
        //     IAccessControl.AccessControlUnauthorizedAccount.selector,
        //     nonOwner,
        //     distributor.DEFAULT_ADMIN_ROLE()
        // )
        distributor.pausePayments(paymentIds);
    }

    function test_pauseRecurringPayments_only_owner_can_unpause() public {
        uint256 paymentId = createBasicRecurringPayment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        distributor.pausePayments(paymentIds);

        address nonOwner = address(0x123);
        vm.prank(nonOwner);
        vm.expectRevert();
        // abi.encodeWithSelector(
        //     IAccessControl.AccessControlUnauthorizedAccount.selector,
        //     nonOwner,
        //     distributor.DEFAULT_ADMIN_ROLE()
        // )
        distributor.unpausePayments(paymentIds);
    }

    function test_pauseRecurringPayments_periods_not_distributed_before_pause_are_lost() public {
        uint256 paymentId = createBasicRecurringPayment();
        paymentId = 0;

        // Move forward 5 days
        vm.warp(block.timestamp + 5 days);
        (uint256 periodsBP, ) = distributor.periodsToDistribute(paymentId, 100);
        console2.log("Periods before pause :", periodsBP);

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = 0;

        // Pause for 3 days
        distributor.pausePayments(paymentIds);
        vm.warp(block.timestamp + 3 days);
        distributor.unpausePayments(paymentIds);

        // Move forward 2 more days
        vm.warp(block.timestamp + 2 days);

        // Should have 7 periods (5 days before pause + 2 days after pause - 3 days during pause = 4 periods)
        (uint256 periods, ) = distributor.periodsToDistribute(paymentId, 100);
        console2.log("Periods :", periods);
        assertEq(periods, 3);
    }

    function test_pauseRecurringPayments_periods_distributed_before_pause_are_preserved() public {
        uint256 paymentId = createBasicRecurringPayment();

        // Move forward 5 days
        vm.warp(block.timestamp + 5 days);

        // Distribute 3 periods
        distributor.distribute(paymentId, 3);

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        // Pause for 2 days
        distributor.pausePayments(paymentIds);
        vm.warp(block.timestamp + 2 days);
        distributor.unpausePayments(paymentIds);

        // Move forward 3 more days
        vm.warp(block.timestamp + 3 days);

        (uint256 periods, ) = distributor.periodsToDistribute(paymentId, 10);
        assertEq(periods, 4);

        // We should be able to distribute these remaining periods
        distributor.distribute(paymentId, 3);
    }
}
