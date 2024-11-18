// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {CronLibrary} from "../libraries/CronLibrary.sol";

interface IDistributor {

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

    event PaymentPaused(uint256 indexed paymentId);

    event PaymentUnpaused(uint256 indexed paymentId);

    event DistributionFeeSet(
        address oldDistributionFeeToken,
        uint256 oldDistributionFeeAmount,
        address newDistributionFeeToken,
        uint256 newDistributionFeeAmount
    );
}
