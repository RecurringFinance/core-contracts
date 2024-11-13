pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../src/DistributorFactory.sol";
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
        uint256[] memory intervals = new uint256[](1);
        intervals[0] = 1 days;

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
        distributor.distribute(recurringPaymentId);
    }

    function test_distributeRecurringPayments_should_distribute_successfully_after_start_time() public {
        uint256 recurringPaymentId = create_basic_recurring_payment();

        // Move forward 2 days
        vm.warp(block.timestamp + 2 days);

        distributor.distribute(recurringPaymentId);

        (, , , uint256 lastDistributionTime, , , , , , , , ) = distributor.getRecurringPayment(recurringPaymentId);

        assertEq(lastDistributionTime, block.timestamp);
    }

    function test_distributeRecurringPayments_should_fail_if_no_period_passed_since_last_distribution() public {
        uint256 recurringPaymentId = create_basic_recurring_payment();

        // Move forward 2 days
        vm.warp(block.timestamp + 2 days);

        // distribute the first period
        distributor.distribute(recurringPaymentId);

        // Move forward 1 hour
        vm.warp(block.timestamp + 1 hours);

        vm.expectRevert("No periods have passed since last distribution");
        distributor.distribute(recurringPaymentId);
    }

    function test_distributeRecurringPayments_should_work_even_if_end_time_is_in_the_past() public {
        uint256 recurringPaymentId = create_basic_recurring_payment();

        // Move forward 31 days
        vm.warp(block.timestamp + 31 days);

        distributor.distribute(recurringPaymentId);

        (, , , uint256 lastDistributionTime, , , , , , , , ) = distributor.getRecurringPayment(recurringPaymentId);

        assertEq(lastDistributionTime, block.timestamp);
    }

    function test_distributeRecurringPayments_should_fail_if_distribution_is_after_end_time() public {
        uint256 recurringPaymentId = create_basic_recurring_payment();

        // Move forward 30 days
        vm.warp(block.timestamp + 30 days);

        // distribute all the periods
        distributor.distribute(recurringPaymentId);

        // Move forward 1 day
        vm.warp(block.timestamp + 1 days);

        // no more periods to distribute and payment has ended
        vm.expectRevert("Recurring payment has ended");
        distributor.distribute(recurringPaymentId);
    }
}
