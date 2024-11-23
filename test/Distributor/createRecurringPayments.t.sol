// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../src/DistributorFactory.sol";
import "../../src/interfaces/IDistributor.sol";
import {MockERC20} from "./Distributor.t.sol";

contract DistributorTest is Test {
    address public owner;
    Distributor public distributor;
    MockERC20 public tokenToDistribute;
    MockERC20 public distributionFeeToken;

    function setUp() public {
        owner = address(this);

        // Deploy mock tokens
        tokenToDistribute = new MockERC20("Distribute Token", "DST", 1_000_000 ether);
        distributionFeeToken = new MockERC20("Distribution Fee Token", "DFT", 1_000_000 ether);

        // Deploy Distributor with the owner address
        distributor = new Distributor(owner);

        // Transfer tokens to Distributor contract
        tokenToDistribute.transfer(address(distributor), 500_000 ether);
        distributionFeeToken.transfer(address(distributor), 500_000 ether);
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
        uint256 distributionFeeAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = endTime;

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
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = distributionFeeAmount;

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

        (
            uint256 retrievedStartTime,
            uint256 retrievedEndTime,
            ,
            // CronSchedule memory cronSchedule,
            uint256 retrievedDistributedUpToTime,
            uint256 retrievedLastDistributionTime,
            address retrievedTokenToDistribute,
            address[] memory retrievedBeneficiaries,
            uint256[] memory retrievedBeneficiariesAmounts,
            bool revoked
        ) = distributor.getRecurringPayment(0);

        (address retrievedDistributionFeeToken, uint256 retrievedDistributionFeeAmount) = distributor
            .getDistributionFee(0);

        // Assertions
        assertEq(retrievedStartTime, startTimes[0]);
        assertEq(retrievedEndTime, endTime);
        // assertEq(retrievedPeriodInterval, periodInterval);
        assertEq(retrievedLastDistributionTime, 0);
        assertEq(retrievedDistributedUpToTime, 0);
        assertEq(retrievedTokenToDistribute, address(tokenToDistribute));
        assertEq(retrievedDistributionFeeToken, address(distributionFeeToken));
        assertEq(retrievedDistributionFeeAmount, distributionFeeAmount);
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
        uint256 distributionFeeAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = endTime;
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
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = distributionFeeAmount;

        vm.expectRevert("There must be a start date");
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
    }

    function test_createRecurringPayments_with_mismatched_array_length() public {
        (address[] memory beneficiaries, uint256[] memory beneficiariesAmounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](2);
        startTimes[0] = block.timestamp + 1 days;
        startTimes[1] = block.timestamp + 2 days;
        uint256 endTime = 0;
        uint256 distributionFeeAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = endTime;
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
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = distributionFeeAmount;

        vm.expectRevert("Array length mismatch");
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
    }

    function test_createRecurringPayments_with_token_to_distribute_is_zero() public {
        (address[] memory beneficiaries, uint256[] memory beneficiariesAmounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;
        uint256 endTime = 0;
        uint256 distributionFeeAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = endTime;
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
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = distributionFeeAmount;

        vm.expectRevert("Token to distribute cannot be 0");
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
    }

    function test_createRecurringPayments_with_end_time_before_start_time() public {
        (address[] memory beneficiaries, uint256[] memory beneficiariesAmounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;
        uint256 distributionFeeAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp;
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
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = distributionFeeAmount;

        vm.expectRevert("End time must be greater than start time or 0");
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
    }

    function test_createRecurringPayments_with_mismatch_beneficiaries_lengths_and_amounts() public {
        (
            address[] memory beneficiaries,
            uint256[] memory beneficiariesAmounts
        ) = setupMalformedBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;
        uint256 distributionFeeAmount = 1 ether;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 2 days;
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
        amountsArray[0] = beneficiariesAmounts;

        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);

        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = distributionFeeAmount;

        vm.expectRevert("Beneficiaries and amounts length mismatch");
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

        CronLibrary.CronSchedule[] memory intervals = new CronLibrary.CronSchedule[](2);
        intervals[0] = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });
        intervals[1] = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        address[][] memory beneficiariesArray = new address[][](2);
        beneficiariesArray[0] = beneficiaries1;
        beneficiariesArray[1] = beneficiaries2;

        uint256[][] memory amountsArray = new uint256[][](2);
        amountsArray[0] = amounts1;
        amountsArray[1] = amounts2;

        address[] memory tokens = new address[](2);
        tokens[0] = address(tokenToDistribute);
        tokens[1] = address(tokenToDistribute);

        address[] memory distributionFeeTokens = new address[](2);
        distributionFeeTokens[0] = address(distributionFeeToken);
        distributionFeeTokens[1] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](2);
        distributionFeeAmounts[0] = 1 ether;
        distributionFeeAmounts[1] = 2 ether;

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

        assertEq(distributor.recurringPaymentCounter(), 2);
    }

    function test_createRecurringPayments_with_same_start_and_end_time() public {
        (address[] memory beneficiaries, uint256[] memory amounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 1 days; // Same as start time

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
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = 1 ether;

        vm.expectRevert("End time must be greater than start time or 0");
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
    }

    function test_createRecurringPayments_with_empty_beneficiaries() public {
        address[] memory beneficiaries = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;

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
        distributionFeeTokens[0] = address(distributionFeeToken);

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

        // Payment should be created but with no beneficiaries

        /* prettier-ignore */
        (
            // startTime
            ,
            // endTime
            ,
            // cronSchedule
            ,
            // distributedUpToTime
            ,
            // lastDistributionTime
            ,
            // tokenToDistribute
            ,
            address[] memory retrievedBeneficiaries
            , 
            // beneficiaryToAmount
            ,
            // revoked
        ) = distributor.getRecurringPayment(0);
        /* prettier-ignore */

        assertEq(retrievedBeneficiaries.length, 0);
    }

    function test_createRecurringPayments_with_max_uint256_values() public {
        (address[] memory beneficiaries, uint256[] memory amounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = type(uint256).max;

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
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = type(uint256).max;

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

        // Verify the payment was created with max values
        /* prettier-ignore */
        (
            // startTime
            ,
            uint256 retrievedEndTime,
            ,
            // cronSchedule
            ,
            // distributedUpToTime
            ,
            // lastDistributionTime
            ,
            // tokenToDistribute
            ,
            // beneficiaryToAmount
            ,
            // revoked
        ) = distributor.getRecurringPayment(0);
        /* prettier-ignore */

        (address retrievedDistributionFeeToken, uint256 retrievedDistributionFeeAmount) = distributor.getDistributionFee(0);
        assertEq(retrievedEndTime, type(uint256).max);
        assertEq(retrievedDistributionFeeToken, address(distributionFeeToken));
        assertEq(retrievedDistributionFeeAmount, type(uint256).max);
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
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = 1 ether;

        vm.expectRevert("Duplicate beneficiaries");
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
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = 0; // Zero reward amount

        // Should succeed as zero reward amount is valid
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

        // Verify the payment was created with zero reward
        (address retrievedDistributionFeeToken, uint256 retrievedDistributionFeeAmount) = distributor
            .getDistributionFee(0);
        assertEq(retrievedDistributionFeeToken, address(distributionFeeToken));
        assertEq(retrievedDistributionFeeAmount, 0);
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
        distributionFeeTokens[0] = address(distributionFeeToken);

        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = 1 ether;

        // Should fail as zero amounts are not valid
        vm.expectRevert("Amount per period must be greater than 0");
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
    }

    function test_createRecurringPayments_with_zero_address_reward_token() public {
        (address[] memory beneficiaries, uint256[] memory amounts) = setupBeneficiariesAndAmounts();

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;

        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 30 days;

        CronLibrary.CronSchedule[] memory cronSchedules = new CronLibrary.CronSchedule[](1);
        cronSchedules[0] = CronLibrary.CronSchedule({
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

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(0); // Zero address for reward token

        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = 1 ether;

        // Should succeed as zero address reward token is valid (means no reward)
        distributor.createRecurringPayments(
            startTimes,
            endTimes,
            cronSchedules,
            beneficiariesArray,
            amountsArray,
            tokens,
            rewardTokens,
            rewardAmounts
        );

        // Verify the payment was created with zero address reward token
        (address retrievedRewardToken, uint256 retrievedRewardAmount) = distributor.getDistributionFee(0);
        assertEq(retrievedRewardToken, address(0));
        assertEq(retrievedRewardAmount, 1 ether);
    }

    function test_createRecurringPayments_with_invalid_cron_schedules() public {
        (address[] memory beneficiaries, uint256[] memory amounts) = setupBeneficiariesAndAmounts();

        // Setup common parameters
        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp + 1 days;
        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = block.timestamp + 30 days;

        address[][] memory beneficiariesArray = new address[][](1);
        beneficiariesArray[0] = beneficiaries;
        uint256[][] memory amountsArray = new uint256[][](1);
        amountsArray[0] = amounts;
        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenToDistribute);
        address[] memory distributionFeeTokens = new address[](1);
        distributionFeeTokens[0] = address(distributionFeeToken);
        uint256[] memory distributionFeeAmounts = new uint256[](1);
        distributionFeeAmounts[0] = 1 ether;

        // Test 1: Too many hours
        CronLibrary.CronSchedule[] memory intervals = new CronLibrary.CronSchedule[](1);
        uint8[] memory tooManyHours = new uint8[](25); // 25 hours
        for (uint8 i = 0; i < 25; i++) tooManyHours[i] = i;
        intervals[0] = CronLibrary.CronSchedule({
            hrs: tooManyHours,
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });
        vm.expectRevert("Too many hour values");
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

        // Test 2: Invalid hour value
        uint8[] memory invalidHours = new uint8[](1);
        invalidHours[0] = 24; // Invalid hour (should be 0-23)
        intervals[0] = CronLibrary.CronSchedule({
            hrs: invalidHours,
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });
        vm.expectRevert("Invalid hour value");
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

        // Test 3: Duplicate hours
        uint8[] memory duplicateHours = new uint8[](2);
        duplicateHours[0] = 5;
        duplicateHours[1] = 5;
        intervals[0] = CronLibrary.CronSchedule({
            hrs: duplicateHours,
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });
        vm.expectRevert("Duplicate hour value");
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

        // Test 4: Invalid day of month
        uint8[] memory invalidDays = new uint8[](1);
        invalidDays[0] = 32; // Invalid day (should be 1-31)
        intervals[0] = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: invalidDays,
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });
        vm.expectRevert("Invalid day of month value");
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

        // Test 5: Invalid month
        uint8[] memory invalidMonths = new uint8[](1);
        invalidMonths[0] = 13; // Invalid month (should be 1-12)
        intervals[0] = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: invalidMonths,
            daysOfWeek: new uint8[](0)
        });
        vm.expectRevert("Invalid month value");
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

        // Test 6: Invalid day of week
        uint8[] memory invalidDaysOfWeek = new uint8[](1);
        invalidDaysOfWeek[0] = 7; // Invalid day (should be 0-6)
        intervals[0] = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: invalidDaysOfWeek
        });
        vm.expectRevert("Invalid day of week value");
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

        // Test 7: Valid cron schedule
        uint8[] memory validHours = new uint8[](2);
        validHours[0] = 9;
        validHours[1] = 17;
        uint8[] memory validDaysOfWeek = new uint8[](5);
        for (uint8 i = 0; i < 5; i++) validDaysOfWeek[i] = i; // Monday-Friday
        intervals[0] = CronLibrary.CronSchedule({
            hrs: validHours,
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: validDaysOfWeek
        });
        // This should not revert
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
    }
}
