// ▗▄▄▖ ▗▄▄▄▖ ▗▄▄▖▗▖ ▗▖▗▄▄▖ ▗▄▄▖ ▗▄▄▄▖▗▖  ▗▖ ▗▄▄▖
// ▐▌ ▐▌▐▌   ▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌  █  ▐▛▚▖▐▌▐▌
// ▐▛▀▚▖▐▛▀▀▘▐▌   ▐▌ ▐▌▐▛▀▚▖▐▛▀▚▖  █  ▐▌ ▝▜▌▐▌▝▜▌
// ▐▌ ▐▌▐▙▄▄▖▝▚▄▄▖▝▚▄▞▘▐▌ ▐▌▐▌ ▐▌▗▄█▄▖▐▌  ▐▌▝▚▄▞▘

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IDistributor.sol";

/**
 * @title Distributor
 * @notice Manages recurring token payments to multiple beneficiaries with optional rewards
 * @dev Implements reentrancy protection and ownership controls
 */
contract Distributor is ReentrancyGuard, AccessControl, IDistributor {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /* Variables */
    mapping(uint256 => RecurringPayment) private recurringPayments;
    uint256 public recurringPaymentCounter;

    /**
     * @notice Represents a recurring payment configuration
     * @dev Uses a mapping for beneficiary amounts to allow efficient updates
     */
    struct RecurringPayment {
        uint256 startTime;
        uint256 endTime;
        uint256 periodInterval;
        uint256 lastDistributionTime;
        address tokenToDistribute;
        EnumerableSet.AddressSet beneficiaries;
        mapping(address => uint256) beneficiaryToAmount;
        address distributionFeeToken;
        uint256 distributionFeeAmount;
        uint256 pausedAt;
        uint256 pausedDuration;
        bool revoked;
    }

    modifier onlyValidRecurringPaymentId(uint256 _recurringPaymentId) {
        require(_recurringPaymentId < recurringPaymentCounter, "Invalid recurring payment id");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0x0");
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    /**
     * @notice Creates multiple recurring payment configurations in a single transaction
     * @dev Only callable by contract owner
     * @param _startTimes Array of start timestamps for each payment
     * @param _endTimes Array of end timestamps (0 for no end)
     * @param _periodIntervals Array of time intervals between payments
     * @param _beneficiaries Array of beneficiary address arrays
     * @param _beneficiariesAmounts Array of payment amount arrays
     * @param _tokensToDistribute Array of token addresses to distribute
     * @param _distributionFeeTokens Array of distribution fee token addresses
     * @param _distributionFeeAmounts Array of distribution fee amounts
     */
    function createRecurringPayments(
        uint256[] memory _startTimes,
        uint256[] memory _endTimes,
        uint256[] memory _periodIntervals,
        address[][] memory _beneficiaries,
        uint256[][] memory _beneficiariesAmounts,
        address[] memory _tokensToDistribute,
        address[] memory _distributionFeeTokens,
        uint256[] memory _distributionFeeAmounts
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_startTimes.length > 0, "There must be a start date");
        require(
                _startTimes.length == _endTimes.length &&
                _startTimes.length == _periodIntervals.length &&
                _startTimes.length == _beneficiaries.length &&
                _startTimes.length == _beneficiariesAmounts.length &&
                _startTimes.length == _tokensToDistribute.length &&
                _startTimes.length == _distributionFeeTokens.length &&
                _startTimes.length == _distributionFeeAmounts.length,
            "Array length mismatch"
        );

        for (uint256 i = 0; i < _startTimes.length; i++) {
            require(_tokensToDistribute[i] != address(0), "Token to distribute cannot be 0");
            require(
                _endTimes[i] == 0 || _endTimes[i] > _startTimes[i],
                "End time must be greater than start time or 0"
            );
            require(
                _beneficiaries[i].length == _beneficiariesAmounts[i].length,
                "Beneficiaries and amounts length mismatch"
            );

            require(_periodIntervals[i] > 0, "Period interval must be greater than 0 seconds");

            _createRecurringPayment(
                _startTimes[i],
                _endTimes[i],
                _periodIntervals[i],
                _beneficiaries[i],
                _beneficiariesAmounts[i],
                _tokensToDistribute[i],
                _distributionFeeTokens[i],
                _distributionFeeAmounts[i]
            );
        }
    }

    /**
     * @notice Creates a recurring payment
     * @dev Includes reentrancy protection
     * @param _startTime The start time of the recurring payment
     * @param _endTime The end time of the recurring payment
     * @param _periodInterval The interval between payments
     * @param _beneficiaries The beneficiaries of the recurring payment
     * @param _beneficiariesAmounts The amounts to distribute to each beneficiary
     * @param _tokenToDistribute The token to distribute
     * @param _distributionFeeToken The distribution fee token
     * @param _distributionFeeAmount The distribution fee amount
     */
    function _createRecurringPayment(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periodInterval,
        address[] memory _beneficiaries,
        uint256[] memory _beneficiariesAmounts,
        address _tokenToDistribute,
        address _distributionFeeToken,
        uint256 _distributionFeeAmount
    ) internal {
        RecurringPayment storage recurringPayment = recurringPayments[recurringPaymentCounter];

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            require(_beneficiaries[i] != address(0), "Beneficiary address cannot be 0x0");
            require(EnumerableSet.add(recurringPayment.beneficiaries, _beneficiaries[i]), "Duplicate beneficiaries");
            require(_beneficiariesAmounts[i] > 0, "Amount per period must be greater than 0");
            recurringPayment.beneficiaryToAmount[_beneficiaries[i]] = _beneficiariesAmounts[i];
        }

        recurringPayment.startTime = _startTime;
        recurringPayment.endTime = _endTime;
        recurringPayment.periodInterval = _periodInterval;
        recurringPayment.lastDistributionTime = 0;
        recurringPayment.tokenToDistribute = _tokenToDistribute;
        recurringPayment.pausedAt = 0;
        recurringPayment.pausedDuration = 0;
        recurringPayment.revoked = false;
        recurringPayment.distributionFeeToken = _distributionFeeToken;
        recurringPayment.distributionFeeAmount = _distributionFeeAmount;

        // emit the event before incrementing the counter
        emit NewRecurringPayment(
            recurringPaymentCounter,
            _startTime,
            _endTime,
            _periodInterval,
            _tokenToDistribute,
            _distributionFeeToken,
            _distributionFeeAmount
        );

        recurringPaymentCounter++;
    }

    /**
     * @notice Distributes tokens to beneficiaries for all eligible periods
     * @dev Includes reentrancy protection
     * @param _recurringPaymentId The ID of the recurring payment to distribute
     */
    function distribute(uint256 _recurringPaymentId) public nonReentrant onlyValidRecurringPaymentId(_recurringPaymentId){

        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];

        require(canDistribute(_recurringPaymentId), "Cannot distribute yet");

        uint256 periods = periodsToDistribute(_recurringPaymentId);

        recurringPayment.lastDistributionTime = block.timestamp;
        recurringPayment.pausedDuration = 0;

        for (uint256 i = 0; i < EnumerableSet.length(recurringPayment.beneficiaries); i++) {
            IERC20(recurringPayment.tokenToDistribute).safeTransfer(
                EnumerableSet.at(recurringPayment.beneficiaries, i),
                recurringPayment.beneficiaryToAmount[EnumerableSet.at(recurringPayment.beneficiaries, i)] * periods
            );
        }

        if (recurringPayment.distributionFeeToken != address(0)) {
            IERC20(recurringPayment.distributionFeeToken).safeTransfer(msg.sender, recurringPayment.distributionFeeAmount);
        }

        emit Distribution(_recurringPaymentId, periods, block.timestamp);
    }

    /**
     * @notice Pauses multiple recurring payments
     * @dev Only callable by contract owner
     * @param _recurringPaymentIds Array of payment IDs to pause
     */
    function pauseRecurringPayments(uint256[] memory _recurringPaymentIds) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _recurringPaymentIds.length; i++) {
            _pauseRecurringPayment(_recurringPaymentIds[i]);
        }
    }

    function _pauseRecurringPayment(uint256 _recurringPaymentId) internal onlyValidRecurringPaymentId(_recurringPaymentId) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];
        require(recurringPayment.pausedAt == 0, "Payment already paused");
        recurringPayment.pausedAt = block.timestamp;
        emit RecurringPaymentPaused(_recurringPaymentId);
    }

    /**
     * @notice Unpauses multiple recurring payments
     * @dev Only callable by contract owner
     * @param _recurringPaymentIds Array of payment IDs to unpause
     */
    function unpauseRecurringPayments(uint256[] memory _recurringPaymentIds) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _recurringPaymentIds.length; i++) {
            _unpauseRecurringPayment(_recurringPaymentIds[i]);
        }
    }

    function _unpauseRecurringPayment(uint256 _recurringPaymentId) internal onlyValidRecurringPaymentId(_recurringPaymentId) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];
        require(recurringPayment.pausedAt != 0, "Payment not paused");

        recurringPayment.pausedDuration += block.timestamp - recurringPayment.pausedAt;

        recurringPayment.pausedAt = 0;
        emit RecurringPaymentUnpaused(_recurringPaymentId);
    }

    /**
     * @notice Revokes multiple recurring payments
     * @dev Only callable by contract owner
     * @param _recurringPaymentIds Array of payment IDs to revoke
     */
    function revokeRecurringPayments(uint256[] memory _recurringPaymentIds) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _recurringPaymentIds.length; i++) {
            _revokeRecurringPayment(_recurringPaymentIds[i]);
        }
    }

    function _revokeRecurringPayment(uint256 _recurringPaymentId) internal onlyValidRecurringPaymentId(_recurringPaymentId) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];
        require(!recurringPayment.revoked, "Recurring payment already revoked");
        recurringPayment.revoked = true;

        emit DistributionRevoked(_recurringPaymentId);
    }

    /**
     * @notice Checks if a recurring payment can be distributed
     * @param _recurringPaymentId The ID of the recurring payment to check
     * @return bool True if distribution is possible
     */
    function canDistribute(uint256 _recurringPaymentId) public view onlyValidRecurringPaymentId(_recurringPaymentId) returns (bool) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];

        // block distribution if the payment has not started yet
        require(block.timestamp >= recurringPayment.startTime, "Recurring payment period did not start yet");

        // block distribution if the payment has been revoked
        // even if some periods are pending distribution
        require(!recurringPayment.revoked, "Recurring payment has been revoked");

        uint256 periods = periodsToDistribute(_recurringPaymentId);
        if (periods == 0) {
            // if the payment has an end time and no periods to distribute,
            // check if the end time has passed
            // only here for better error message
            require(
                recurringPayment.endTime == 0 || block.timestamp <= recurringPayment.endTime,
                "Recurring payment has ended"
            );
        }
        require(periods > 0, "No periods have passed since last distribution");

        // check if the the distributor has enough token to distribute
        // to cover the total amount to distribute for all beneficiaries and all periods
        uint256 distributorTokenBalance = IERC20(recurringPayment.tokenToDistribute).balanceOf(address(this));
        uint256 totalAmountToDistribute = _getTotalAmountToDistribute(_recurringPaymentId, periods);
        require(distributorTokenBalance >= totalAmountToDistribute, "Insufficient token balance for distribution");

        return true;
    }

    /**
     * @notice Calculates the number of periods available for distribution
     * @dev Accounts for paused time and payment schedule
     * @param _recurringPaymentId The ID of the recurring payment
     * @return uint256 Number of periods that can be distributed
     */
    function periodsToDistribute(uint256 _recurringPaymentId) public view onlyValidRecurringPaymentId(_recurringPaymentId) returns (uint256) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];

        uint256 fromTime = recurringPayment.lastDistributionTime > 0
            ? recurringPayment.lastDistributionTime
            : recurringPayment.startTime;

        uint256 toTime = recurringPayment.endTime > 0 && block.timestamp > recurringPayment.endTime
            ? recurringPayment.endTime
            : block.timestamp;

        // Add paused duration
        // => case where the payment was paused for a while, then unpaused but still not distributed
        uint256 totalPausedDuration = recurringPayment.pausedDuration;
        if (recurringPayment.pausedAt != 0) {
            // if the payment is currently paused, add the time since the last pause to the total paused time
            totalPausedDuration += block.timestamp - recurringPayment.pausedAt;
        }

        // if the total paused duration is greater than the elapsed time,
        // it means that no periods have passed since the last pause
        if (totalPausedDuration > toTime - fromTime) {
            return 0;
        }

        // Calculate the elapsed time since the last distribution
        uint256 elapsedUnpausedDurationSinceLastDistribution = toTime - fromTime - totalPausedDuration;

        return elapsedUnpausedDurationSinceLastDistribution / recurringPayment.periodInterval;
    }

    /**
     * @notice Allows owner to withdraw tokens from the contract
     * @dev Supports both ERC20 tokens and native currency
     * @param _token The token address (0 address for native currency)
     * @param _amount Amount to withdraw
     * @param _beneficiary Address to receive the withdrawal
     */
    function withdrawFunds(address _token, uint256 _amount, address _beneficiary) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount > 0, "Amount must be greater than 0");
        require(_beneficiary != address(0), "Beneficiary address cannot be 0x0");
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Insufficient token balance for distribution");

        if (_token == address(0)) {
            // if the token is the native currency, transfer it to the beneficiary as a native token
            payable(_beneficiary).transfer(_amount);
            return;
        }
        IERC20(_token).safeTransfer(_beneficiary, _amount);
    }

    // Helpers
    /**
     * @notice Calculates the total amount to distribute for a given number of periods
     * @param _recurringPaymentId The ID of the recurring payment
     * @param _periodsToDistribute The number of periods to distribute
     * @return uint256 The total amount to distribute
     */
    function _getTotalAmountToDistribute(
        uint256 _recurringPaymentId,
        uint256 _periodsToDistribute
    ) internal view returns (uint256) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < EnumerableSet.length(recurringPayment.beneficiaries); i++) {
            totalAmount += recurringPayment.beneficiaryToAmount[EnumerableSet.at(recurringPayment.beneficiaries, i)];
        }
        return totalAmount * _periodsToDistribute;
    }

    // Getters

    /**
     * @notice Returns the IDs of all recurring payments
     * @return uint256[] Array of payment IDs
     */
    function getRecurringPaymentIds() public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](recurringPaymentCounter);
        for (uint256 i = 0; i < recurringPaymentCounter; i++) {
            ids[i] = i;
        }
        return ids;
    }

    /**
     * @notice Returns the details of a recurring payment
     * @param _recurringPaymentId The ID of the recurring payment
     * @return uint256 The start time
     * @return uint256 The end time
     * @return uint256 The period interval
     * @return uint256 The last distribution time
     */
    function getRecurringPayment(
        uint256 _recurringPaymentId
    )
        public
        view
        onlyValidRecurringPaymentId(_recurringPaymentId)
        returns (
            uint256, // 0: startTime
            uint256, // 1: endTime
            uint256, // 2: periodInterval
            uint256, // 3: lastDistributionTime
            address, // 4: tokenToDistribute
            address[] memory, // 5: beneficiaries
            uint256[] memory, // 6: beneficiariesAmounts
            address, // 7: distributionFeeToken
            uint256, // 8: distributionFeeAmount
            uint256, // 9: pausedAt
            uint256, // 10: pausedDuration
            bool // 11: revoked
        )
    {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];

        uint256[] memory beneficiariesAmounts = new uint256[](EnumerableSet.length(recurringPayment.beneficiaries));

        for (uint256 i = 0; i < EnumerableSet.length(recurringPayment.beneficiaries); i++) {
            beneficiariesAmounts[i] = recurringPayment.beneficiaryToAmount[
                EnumerableSet.at(recurringPayment.beneficiaries, i)
            ];
        }

        return (
            recurringPayment.startTime,
            recurringPayment.endTime,
            recurringPayment.periodInterval,
            recurringPayment.lastDistributionTime,
            recurringPayment.tokenToDistribute,
            EnumerableSet.values(recurringPayment.beneficiaries),
            beneficiariesAmounts,
            recurringPayment.distributionFeeToken,
            recurringPayment.distributionFeeAmount,
            recurringPayment.pausedAt,
            recurringPayment.pausedDuration,
            recurringPayment.revoked
        );
    }

    /**
     * @notice Returns the distribution fee token and amount for a recurring payment
     * @param _recurringPaymentId The ID of the recurring payment
     * @return address The distribution fee token address
     * @return uint256 The distribution fee amount
     */
    function getDistributionFee(uint256 _recurringPaymentId) public view onlyValidRecurringPaymentId(_recurringPaymentId) returns (address, uint256) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];
        return (recurringPayment.distributionFeeToken, recurringPayment.distributionFeeAmount);
    }

    // Setters
    /**
     * @notice Updates the distribution fee configuration for a recurring payment
     * @dev Only callable by contract owner and when payment is not revoked
     * @param _recurringPaymentId The ID of the recurring payment to update
     * @param _distributionFeeToken The new distribution fee token address
     * @param _distributionFeeAmount The new distribution fee amount
     */
    function setDistributionFee(
        uint256 _recurringPaymentId,
        address _distributionFeeToken,
        uint256 _distributionFeeAmount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyValidRecurringPaymentId(_recurringPaymentId) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];
        require(!recurringPayment.revoked, "Recurring payment is revoked");

        emit DistributionFeeSet(
            recurringPayment.distributionFeeToken,
            recurringPayment.distributionFeeAmount,
            _distributionFeeToken,
            _distributionFeeAmount
        );

        recurringPayment.distributionFeeToken = _distributionFeeToken;
        recurringPayment.distributionFeeAmount = _distributionFeeAmount;
    }

    // Fallbacks that prevent ETH deposits
    receive() external payable {
        revert("This contract does not accept ETH, use WETH instead");
    }

    fallback() external payable {
        revert("This contract does not accept ETH, use WETH instead");
    }
}
