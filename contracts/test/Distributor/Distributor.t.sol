// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../src/Distributor.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 Token for testing
contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

// Helper contract to test contract-to-contract calls
contract CallerContract {
    function callDistribute(
        Distributor _distributor,
        uint256 _recurringPaymentId
    ) public {
        _distributor.distribute(_recurringPaymentId);
    }
}

// contract DistributorTest is Test {
//     address public owner;
//     Distributor public distributor;
//     MockERC20 public tokenToDistribute;
//     MockERC20 public rewardToken;

//     function setUp() public {
//         owner = address(this);

//         // Deploy mock tokens
//         tokenToDistribute = new MockERC20(
//             "Distribute Token",
//             "DST",
//             1_000_000 ether
//         );
//         rewardToken = new MockERC20("Reward Token", "RWT", 1_000_000 ether);

//         // Deploy Distributor with the owner address
//         distributor = new Distributor(owner);

//         // Transfer tokens to Distributor contract
//         tokenToDistribute.transfer(address(distributor), 500_000 ether);
//         rewardToken.transfer(address(distributor), 500_000 ether);
//     }

//     // Helper function to set up beneficiaries and amounts
//     function setupBeneficiariesAndAmounts()
//         internal
//         pure
//         returns (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         )
//     {
//         beneficiaries = new address[](2);
//         beneficiaries[0] = address(0x1);
//         beneficiaries[1] = address(0x2);

//         beneficiariesAmounts = new uint256[](2);
//         beneficiariesAmounts[0] = 10 ether;
//         beneficiariesAmounts[1] = 15 ether;
//     }

//     function testCreateRecurringPayment() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp + 1 days;
//         uint256 endTime = 0;
//         uint256 periodInterval = 1 days;
//         uint256 rewardAmount = 1 ether;

//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = endTime;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = periodInterval;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;

//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);

//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);

//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = rewardAmount;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );
//         (
//             uint256 retrievedStartTime,
//             uint256 retrievedEndTime,
//             uint256 retrievedPeriodInterval,
//             uint256 retrievedLastDistributionTime,
//             address retrievedTokenToDistribute,
//             address[] memory retrievedBeneficiaries,
//             uint256[] memory retrievedBeneficiariesAmounts,
//             address retrievedRewardToken,
//             uint256 retrievedRewardAmount,
//             uint256 pausedAt,
//             uint256 totalPausedTime,
//             bool revoked
//         ) = distributor.getRecurringPayment(0);

//         // Assertions
//         assertEq(retrievedStartTime, startTimes[0]);
//         assertEq(retrievedEndTime, endTime);
//         assertEq(retrievedPeriodInterval, periodInterval);
//         assertEq(retrievedLastDistributionTime, 0);
//         assertEq(retrievedTokenToDistribute, address(tokenToDistribute));
//         assertEq(retrievedRewardToken, address(rewardToken));
//         assertEq(retrievedRewardAmount, rewardAmount);
//         assertEq(revoked, false);

//         assertEq(retrievedBeneficiaries.length, beneficiaries.length);
//         for (uint256 i = 0; i < beneficiaries.length; i++) {
//             assertEq(retrievedBeneficiaries[i], beneficiaries[i]);
//         }
//         assertEq(retrievedBeneficiariesAmounts.length, beneficiaries.length);
//         for (uint256 i = 0; i < beneficiaries.length; i++) {
//             assertEq(retrievedBeneficiariesAmounts[i], beneficiariesAmounts[i]);
//         }
//     }

//     function testDistribute() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 1 days;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         // Fast forward time to allow distribution
//         vm.warp(block.timestamp + 2 days);

//         uint256 initialCallerRewardBalance = rewardToken.balanceOf(
//             address(this)
//         );
//         uint256 initialBeneficiary1Balance = tokenToDistribute.balanceOf(
//             beneficiaries[0]
//         );
//         uint256 initialBeneficiary2Balance = tokenToDistribute.balanceOf(
//             beneficiaries[1]
//         );

//         distributor.distribute(0);

//         uint256 periods = 2; // 2 days passed, so 2 periods
//         uint256 expectedBeneficiary1Balance = initialBeneficiary1Balance +
//             (beneficiariesAmounts[0] * periods);
//         uint256 expectedBeneficiary2Balance = initialBeneficiary2Balance +
//             (beneficiariesAmounts[1] * periods);
//         uint256 expectedCallerRewardBalance = initialCallerRewardBalance +
//             rewardAmounts[0];

