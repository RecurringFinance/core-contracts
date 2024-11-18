// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./DateTimeLibrary.sol";

library CronLibrary {

    /**
     * @dev Cron schedule struct
     */
    struct CronSchedule {
        uint8[] hrs; // hours (0-23)
        uint8[] daysOfMonth; // days of the month (1-31)
        uint8[] months; // months (1-12)
        uint8[] daysOfWeek; // days of the week (0-6, where 0 is Sunday)
    }

    /**
     * @dev Validates the cron schedule
     * @param schedule The CronSchedule struct containing the cron configuration.
     */
    function validateCronSchedule(CronSchedule memory schedule) internal pure {
        // Check array lengths aren't excessive
        require(schedule.hrs.length <= 24, "Too many hour values");
        require(schedule.daysOfMonth.length <= 31, "Too many days of month");
        require(schedule.months.length <= 12, "Too many months");
        require(schedule.daysOfWeek.length <= 7, "Too many days of week");

        // Validate hours (0-23)
        for (uint i = 0; i < schedule.hrs.length; i++) {
            require(schedule.hrs[i] <= 23, "Invalid hour value");
            // Check for duplicates
            for (uint j = i + 1; j < schedule.hrs.length; j++) {
                require(schedule.hrs[i] != schedule.hrs[j], "Duplicate hour value");
            }
        }

        // Validate daysOfMonth (1-31)
        for (uint i = 0; i < schedule.daysOfMonth.length; i++) {
            require(schedule.daysOfMonth[i] >= 1 && schedule.daysOfMonth[i] <= 31, "Invalid day of month value");
            for (uint j = i + 1; j < schedule.daysOfMonth.length; j++) {
                require(schedule.daysOfMonth[i] != schedule.daysOfMonth[j], "Duplicate day of month value");
            }
        }

        // Validate months (1-12)
        for (uint i = 0; i < schedule.months.length; i++) {
            require(schedule.months[i] >= 1 && schedule.months[i] <= 12, "Invalid month value");
            for (uint j = i + 1; j < schedule.months.length; j++) {
                require(schedule.months[i] != schedule.months[j], "Duplicate month value");
            }
        }

        // Validate daysOfWeek (0-6)
        for (uint i = 0; i < schedule.daysOfWeek.length; i++) {
            require(schedule.daysOfWeek[i] <= 6, "Invalid day of week value");
            for (uint j = i + 1; j < schedule.daysOfWeek.length; j++) {
                require(schedule.daysOfWeek[i] != schedule.daysOfWeek[j], "Duplicate day of week value");
            }
        }
    }

    function getMinCronInterval(CronSchedule memory cronSchedule) internal pure returns (uint256) {
        // Determine the smallest interval specified in the cron schedule
        if (cronSchedule.hrs.length > 0) {
            return 1 hours;
        } else if (cronSchedule.daysOfMonth.length > 0 || cronSchedule.daysOfWeek.length > 0) {
            return 1 days;
        } else if (cronSchedule.months.length > 0) {
            return 0; // for months, we need to compute the exact number of days
        } else {
            return 1 minutes; // All fields are empty (wildcards)
        }
    }

    function matchesCron(uint256 timestamp, CronSchedule memory cronSchedule) internal pure returns (bool) {
        if (!matchesField(cronSchedule.hrs, DateTime.getHour(timestamp))) return false;
        if (!matchesField(cronSchedule.daysOfMonth, DateTime.getDay(timestamp))) return false;
        if (!matchesField(cronSchedule.months, DateTime.getMonth(timestamp))) return false;
        if (!matchesField(cronSchedule.daysOfWeek, DateTime.getDayOfWeek(timestamp))) return false;

        return true;
    }

    function matchesField(uint8[] memory field, uint256 value) internal pure returns (bool) {
        if (field.length == 0) return true; // Wildcard
        for (uint i = 0; i < field.length; i++) {
            if (field[i] == value) {
                return true;
            }
        }
        return false;
    }
}