// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDistributor {
    event NewRecurringPayment(
        uint256 recurringPaymentId,
        uint256 startTime,
        uint256 endTime,
        uint256 periodInterval,
        address tokenToDistribute,
        address distributionFeeToken,
        uint256 distributionFeeAmount
    );

    event Distribution(
        uint256 recurringPaymentId,
        uint256 period,
        uint256 timestamp
    );

    event DistributionRevoked(uint256 recurringPaymentId);

    event RecurringPaymentPaused(uint256 indexed recurringPaymentId);
    
    event RecurringPaymentUnpaused(uint256 indexed recurringPaymentId);

    event DistributionFeeSet(
        address oldDistributionFeeToken,
        uint256 oldDistributionFeeAmount,
        address newDistributionFeeToken,
        uint256 newDistributionFeeAmount
    );
}
