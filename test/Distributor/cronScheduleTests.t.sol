// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../src/Distributor.sol";
import {MockERC20} from "./Distributor.t.sol";
import {CronLibrary} from "../../src/libraries/CronLibrary.sol";

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
        endTimes[0] = block.timestamp + 30 days;

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
}
