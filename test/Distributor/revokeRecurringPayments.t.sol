// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../src/DistributorFactory.sol";
import "../../src/interfaces/IDistributor.sol";
import {MockERC20} from "./Distributor.t.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RevokeRecurringPaymentTest is Test {
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
        // uint256[] memory intervals = new uint256[](1);
        // intervals[0] = 1 days;
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

    function test_revokeRecurringPayments_single_payment_successfully() public {
        uint256 paymentId = create_basic_recurring_payment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        distributor.revokeRecurringPayments(paymentIds);

        (, , , , , , , , bool revoked) = distributor.getRecurringPayment(0);

        assertTrue(revoked, "Recurring payment should be revoked");
    }

    function test_revokeRecurringPayments_multiple_payments_successfully() public {
        uint256 firstPaymentId = create_basic_recurring_payment();
        uint256 secondPaymentId = create_basic_recurring_payment();

        uint256[] memory paymentIds = new uint256[](2);
        paymentIds[0] = firstPaymentId;
        paymentIds[1] = secondPaymentId;

        distributor.revokeRecurringPayments(paymentIds);

        (, , , , , , , , bool revokedFirst) = distributor.getRecurringPayment(firstPaymentId);
        (, , , , , , , , bool revokedSecond) = distributor.getRecurringPayment(secondPaymentId);

        assertTrue(revokedFirst, "First recurring payment should be revoked");
        assertTrue(revokedSecond, "Second recurring payment should be revoked");
    }

    function test_revokeRecurringPayments_cannot_revoke_nonexistent_payment() public {
        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = 999;

        vm.expectRevert("Invalid recurring payment id");
        distributor.revokeRecurringPayments(paymentIds);
    }

    function test_revokeRecurringPayments_cannot_revoke_already_revoked() public {
        uint256 paymentId = create_basic_recurring_payment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        distributor.revokeRecurringPayments(paymentIds);

        vm.expectRevert("Recurring payment already revoked");
        distributor.revokeRecurringPayments(paymentIds);
    }

    function test_revokeRecurringPayments_only_owner_can_revoke() public {
        uint256 paymentId = create_basic_recurring_payment();
        address nonOwner = address(0x123);

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        vm.prank(nonOwner);
        // TODO: expect actual error message
        // vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        vm.expectRevert();
        distributor.revokeRecurringPayments(paymentIds);
    }

    function test_revokeRecurringPayments_updates_revoked_status() public {
        uint256 paymentId = create_basic_recurring_payment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        distributor.revokeRecurringPayments(paymentIds);

        (, , , , , , , , bool revoked) = distributor.getRecurringPayment(paymentId);

        assertTrue(revoked, "Recurring payment should be marked as revoked");
    }

    function test_revokeRecurringPayments_stops_distributions() public {
        uint256 paymentId = create_basic_recurring_payment();

        uint256[] memory paymentIds = new uint256[](1);
        paymentIds[0] = paymentId;

        distributor.revokeRecurringPayments(paymentIds);

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert("Recurring payment has been revoked");
        distributor.distribute(paymentId, 10);
    }

    function test_revokeRecurringPayments_updates_multiple_correctly() public {
        uint256 firstPaymentId = create_basic_recurring_payment();
        uint256 secondPaymentId = create_basic_recurring_payment();

        uint256[] memory paymentIds = new uint256[](2);
        paymentIds[0] = firstPaymentId;
        paymentIds[1] = secondPaymentId;

        distributor.revokeRecurringPayments(paymentIds);

        (, , , , , , , , bool revokedFirst) = distributor.getRecurringPayment(firstPaymentId);
        (, , , , , , , , bool revokedSecond) = distributor.getRecurringPayment(secondPaymentId);

        assertTrue(revokedFirst, "First recurring payment should be revoked");
        assertTrue(revokedSecond, "Second recurring payment should be revoked");
    }
}
