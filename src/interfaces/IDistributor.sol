// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {CronLibrary} from "../libraries/CronLibrary.sol";

interface IDistributor {
    // Events
    event NewRecurringPayment(
        uint256 recurringPaymentId,
        uint256 startTime,
        uint256 endTime,
        CronLibrary.CronSchedule cronSchedule,
        address tokenToDistribute,
        address distributionFeeToken,
        uint256 distributionFeeAmount
    );

    event Distribution(uint256 recurringPaymentId, uint256 period, uint256 timestamp);

    event DistributionRevoked(uint256 recurringPaymentId);

    event EndTimeSet(uint256 recurringPaymentId, uint256 newEndTime);

    // Functions
    function createRecurringPayments(
        uint256[] memory _startTimes,
        uint256[] memory _endTimes,
        CronLibrary.CronSchedule[] memory _cronSchedules,
        address[][] memory _beneficiaries,
        uint256[][] memory _beneficiariesAmounts,
        address[] memory _tokensToDistribute,
        address[] memory _distributionFeeTokens,
        uint256[] memory _distributionFeeAmounts
    ) external;

    function distribute(uint256 _recurringPaymentId, uint256 _maxPeriods) external;

    function revokeRecurringPayments(uint256[] memory _recurringPaymentIds) external;

    function canDistribute(uint256 _recurringPaymentId) external view returns (bool);

    function periodsToDistribute(
        uint256 _recurringPaymentId,
        uint256 _maxPeriodsToDistribute
    ) external view returns (uint256, uint256);

    function withdrawFunds(address _token, uint256 _amount, address _beneficiary) external;

    function getRecurringPayment(
        uint256 _recurringPaymentId
    )
        external
        view
        returns (
            uint256,
            uint256,
            CronLibrary.CronSchedule memory,
            uint256,
            uint256,
            address,
            address[] memory,
            uint256[] memory,
            bool
        );

    function getDistributionFee(uint256 _recurringPaymentId) external view returns (address, uint256);

    function setEndTime(uint256 _recurringPaymentId, uint256 _newEndTime) external;

    function recurringPaymentCounter() external view returns (uint256);
}