//         // Assertions
//         assertEq(
//             tokenToDistribute.balanceOf(beneficiaries[0]),
//             expectedBeneficiary1Balance
//         );
//         assertEq(
//             tokenToDistribute.balanceOf(beneficiaries[1]),
//             expectedBeneficiary2Balance
//         );
//         assertEq(
//             rewardToken.balanceOf(address(this)),
//             expectedCallerRewardBalance
//         );

//         // Check last distribution time updated
//         (, , , uint256 lastDistributionTime, , , , , , , ,) = distributor
//             .getRecurringPayment(0);
//         uint256 expectedLastDistributionTime = startTimes[0] +
//             (periods * intervals[0]);
//         assertEq(lastDistributionTime, expectedLastDistributionTime);
//     }

//     function testCannotDistributeTooSoon() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 1 days;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         // Attempt to distribute without time advancement
//         vm.expectRevert("No periods have passed since last distribution");
//         distributor.distribute(0);
//     }

//     function testRevokeRecurringPayment() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 1 days;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         distributor.revokeRecurringPayment(0);

//         // Try to distribute after revocation
//         vm.warp(block.timestamp + 2 days);
//         vm.expectRevert("Recurring payment has been revoked");
//         distributor.distribute(0);
//     }

//     function testSetBeneficiariesAndAmounts() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp + 1 days;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 1 days;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         // New beneficiaries and amounts
//         address[] memory newBeneficiaries = new address[](2);
//         newBeneficiaries[0] = address(0x3);
//         newBeneficiaries[1] = address(0x4);

//         uint256[] memory newbeneficiariesAmounts = new uint256[](2);
//         newbeneficiariesAmounts[0] = 200 ether;
//         newbeneficiariesAmounts[1] = 300 ether;

//         distributor.setBeneficiariesAndAmounts(
//             0,
//             newBeneficiaries,
//             newbeneficiariesAmounts
//         );

//         (, , , , , address[] memory updatedBeneficiaries, , , , , ,) = distributor
//             .getRecurringPayment(0);

//         // Assertions
//         assertEq(updatedBeneficiaries.length, newBeneficiaries.length);
//         for (uint256 i = 0; i < newBeneficiaries.length; i++) {
//             assertEq(updatedBeneficiaries[i], newBeneficiaries[i]);
//         }
//     }

//     function testSetBounty() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp + 1 days;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 1 days;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         // New bounty details
//         MockERC20 newRewardToken = new MockERC20(
//             "New Reward Token",
//             "NRT",
//             1_000_000 ether
//         );
//         uint256 newRewardAmount = 100 ether;

//         // Transfer new reward tokens to contract
//         newRewardToken.transfer(address(distributor), 500_000 ether);

//         distributor.setBounty(0, address(newRewardToken), newRewardAmount);

//         (address updatedRewardToken, uint256 updatedRewardAmount) = distributor
//             .getBounty(0);

//         // Assertions
//         assertEq(updatedRewardToken, address(newRewardToken));
//         assertEq(updatedRewardAmount, newRewardAmount);
//     }

//     function testCannotReceiveETH() public {
//         vm.deal(address(this), 1 ether);

//         // Attempt to send ETH to the contract
//         (bool success, ) = address(distributor).call{value: 1 ether}("");
//         assertTrue(!success);
//     }

//     function testCannotReceiveETHWithData() public {
//         vm.deal(address(this), 1 ether);

//         // Attempt to send ETH with data
//         (bool success, ) = address(distributor).call{value: 1 ether}(
//             abi.encodeWithSignature("nonExistentFunction()")
//         );
//         assertTrue(!success);
//     }

//     function testDistributeBeforeStartTime() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp + 1 days;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 1 days;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         // Attempt to distribute before start time
//         vm.expectRevert("Recurring payment period did not start yet");
//         distributor.distribute(0);
//     }

//     function testDistributeWithZeroPeriodInterval() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 0;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         // Fast forward time
//         vm.warp(block.timestamp + 1 days);

//         // Attempt to distribute
//         vm.expectRevert(); // Should revert due to division by zero
//         distributor.distribute(0);
//     }

