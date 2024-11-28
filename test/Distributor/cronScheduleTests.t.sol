// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../src/Distributor.sol";
import {MockERC20} from "./Distributor.t.sol";
import {CronLibrary} from "../../src/libraries/CronLibrary.sol";
import {console2} from "forge-std/console2.sol";

contract CronScheduleTests is Test {
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

    function createBasicPayment(CronLibrary.CronSchedule memory cronSchedule) internal {
        address[] memory beneficiaries = new address[](2);
        beneficiaries[0] = address(0x1);
        beneficiaries[1] = address(0x2);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10 ether;
        amounts[1] = 15 ether;

        uint256[] memory startTimes = new uint256[](1);
        startTimes[0] = block.timestamp;
        uint256[] memory endTimes = new uint256[](1);
        endTimes[0] = 0;

        CronLibrary.CronSchedule[] memory intervals = new CronLibrary.CronSchedule[](1);
        intervals[0] = cronSchedule;

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
    }

    function test_every_hour() public {
        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        createBasicPayment(schedule);
        (, , CronLibrary.CronSchedule memory savedSchedule, , , , , , ) = distributor.getRecurringPayment(0);

        assertEq(savedSchedule.hrs.length, 0);
        assertEq(savedSchedule.daysOfMonth.length, 0);
        assertEq(savedSchedule.months.length, 0);
        assertEq(savedSchedule.daysOfWeek.length, 0);
    }

    function test_specific_hours() public {
        uint8[] memory hrs = new uint8[](3);
        hrs[0] = 9; // 9 AM
        hrs[1] = 13; // 1 PM
        hrs[2] = 17; // 5 PM

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: hrs,
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        createBasicPayment(schedule);
        (, , CronLibrary.CronSchedule memory savedSchedule, , , , , , ) = distributor.getRecurringPayment(0);

        assertEq(savedSchedule.hrs.length, 3);
        assertEq(savedSchedule.hrs[0], 9);
        assertEq(savedSchedule.hrs[1], 13);
        assertEq(savedSchedule.hrs[2], 17);
    }

    function test_monthly_schedule() public {
        uint8[] memory daysOfMonth = new uint8[](2);
        daysOfMonth[0] = 1; // 1st of month
        daysOfMonth[1] = 15; // 15th of month

        uint8[] memory hrs = new uint8[](1);
        hrs[0] = 12; // noon

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: hrs,
            daysOfMonth: daysOfMonth,
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        createBasicPayment(schedule);
        (, , CronLibrary.CronSchedule memory savedSchedule, , , , , , ) = distributor.getRecurringPayment(0);

        assertEq(savedSchedule.daysOfMonth.length, 2);
        assertEq(savedSchedule.daysOfMonth[0], 1);
        assertEq(savedSchedule.daysOfMonth[1], 15);
        assertEq(savedSchedule.hrs[0], 12);
    }

    function test_specific_months() public {
        uint8[] memory months = new uint8[](3);
        months[0] = 3; // March
        months[1] = 6; // June
        months[2] = 9; // September

        uint8[] memory daysOfMonth = new uint8[](1);
        daysOfMonth[0] = 1; // 1st of month

        uint8[] memory hrs = new uint8[](1);
        hrs[0] = 0; // midnight

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: hrs,
            daysOfMonth: daysOfMonth,
            months: months,
            daysOfWeek: new uint8[](0)
        });

        createBasicPayment(schedule);
        (, , CronLibrary.CronSchedule memory savedSchedule, , , , , , ) = distributor.getRecurringPayment(0);

        assertEq(savedSchedule.months.length, 3);
        assertEq(savedSchedule.months[0], 3);
        assertEq(savedSchedule.months[1], 6);
        assertEq(savedSchedule.months[2], 9);
    }

    function test_invalid_hour() public {
        uint8[] memory hrs = new uint8[](1);
        hrs[0] = 24; // Invalid hour (should be 0-23)

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: hrs,
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        vm.expectRevert("Invalid hour value");
        createBasicPayment(schedule);
    }

    function test_invalid_day_of_month() public {
        uint8[] memory daysOfMonth = new uint8[](1);
        daysOfMonth[0] = 32; // Invalid day (should be 1-31)

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: daysOfMonth,
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        vm.expectRevert("Invalid day of month value");
        createBasicPayment(schedule);
    }

    function test_invalid_month() public {
        uint8[] memory months = new uint8[](1);
        months[0] = 13; // Invalid month (should be 1-12)

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: months,
            daysOfWeek: new uint8[](0)
        });

        vm.expectRevert("Invalid month value");
        createBasicPayment(schedule);
    }

    function test_invalid_day_of_week() public {
        uint8[] memory daysOfWeek = new uint8[](1);
        daysOfWeek[0] = 7; // Invalid day (should be 0-6, where 0 is Sunday)

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: daysOfWeek
        });

        vm.expectRevert("Invalid day of week value");
        createBasicPayment(schedule);
    }

    function test_weekly_schedule() public {
        uint8[] memory daysOfWeek = new uint8[](2);
        daysOfWeek[0] = 1; // Monday
        daysOfWeek[1] = 4; // Thursday

        uint8[] memory hrs = new uint8[](1);
        hrs[0] = 15; // 3 PM

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: hrs,
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: daysOfWeek
        });

        createBasicPayment(schedule);
        (, , CronLibrary.CronSchedule memory savedSchedule, , , , , , ) = distributor.getRecurringPayment(0);

        assertEq(savedSchedule.daysOfWeek.length, 2);
        assertEq(savedSchedule.daysOfWeek[0], 1);
        assertEq(savedSchedule.daysOfWeek[1], 4);
        assertEq(savedSchedule.hrs[0], 15);
    }

    function test_hourly_periods() public {
        // * * * *
        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: new uint8[](0),
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        createBasicPayment(schedule);

        // Warp 5 hours ahead
        vm.warp(block.timestamp + 5 hours);

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        // 0 (1 hour) 3600 (2 hours) 7200 (3 hours) 10800 (4 hours) 14400 (5 hours) 18000 (6 hours)
        assertEq(periods, 6, "Should have 6 hourly periods");
    }

    function test_weekly_periods() public {
        // 0 * * 1
        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        uint8[] memory monday = new uint8[](1);
        monday[0] = 1; // Monday

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: monday
        });

        // Start on a Monday
        vm.warp(1704067200); // Monday, January 1, 2024
        createBasicPayment(schedule);

        // Warp 3 weeks ahead
        vm.warp(block.timestamp + 21 days); // Monday, January 22, 2024

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        assertEq(periods, 4, "Should have 4 weekly periods"); // jan 1, jan 8, jan 15, jan 22
    }

    function test_monthly_periods() public {
        // 0 * 1 *
        uint8[] memory firstOfMonth = new uint8[](1);
        firstOfMonth[0] = 1; // 1st of each month
        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: firstOfMonth,
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        // Start on January 1st, 2024
        vm.warp(1704067200); // January 1, 2024
        createBasicPayment(schedule);

        // Warp 4 months ahead
        vm.warp(1711929600); // April 1, 2024

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        assertEq(periods, 4, "Should have 4 monthly periods");
    }

    function test_day_leap_time_step_with_non_zero_hour_timestamp() public {
        uint8[] memory firstOfMonth = new uint8[](1);
        firstOfMonth[0] = 1; // 1st of each month
        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: firstOfMonth,
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        // Start on January 1st, 2024 in the afternoon
        vm.warp(1704114063); // January 1, 2024 at 13:01:03 UTC
        createBasicPayment(schedule);

        // Warp 4 months ahead
        vm.warp(1711933205); // April 1, 2024 at 01:00:05 UTC

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        // jan 1st 2024 won't be included as we start at 13:00 UTC instead of 00:00 UTC
        assertEq(periods, 3, "Should have 3 monthly periods");
    }

    function test_start_time_with() public {
        uint8[] memory firstOfMonth = new uint8[](1);
        firstOfMonth[0] = 1; // 1st of each month
        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: firstOfMonth,
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        // Start on January 1st, 2024 in the afternoon
        vm.warp(1704114063); // January 1, 2024 at 13:01:03 UTC
        createBasicPayment(schedule);

        // Warp 4 months ahead
        vm.warp(1711933205); // April 1, 2024 at 01:00:05 UTC

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        // jan 1st 2024 won't be included as we start at 13:00 UTC instead of 00:00 UTC
        assertEq(periods, 3, "Should have 3 monthly periods");
    }

    function test_leap_year_february() public {
        // 0 29 2 *
        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        uint8[] memory day29th = new uint8[](1);
        day29th[0] = 29; //  29th of month

        uint8[] memory february = new uint8[](1);
        february[0] = 2; // February

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: day29th,
            months: february,
            daysOfWeek: new uint8[](0)
        });

        // Start on February 1st, 2024 (leap year)
        vm.warp(1706745600); // February 1, 2024
        createBasicPayment(schedule);

        // Warp to March 1, 2027
        vm.warp(1803859200); // March 1, 2027

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        assertEq(periods, 1, "Should have 1 period for Feb 29th in leap year 2024");
    }

    function test_non_leap_year_february() public {
        // 0 29 2 *
        uint8[] memory feb29th = new uint8[](1);
        feb29th[0] = 29; // February 29th
        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: feb29th,
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        // Start on February 1st, 2023 (non-leap year)
        vm.warp(1675209600); // February 1, 2023
        createBasicPayment(schedule);

        // Warp to March 1st
        vm.warp(1677628800); // March 1, 2023

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        assertEq(periods, 0, "Should have 0 periods for Feb 29th in non-leap year");
    }

    function test_specific_weekday_of_month() public {
        // 0 5 * 1
        // Schedule for 5th of the month only if it's a Monday
        uint8[] memory fifthOfMonth = new uint8[](1);
        fifthOfMonth[0] = 5; // 5th of the month

        uint8[] memory monday = new uint8[](1);
        monday[0] = 1; // Monday

        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: fifthOfMonth,
            months: new uint8[](0),
            daysOfWeek: monday
        });

        // Start on January 1st, 2024
        vm.warp(1704067200); // January 1, 2024
        createBasicPayment(schedule);

        // Warp to end of 2024
        vm.warp(1735689600); // December 31, 2024

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        // In 2024, the 5th falls on a Monday in February and August
        assertEq(periods, 2, "Should have 2 periods for 5th Monday in 2024");
    }

    function test_yearly_periods() public {
        // 0 1 1 *
        uint8[] memory january = new uint8[](1);
        january[0] = 1; // January

        uint8[] memory firstOfMonth = new uint8[](1);
        firstOfMonth[0] = 1; // 1st of January

        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: firstOfMonth,
            months: january,
            daysOfWeek: new uint8[](0)
        });

        // Start on January 1st, 2024
        vm.warp(1704067200);
        createBasicPayment(schedule);

        // Warp 3 years ahead
        vm.warp(block.timestamp + (365 * 3 + 1) * 1 days); // Adding 1 day for leap year to go to jan 1 2027

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        assertEq(periods, 4, "Should have 4 yearly periods"); // jan 1 2024, jan 1 2025, jan 1 2026, jan 1 2027
    }

    function test_multiple_hours() public {
        // 2,4,6 * * *
        uint8[] memory hrs = new uint8[](3);
        hrs[0] = 2;
        hrs[1] = 4;
        hrs[2] = 6;

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: hrs,
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        createBasicPayment(schedule);

        vm.warp(block.timestamp + 24 hours);
        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        assertEq(periods, 3, "Should have 3 periods for 2 AM, 4 AM, 6 AM");
    }

    function test_multiple_months() public {
        // 0 0 2,6 *
        uint8[] memory months = new uint8[](2);
        months[0] = 2;
        months[1] = 6;

        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        uint8[] memory firstOfMonth = new uint8[](1);
        firstOfMonth[0] = 1; // 1st of month

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: firstOfMonth,
            months: months,
            daysOfWeek: new uint8[](0)
        });

        vm.warp(1704067200); // January 1, 2024
        createBasicPayment(schedule);
        vm.warp(1735603200); // December 31, 2024

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        assertEq(periods, 2, "Should have 2 periods for February and June");
    }

    function test_multiple_days_of_month() public {
        // 0 1,15 * *
        uint8[] memory daysOfMonth = new uint8[](2);
        daysOfMonth[0] = 1;
        daysOfMonth[1] = 15;

        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: daysOfMonth,
            months: new uint8[](0),
            daysOfWeek: new uint8[](0)
        });

        vm.warp(1704067200); // January 1, 2024
        createBasicPayment(schedule);
        vm.warp(1706659200); // January 31, 2024

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        assertEq(periods, 2, "Should have 2 periods for 1st and 15th of the month");
    }

    function test_multiple_days_of_week() public {
        // 0 0 * * 1,4
        // only on Monday and Thursday
        uint8[] memory daysOfWeek = new uint8[](2);
        daysOfWeek[0] = 1;
        daysOfWeek[1] = 4;

        uint8[] memory onlyAtMidnight = new uint8[](1);
        onlyAtMidnight[0] = 0; // midnight

        CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
            hrs: onlyAtMidnight,
            daysOfMonth: new uint8[](0),
            months: new uint8[](0),
            daysOfWeek: daysOfWeek
        });

        vm.warp(1704067200); // January 1, 2024
        createBasicPayment(schedule);
        vm.warp(1704585600); // January 7, 2024

        (uint256 periods, ) = distributor.periodsToDistribute(0, 100);
        assertEq(periods, 2, "Should have 2 periods for Monday and Thursday");
    }

    // function test_random_cron_schedules() public {
    //     // Create and test 100 random schedules
    //     for (uint256 i = 0; i < 100; i++) {
    //         // Generate random schedule components
    //         uint8[] memory hrs = _generateRandomArray(24, uint8(bound(uint256(keccak256(abi.encode(i, "hrs"))), 0, 5)));
    //         uint8[] memory daysOfMonth = _generateRandomArray(
    //             31,
    //             uint8(bound(uint256(keccak256(abi.encode(i, "days"))), 0, 3))
    //         );
    //         uint8[] memory months = _generateRandomArray(
    //             12,
    //             uint8(bound(uint256(keccak256(abi.encode(i, "months"))), 0, 2))
    //         );
    //         uint8[] memory daysOfWeek = _generateRandomArray(
    //             7,
    //             uint8(bound(uint256(keccak256(abi.encode(i, "weekdays"))), 0, 2))
    //         );

    //         CronLibrary.CronSchedule memory schedule = CronLibrary.CronSchedule({
    //             hrs: hrs,
    //             daysOfMonth: daysOfMonth,
    //             months: months,
    //             daysOfWeek: daysOfWeek
    //         });
    //         for (uint8 j = 0; j < schedule.hrs.length; j++) {
    //             console2.log("hrs", schedule.hrs[j]);
    //         }
    //         for (uint8 j = 0; j < schedule.daysOfMonth.length; j++) {
    //             console2.log("daysOfMonth", schedule.daysOfMonth[j]);
    //         }
    //         for (uint8 j = 0; j < schedule.months.length; j++) {
    //             console2.log("months", schedule.months[j]);
    //         }
    //         for (uint8 j = 0; j < schedule.daysOfWeek.length; j++) {
    //             console2.log("daysOfWeek", schedule.daysOfWeek[j]);
    //         }

    //         // Create payment with random schedule
    //         createBasicPayment(schedule);

    //         // Generate random future timestamp (between 1 day and 365 days ahead)
    //         uint256 futureTimestamp = 1704067200 +
    //             bound(uint256(keccak256(abi.encode(i, "timestamp"))), 1 days, 365 days); // January 1, 2024

    //         // Warp to future time
    //         vm.warp(futureTimestamp);

    //         console2.log("futureTimestamp", futureTimestamp);
    //         console2.log("i", i);

    //         // Get periods to distribute
    //         (uint256 periods, uint256 lastDistributionTime) = distributor.periodsToDistribute(i, 100);
    //         console2.log("periods", periods);

    //         // If we have periods, verify that the last timestamp matches a valid schedule
    //         if (periods > 0) {
    //             console2.log("lastDistributionTime", lastDistributionTime);

    //             require(
    //                 CronLibrary.matchesCron(lastDistributionTime, schedule),
    //                 "Last distribution time doesn't match schedule"
    //             );
    //             emit log_named_uint("Schedule", i);
    //             emit log_named_uint("Periods", periods);
    //             emit log_named_uint("Last Distribution Time", lastDistributionTime);
    //         }
    //     }
    // }

    // // Helper function to generate random arrays for the schedule
    // function _generateRandomArray(uint8 maxValue, uint8 maxLength) internal view returns (uint8[] memory) {
    //     if (maxLength == 0) return new uint8[](0);

    //     uint8[] memory values = new uint8[](maxLength);
    //     uint8 actualLength = 0;

    //     for (uint8 i = 0; i < maxLength; i++) {
    //         uint8 value = uint8(bound(uint256(keccak256(abi.encode(block.timestamp, i, maxValue))), 0, maxValue - 1));

    //         // Check for duplicates
    //         bool isDuplicate = false;
    //         for (uint8 j = 0; j < actualLength; j++) {
    //             if (values[j] == value) {
    //                 isDuplicate = true;
    //                 break;
    //             }
    //         }

    //         if (!isDuplicate) {
    //             values[actualLength] = value;
    //             actualLength++;
    //         }
    //     }

    //     // Create final array with actual length
    //     uint8[] memory result = new uint8[](actualLength);
    //     for (uint8 i = 0; i < actualLength; i++) {
    //         result[i] = values[i];
    //     }

    //     return result;
    // }
}
