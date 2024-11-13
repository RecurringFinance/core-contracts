pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../src/DistributorFactory.sol";
// import "../src/Distributor.sol";
import {MockERC20} from "./Distributor.t.sol";

contract DistributorTest is Test {
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

    // Helper function to set up beneficiaries and amounts
    function setupBeneficiariesAndAmounts()
        internal
        pure
        returns (address[] memory beneficiaries, uint256[] memory beneficiariesAmounts)
    {
        beneficiaries = new address[](2);
        beneficiaries[0] = address(0x1);
        beneficiaries[1] = address(0x2);

        beneficiariesAmounts = new uint256[](2);
        beneficiariesAmounts[0] = 10 ether;
        beneficiariesAmounts[1] = 15 ether;
    }

    // Helper function to set up malformed beneficiaries and amounts
    function setupMalformedBeneficiariesAndAmounts()
        internal
        pure
        returns (address[] memory beneficiaries, uint256[] memory beneficiariesAmounts)
    {
        beneficiaries = new address[](1);
        beneficiaries[0] = address(0x1);
        // beneficiaries[1] = address(0x2);

        beneficiariesAmounts = new uint256[](2);
        beneficiariesAmounts[0] = 10 ether;
        beneficiariesAmounts[1] = 15 ether;
    }

    function test_createRecurringPayment_with_correct_parameters() public {
        (address[] memory beneficiaries, uint256[] memory beneficiariesAmounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;
        uint256 endTime = 0;
        uint256 periodInterval = 1 days;
        uint256 rewardAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = endTime;
        uint256[] memory intervals = new uint256[](1);
        intervals[0] = periodInterval;
        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;
        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = rewardAmount;

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
        (
            uint256 retrievedStartTime,
            uint256 retrievedEndTime,
            uint256 retrievedPeriodInterval,
            uint256 retrievedLastDistributionTime,
            address retrievedTokenToDistribute,
            address[] memory retrievedBeneficiaries,
            uint256[] memory retrievedBeneficiariesAmounts,
            address retrievedRewardToken,
            uint256 retrievedRewardAmount, // Skip pausedAt
            ,
            ,
            // Skip totalPausedTime
            bool revoked
        ) = distributor.getRecurringPayment(0);

        // Assertions
        assertEq(retrievedStartTime, startTimes[0]);
        assertEq(retrievedEndTime, endTime);
        assertEq(retrievedPeriodInterval, periodInterval);
        assertEq(retrievedLastDistributionTime, 0);
        assertEq(retrievedTokenToDistribute, address(tokenToDistribute));
        assertEq(retrievedRewardToken, address(rewardToken));
        assertEq(retrievedRewardAmount, rewardAmount);
        assertEq(revoked, false);

        assertEq(retrievedBeneficiaries.length, beneficiaries.length);
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            assertEq(retrievedBeneficiaries[i], beneficiaries[i]);
        }
        assertEq(retrievedBeneficiariesAmounts.length, beneficiaries.length);
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            assertEq(retrievedBeneficiariesAmounts[i], beneficiariesAmounts[i]);
        }
    }

    function test_createRecurringPayments_with_no_start_date() public {
        (address[] memory beneficiaries, uint256[] memory beneficiariesAmounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes;
        uint256 endTime = 0;
        uint256 periodInterval = 1 days;
        uint256 rewardAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = endTime;
        uint256[] memory intervals = new uint256[](1);
        intervals[0] = periodInterval;
        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;
        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = rewardAmount;

        vm.expectRevert("There must be a start date");
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
    }

    function test_createRecurringPayments_with_mismatched_array_length() public {
        (address[] memory beneficiaries, uint256[] memory beneficiariesAmounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](2);
        startTimes[0] = block.timestamp + 1 days;
        startTimes[1] = block.timestamp + 2 days;
        uint256 endTime = 0;
        uint256 periodInterval = 1 days;
        uint256 rewardAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = endTime;
        uint256[] memory intervals = new uint256[](1);
        intervals[0] = periodInterval;
        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;
        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = rewardAmount;

        vm.expectRevert("Array length mismatch");
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
    }

    function test_createRecurringPayments_with_token_to_distribute_is_zero() public {
        (address[] memory beneficiaries, uint256[] memory beneficiariesAmounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;
        uint256 endTime = 0;
        uint256 periodInterval = 1 days;
        uint256 rewardAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = endTime;
        uint256[] memory intervals = new uint256[](1);
        intervals[0] = periodInterval;
        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;
        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = rewardAmount;

        vm.expectRevert("Token to distribute cannot be 0");
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
    }

    function test_createRecurringPayments_with_end_time_before_start_time() public {
        (address[] memory beneficiaries, uint256[] memory beneficiariesAmounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;
        uint256 periodInterval = 1 days;
        uint256 rewardAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp;
        uint256[] memory intervals = new uint256[](1);
        intervals[0] = periodInterval;
        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;
        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = rewardAmount;

        vm.expectRevert("End time must be greater than start time or 0");
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
    }

    function test_createRecurringPayments_with_mismatch_beneficiaries_lengths_and_amounts() public {
        (
            address[] memory beneficiaries,
            uint256[] memory beneficiariesAmounts
        ) = setupMalformedBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;
        uint256 periodInterval = 1 days;
        uint256 rewardAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 2 days;
        uint256[] memory intervals = new uint256[](1);
        intervals[0] = periodInterval;
        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;
        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = rewardAmount;

        vm.expectRevert("Beneficiaries and amounts length mismatch");
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
    }

    function test_createRecurringPayments_with_multiple_valid_payments() public {
        (address[] memory beneficiaries1, uint256[] memory amounts1) = setupBeneficiariesAndAmounts();
        (address[] memory beneficiaries2, uint256[] memory amounts2) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](2);
        startTimes[0] = block.timestamp + 1 days;
        startTimes[1] = block.timestamp + 2 days;

        uint256[] memory endTimes = new uint256[](2);
        endTimes[0] = block.timestamp + 30 days;
        endTimes[1] = block.timestamp + 60 days;

        uint256[] memory intervals = new uint256[](2);
        intervals[0] = 1 days;
        intervals[1] = 7 days;

        address[][] memory beneficiariesArray = new address[][](2);
        beneficiariesArray[0] = beneficiaries1;
        beneficiariesArray[1] = beneficiaries2;

        uint256[][] memory amountsArray = new uint256[][](2);
        amountsArray[0] = amounts1;
        amountsArray[1] = amounts2;

        address[] memory tokens = new address[](2);
        tokens[0] = address(tokenToDistribute);
        tokens[1] = address(tokenToDistribute);

        address[] memory rewardTokens = new address[](2);
        rewardTokens[0] = address(rewardToken);
        rewardTokens[1] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](2);
        rewardAmounts[0] = 1 ether;
        rewardAmounts[1] = 2 ether;

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

        assertEq(distributor.recurringPaymentCounter(), 2);
    }

    function test_createRecurringPayments_with_zero_period_interval() public {
        (address[] memory beneficiaries, uint256[] memory amounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 30 days;

        uint256[] memory intervals = new uint256[](1);
        intervals[0] = 0; // Zero interval

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

        vm.expectRevert("Period interval must be greater than 0 seconds");
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
    }

    function test_createRecurringPayments_with_same_start_and_end_time() public {
        (address[] memory beneficiaries, uint256[] memory amounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 1 days; // Same as start time

        uint256[] memory intervals = new uint256[](1);
        intervals[0] = 1 days;

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

        vm.expectRevert("End time must be greater than start time or 0");
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
    }

    function test_createRecurringPayments_with_empty_beneficiaries() public {
        address[] memory beneficiaries = new address[](0);
        uint256[] memory amounts = new uint256[](0);

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

        // Payment should be created but with no beneficiaries
        (, , , , , address[] memory retrievedBeneficiaries, , , , , , ) = distributor.getRecurringPayment(0);
        assertEq(retrievedBeneficiaries.length, 0);
    }

    function test_createRecurringPayments_with_max_uint256_values() public {
        (address[] memory beneficiaries, uint256[] memory amounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = type(uint256).max;

        uint256[] memory intervals = new uint256[](1);
        intervals[0] = type(uint256).max;

        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;

        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = amounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = type(uint256).max;

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

        // Verify the payment was created with max values
        (
            ,
            uint256 retrievedEndTime,
            uint256 retrievedInterval,
            ,
            ,
            ,
            ,
            ,
            uint256 retrievedRewardAmount,
            ,
            ,

        ) = distributor.getRecurringPayment(0);

        assertEq(retrievedEndTime, type(uint256).max);
        assertEq(retrievedInterval, type(uint256).max);
        assertEq(retrievedRewardAmount, type(uint256).max);
    }

    function test_createRecurringPayments_with_duplicate_beneficiaries() public {
        address[] memory beneficiaries = new address[](3);
        beneficiaries[0] = address(0x1);
        beneficiaries[1] = address(0x1); // Duplicate address
        beneficiaries[2] = address(0x2);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        amounts[1] = 20 ether;
        amounts[2] = 15 ether;

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

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = 1 ether;

        vm.expectRevert("Duplicate beneficiaries");
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

        // // The last amount should override the previous one for the same address
        // (,,,,, address[] memory retrievedBeneficiaries, uint256[] memory retrievedAmounts,,,,,) = distributor.getRecurringPayment(0);

        // for (uint256 i = 0; i < retrievedBeneficiaries.length; i++) {
        //     if (retrievedBeneficiaries[i] == address(0x1)) {
        //         assertEq(retrievedAmounts[i], 20 ether);
        //     }
        // }
    }

    function test_createRecurringPayments_with_zero_reward_amount() public {
        (address[] memory beneficiaries, uint256[] memory amounts) = setupBeneficiariesAndAmounts();

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

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = 0; // Zero reward amount

        // Should succeed as zero reward amount is valid
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

        // Verify the payment was created with zero reward
        (, , , , , , , , uint256 retrievedRewardAmount, , , ) = distributor.getRecurringPayment(0);
        assertEq(retrievedRewardAmount, 0);
    }

    function test_createRecurringPayments_with_zero_beneficiary_amounts() public {
        address[] memory beneficiaries = new address[](2);
        beneficiaries[0] = address(0x1);
        beneficiaries[1] = address(0x2);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0; // Zero amount
        amounts[1] = 0; // Zero amount

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

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = 1 ether;

        // Should fail as zero amounts are not valid
        vm.expectRevert("Amount per period must be greater than 0");
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
    }

    function test_createRecurringPayments_with_zero_address_reward_token() public {
        (address[] memory beneficiaries, uint256[] memory amounts) = setupBeneficiariesAndAmounts();

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

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(0); // Zero address for reward token

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = 1 ether;

        // Should succeed as zero address reward token is valid (means no reward)
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

        // Verify the payment was created with zero address reward token
        (, , , , , , , address retrievedRewardToken, , , , ) = distributor.getRecurringPayment(0);
        assertEq(retrievedRewardToken, address(0));
    }
}
