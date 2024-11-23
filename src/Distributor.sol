// ▗▄▄▖ ▗▄▄▄▖ ▗▄▄▖▗▖ ▗▖▗▄▄▖ ▗▄▄▖ ▗▄▄▄▖▗▖  ▗▖ ▗▄▄▖
// ▐▌ ▐▌▐▌   ▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌  █  ▐▛▚▖▐▌▐▌
// ▐▛▀▚▖▐▛▀▀▘▐▌   ▐▌ ▐▌▐▛▀▚▖▐▛▀▚▖  █  ▐▌ ▝▜▌▐▌▝▜▌
// ▐▌ ▐▌▐▙▄▄▖▝▚▄▄▖▝▚▄▞▘▐▌ ▐▌▐▌ ▐▌▗▄█▄▖▐▌  ▐▌▝▚▄▞▘

// https://recurring.finance

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// OpenZeppelin libraries
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Custom libraries
import "./libraries/DateTimeLibrary.sol";

// Interfaces
import "./interfaces/IDistributor.sol";

/**
 * @title Distributor
 * @notice Manages recurring token payments to multiple beneficiaries with optional rewards
 * @dev Implements reentrancy protection and access controls roles
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
        CronLibrary.CronSchedule cronSchedule;
        uint256 distributedUpToTime;
        uint256 lastDistributionTime;
        address tokenToDistribute;
        EnumerableSet.AddressSet beneficiaries;
        mapping(address => uint256) beneficiaryToAmount;
        address distributionFeeToken;
        uint256 distributionFeeAmount;
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
     * @param _cronSchedules Array of cron schedules
     * @param _beneficiaries Array of beneficiaries addresses arrays
     * @param _beneficiariesAmounts Array of payments amounts arrays
     * @param _tokensToDistribute Array of token addresses to distribute
     * @param _distributionFeeTokens Array of distribution fee token addresses
     * @param _distributionFeeAmounts Array of distribution fee amounts
     */
    function createRecurringPayments(
        uint256[] memory _startTimes,
        uint256[] memory _endTimes,
        CronLibrary.CronSchedule[] memory _cronSchedules,
        address[][] memory _beneficiaries,
        uint256[][] memory _beneficiariesAmounts,
        address[] memory _tokensToDistribute,
        address[] memory _distributionFeeTokens,
        uint256[] memory _distributionFeeAmounts
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_startTimes.length > 0, "There must be a start date");
        require(
            _startTimes.length == _endTimes.length &&
                _startTimes.length == _cronSchedules.length &&
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

            _createRecurringPayment(
                _startTimes[i],
                _endTimes[i],
                _cronSchedules[i],
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
     * @param _startTime The start time of the recurring payment
     * @param _endTime The end time of the recurring payment
     * @param _cronSchedule The cron schedule of the recurring payment
     * @param _beneficiaries The beneficiaries of the recurring payment
     * @param _beneficiariesAmounts The amounts to distribute to each beneficiary
     * @param _tokenToDistribute The token to distribute
     * @param _distributionFeeToken The distribution fee token
     * @param _distributionFeeAmount The distribution fee amount
     */
    function _createRecurringPayment(
        uint256 _startTime,
        uint256 _endTime,
        CronLibrary.CronSchedule memory _cronSchedule,
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

        CronLibrary.validateCronSchedule(_cronSchedule);

        recurringPayment.startTime = _startTime;
        recurringPayment.endTime = _endTime;
        recurringPayment.cronSchedule = _cronSchedule;
        recurringPayment.distributedUpToTime = 0;
        recurringPayment.lastDistributionTime = 0;
        recurringPayment.tokenToDistribute = _tokenToDistribute;
        recurringPayment.revoked = false;
        recurringPayment.distributionFeeToken = _distributionFeeToken;
        recurringPayment.distributionFeeAmount = _distributionFeeAmount;

        // emit the event before incrementing the counter
        emit NewRecurringPayment(
            recurringPaymentCounter,
            _startTime,
            _endTime,
            _cronSchedule,
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
     * @param _maxPeriods The maximum number of periods to distribute
     */
    function distribute(
        uint256 _recurringPaymentId,
        uint256 _maxPeriods
    ) public nonReentrant onlyValidRecurringPaymentId(_recurringPaymentId) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];

        require(canDistribute(_recurringPaymentId), "Cannot distribute yet");

        (uint256 periods, uint256 nextDistributionStartTime) = periodsToDistribute(_recurringPaymentId, _maxPeriods);

        recurringPayment.distributedUpToTime = nextDistributionStartTime;
        recurringPayment.lastDistributionTime = block.timestamp;

        for (uint256 i = 0; i < EnumerableSet.length(recurringPayment.beneficiaries); i++) {
            IERC20(recurringPayment.tokenToDistribute).safeTransfer(
                EnumerableSet.at(recurringPayment.beneficiaries, i),
                recurringPayment.beneficiaryToAmount[EnumerableSet.at(recurringPayment.beneficiaries, i)] * periods
            );
        }

        if (recurringPayment.distributionFeeToken != address(0)) {
            uint256 feeBalance = IERC20(recurringPayment.distributionFeeToken).balanceOf(address(this));
            uint256 feeToSend = Math.min(feeBalance, recurringPayment.distributionFeeAmount);

            if (feeToSend > 0) {
                IERC20(recurringPayment.distributionFeeToken).safeTransfer(msg.sender, feeToSend);
            }
        }

        emit Distribution(_recurringPaymentId, periods, block.timestamp);
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

    /**
     * @notice Internal function to revoke a recurring payment
     * @param _recurringPaymentId The ID of the recurring payment to revoke
     */
    function _revokeRecurringPayment(
        uint256 _recurringPaymentId
    ) internal onlyValidRecurringPaymentId(_recurringPaymentId) {
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
    function canDistribute(
        uint256 _recurringPaymentId
    ) public view onlyValidRecurringPaymentId(_recurringPaymentId) returns (bool) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];

        // block distribution if the payment has not started yet
        require(block.timestamp >= recurringPayment.startTime, "Recurring payment period did not start yet");

        // block distribution if the payment has been revoked
        // even if some periods are pending distribution
        require(!recurringPayment.revoked, "Recurring payment has been revoked");

        (uint256 periods, ) = periodsToDistribute(_recurringPaymentId, 1);
        if (periods == 0) {
            // if the payment has an end time and no periods to distribute,
            // check if the end time has passed
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
     * @dev Accounts for payment schedule
     * @param _recurringPaymentId The ID of the recurring payment
     * @return uint256 Number of periods that can be distributed
     */
    function periodsToDistribute(
        uint256 _recurringPaymentId,
        uint256 _maxPeriodsToDistribute
    )
        public
        view
        onlyValidRecurringPaymentId(_recurringPaymentId)
        returns (
            uint256, // 0: periods to distribute (up to _maxPeriodsToDistribute)
            uint256 // 1: next distribution start time (depends on _maxPeriodsToDistribute)
        )
    {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];
        uint256 currentTime = block.timestamp;

        if (_maxPeriodsToDistribute == 0) {
            // default max periods to 100 to save gas
            _maxPeriodsToDistribute = 100;
        }

        if (
            currentTime < recurringPayment.startTime || // payment has not started yet
            recurringPayment.revoked // payment has been revoked
        ) {
            return (0, recurringPayment.distributedUpToTime);
        }

        uint256 fromTime = recurringPayment.distributedUpToTime > 0
            ? recurringPayment.distributedUpToTime + DateTime.SECONDS_PER_HOUR // add 1 hour to the last distribution time to avoid distributing tokens for the same period multiple times (in the same hour)
            : recurringPayment.startTime;

        uint256 toTime = recurringPayment.endTime > 0 && currentTime > recurringPayment.endTime
            ? recurringPayment.endTime
            : currentTime;

        uint256 periodCount = 0;

        // Start from the last distribution time rounded down to the nearest hour
        // => this is to avoid distributing tokens for the same period multiple times (in the same hour)
        uint256 timestamp = fromTime - (fromTime % DateTime.SECONDS_PER_HOUR);

        CronLibrary.CronSchedule memory cs = recurringPayment.cronSchedule;

        uint256 timeStep = CronLibrary.getMinCronInterval(cs);

        while (timestamp <= currentTime && timestamp <= toTime && periodCount < _maxPeriodsToDistribute) {
            if (CronLibrary.matchesCron(timestamp, cs)) {
                periodCount++;
            }
            // jump to the next minimum cron schedule time step
            if (timeStep == 0) {
                // if the time step is 0, it means that we need to jump month per month
                // we use the DateTime.addMonths function to do this
                // this function will make sure to jump to the next month (supports leap years)
                timestamp = DateTime.addMonths(timestamp, 1);
            } else {
                timestamp += timeStep;
            }
        }

        // return the number of periods and the last distribution time
        // the last distribution time won't be the current timestamp if we are distributing less periods than possible
        // (aka if maxPeriods is less than the number of periods that can be distributed)
        return (periodCount, timestamp - timeStep);
    }

    /**
     * @notice Allows owner to withdraw tokens from the contract
     * @dev Supports both ERC20 tokens and native currency (contract does not accepts native currency deposits but support added just in case)
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
     * @notice Returns the details of a recurring payment
     * @param _recurringPaymentId The ID of the recurring payment
     * @return uint256 The start time
     * @return uint256 The end time
     * @return CronSchedule The cron schedule
     * @return uint256 The distributed up to time
     * @return uint256 The last distribution time
     * @return address The token to distribute
     * @return address[] The beneficiaries
     * @return uint256[] The beneficiaries amounts
     * @return bool The revoked status
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
            CronLibrary.CronSchedule memory, // 2: cronSchedule
            uint256, // 3: distributedUpToTime
            uint256, // 4: lastDistributionTime
            address, // 5: tokenToDistribute
            address[] memory, // 6: beneficiaries
            uint256[] memory, // 7: beneficiariesAmounts
            bool // 8: revoked
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
            recurringPayment.cronSchedule,
            recurringPayment.distributedUpToTime,
            recurringPayment.lastDistributionTime,
            recurringPayment.tokenToDistribute,
            EnumerableSet.values(recurringPayment.beneficiaries),
            beneficiariesAmounts,
            recurringPayment.revoked
        );
    }

    /**
     * @notice Returns the distribution fee token and amount for a recurring payment
     * @param _recurringPaymentId The ID of the recurring payment
     * @return address The distribution fee token address
     * @return uint256 The distribution fee amount
     */
    function getDistributionFee(
        uint256 _recurringPaymentId
    ) public view onlyValidRecurringPaymentId(_recurringPaymentId) returns (address, uint256) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];
        return (recurringPayment.distributionFeeToken, recurringPayment.distributionFeeAmount);
    }

    // Setters

    /**
     * @notice Updates the end time of a recurring payment
     * @dev Only callable by contract owner
     * @param _recurringPaymentId The ID of the recurring payment
     * @param _newEndTime The new end time
     */
    function setEndTime(
        uint256 _recurringPaymentId,
        uint256 _newEndTime
    ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyValidRecurringPaymentId(_recurringPaymentId) {
        RecurringPayment storage recurringPayment = recurringPayments[_recurringPaymentId];
        require(
            recurringPayment.endTime == 0 || recurringPayment.endTime > block.timestamp,
            "Current end time has already passed"
        );
        require(_newEndTime > block.timestamp, "New end time must be in the future");
        recurringPayment.endTime = _newEndTime;
        emit EndTimeSet(_recurringPaymentId, _newEndTime);
    }

    // Fallbacks that prevent ETH deposits
    receive() external payable {
        revert("This contract does not accept ETH, use WETH instead");
    }

    fallback() external payable {
        revert("This contract does not accept ETH, use WETH instead");
    }
}