//     function testDistributeWithInsufficientTokenBalance() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 1 days;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         // Withdraw tokens from the contract, draining its balance
//         uint256 contractBalance = tokenToDistribute.balanceOf(
//             address(distributor)
//         );
//         // Withdraw funding tokens from the contract, draining its balance
//         distributor.withdrawFunds(
//             address(tokenToDistribute),
//             contractBalance,
//             address(this)
//         );
//         // Withdraw reward tokens from the contract, draining its balance
//         distributor.withdrawFunds(
//             address(rewardToken),
//             contractBalance,
//             address(this)
//         );

//         // Fast forward time
//         vm.warp(block.timestamp + 2 days);

//         // Attempt to distribute
//         vm.expectRevert("Insufficient token balance for distribution");
//         distributor.distribute(0);
//     }

//     function testNonOwnerCannotCreateRecurringPayment() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         // Transfer ownership to a new owner
//         address newOwner = address(0x10);
//         distributor.transferOwnership(newOwner);

//         vm.startPrank(address(0x11)); // Not the owner

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 1 days;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         // Expect the custom error from Ownable
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Ownable.OwnableUnauthorizedAccount.selector,
//                 address(0x11)
//             )
//         );
//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         vm.stopPrank();
//     }

//     function testDistributeCalledByContract() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 1 days;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         // Fast forward time
//         vm.warp(block.timestamp + 1 days);

//         // Deploy a contract that will call distribute
//         CallerContract caller = new CallerContract();

//         // add ether to the caller contract
//         vm.deal(address(caller), 1000 ether);

//         // Call distribute from the contract
//         caller.callDistribute(distributor, 0);

//         // Assertions to check distributions happened
//         uint256 expectedBeneficiary1Balance = beneficiariesAmounts[0];
//         uint256 expectedBeneficiary2Balance = beneficiariesAmounts[1];
//         uint256 expectedCallerRewardBalance = rewardAmounts[0];

//         // Check that last distribution date was updated
//         (, , , uint256 lastDistributionTime, , , , , , , ,) = distributor
//             .getRecurringPayment(0);

//         assertEq(lastDistributionTime, block.timestamp);

//         assertEq(
//             tokenToDistribute.balanceOf(beneficiaries[0]),
//             expectedBeneficiary1Balance
//         );
//         assertEq(
//             tokenToDistribute.balanceOf(beneficiaries[1]),
//             expectedBeneficiary2Balance
//         );
//         assertEq(
//             rewardToken.balanceOf(address(caller)),
//             expectedCallerRewardBalance
//         );
//     }

//     function testDistributeImmediatelyAfterDistribution() public {
//         (
//             address[] memory beneficiaries,
//             uint256[] memory beneficiariesAmounts
//         ) = setupBeneficiariesAndAmounts();

//         uint256[] memory startTimes = new uint256[](1);
//         startTimes[0] = block.timestamp;
//         uint256[] memory endTimes = new uint256[](1);
//         endTimes[0] = 0;
//         uint256[] memory intervals = new uint256[](1);
//         intervals[0] = 1 days;
//         address[][] memory beneficiariesArray = new address[][](1);
//         beneficiariesArray[0] = beneficiaries;
//         uint256[][] memory amountsArray = new uint256[][](1);
//         amountsArray[0] = beneficiariesAmounts;
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(tokenToDistribute);
//         address[] memory rewardTokens = new address[](1);
//         rewardTokens[0] = address(rewardToken);
//         uint256[] memory rewardAmounts = new uint256[](1);
//         rewardAmounts[0] = 1 ether;

//         distributor.createRecurringPayments(
//             startTimes,
//             endTimes,
//             intervals,
//             beneficiariesArray,
//             amountsArray,
//             tokens,
//             rewardTokens,
//             rewardAmounts
//         );

//         // Fast forward time to allow distribution
//         vm.warp(block.timestamp + 1 days);

//         distributor.distribute(0);

//         // Attempt to distribute again immediately
//         vm.expectRevert("No periods have passed since last distribution");
//         distributor.distribute(0);
//     }

//     function testWithdrawMoreThanBalance() public {
//         uint256 initialBalance = tokenToDistribute.balanceOf(
//             address(distributor)
//         );
//         uint256 withdrawAmount = initialBalance + 1 ether; // Try to withdraw more than the balance

//         vm.expectRevert("Insufficient token balance for distribution");
//         distributor.withdrawFunds(
//             address(tokenToDistribute),
//             withdrawAmount,
//             address(0x5)
//         );

//         // Verify that the balance hasn't changed
//         assertEq(
//             tokenToDistribute.balanceOf(address(distributor)),
//             initialBalance
//         );
//     }
// }
