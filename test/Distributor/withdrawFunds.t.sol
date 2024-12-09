pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../src/DistributorFactory.sol";
import {MockERC20} from "./Distributor.t.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract WithdrawFundsTest is Test {
    address public owner;
    Distributor public distributor;
    MockERC20 public tokenToDistribute;
    MockERC20 public rewardToken;

    function setUp() public {
        owner = address(this);

        // Deploy mock tokens
        tokenToDistribute = new MockERC20("Distribute Token", "DST", 1_000_000 ether);
        rewardToken = new MockERC20("Reward Token", "RWT", 1_000_000 ether);

        // Deploy Distributor with the owner address
        distributor = new Distributor(owner);

        // Transfer tokens to Distributor contract
        tokenToDistribute.transfer(address(distributor), 500_000 ether);
        rewardToken.transfer(address(distributor), 500_000 ether);
    }

    function test_withdrawFunds_successful_withdrawal() public {
        address beneficiary = address(0x123);
        uint256 withdrawAmount = 1000 ether;

        uint256 initialBalance = tokenToDistribute.balanceOf(beneficiary);
        distributor.withdrawFunds(address(tokenToDistribute), withdrawAmount, beneficiary);
        uint256 finalBalance = tokenToDistribute.balanceOf(beneficiary);

        assertEq(finalBalance - initialBalance, withdrawAmount);
    }

    function test_withdrawFunds_only_owner_can_withdraw() public {
        address nonOwner = address(0x123);
        uint256 withdrawAmount = 1000 ether;
        address beneficiary = address(0x456);

        vm.prank(nonOwner);
        vm.expectRevert();
        distributor.withdrawFunds(address(tokenToDistribute), withdrawAmount, beneficiary);
    }

    function test_withdrawFunds_cannot_withdraw_zero_amount() public {
        address beneficiary = address(0x123);
        uint256 withdrawAmount = 0;

        vm.expectRevert("Amount must be greater than 0");
        distributor.withdrawFunds(address(tokenToDistribute), withdrawAmount, beneficiary);
    }

    function test_withdrawFunds_cannot_withdraw_to_zero_address() public {
        address beneficiary = address(0);
        uint256 withdrawAmount = 1000 ether;

        vm.expectRevert("Beneficiary address cannot be 0x0");
        distributor.withdrawFunds(address(tokenToDistribute), withdrawAmount, beneficiary);
    }

    function test_withdrawFunds_cannot_withdraw_more_than_balance() public {
        address beneficiary = address(0x123);
        uint256 withdrawAmount = 1_000_000_000 ether; // More than contract balance

        vm.expectRevert("Insufficient token balance for distribution");
        distributor.withdrawFunds(address(tokenToDistribute), withdrawAmount, beneficiary);
    }

    function test_withdrawFunds_multiple_successful_withdrawals() public {
        address beneficiary = address(0x123);
        uint256 withdrawAmount = 1000 ether;

        uint256 initialBalance = tokenToDistribute.balanceOf(beneficiary);

        // First withdrawal
        distributor.withdrawFunds(address(tokenToDistribute), withdrawAmount, beneficiary);
        uint256 intermediateBalance = tokenToDistribute.balanceOf(beneficiary);
        assertEq(intermediateBalance - initialBalance, withdrawAmount);

        // Second withdrawal
        distributor.withdrawFunds(address(tokenToDistribute), withdrawAmount, beneficiary);
        uint256 finalBalance = tokenToDistribute.balanceOf(beneficiary);
        assertEq(finalBalance - intermediateBalance, withdrawAmount);
    }

    function test_withdrawFunds_different_tokens() public {
        address beneficiary = address(0x123);
        uint256 withdrawAmount = 1000 ether;

        uint256 initialBalance1 = tokenToDistribute.balanceOf(beneficiary);
        uint256 initialBalance2 = rewardToken.balanceOf(beneficiary);

        // Withdraw first token
        distributor.withdrawFunds(address(tokenToDistribute), withdrawAmount, beneficiary);
        // Withdraw second token
        distributor.withdrawFunds(address(rewardToken), withdrawAmount, beneficiary);

        uint256 finalBalance1 = tokenToDistribute.balanceOf(beneficiary);
        uint256 finalBalance2 = rewardToken.balanceOf(beneficiary);

        assertEq(finalBalance1 - initialBalance1, withdrawAmount);
        assertEq(finalBalance2 - initialBalance2, withdrawAmount);
    }

    function test_withdrawFunds_different_beneficiaries() public {
        address beneficiary1 = address(0x123);
        address beneficiary2 = address(0x456);
        uint256 withdrawAmount = 1000 ether;

        uint256 initialBalance1 = tokenToDistribute.balanceOf(beneficiary1);
        uint256 initialBalance2 = tokenToDistribute.balanceOf(beneficiary2);

        distributor.withdrawFunds(address(tokenToDistribute), withdrawAmount, beneficiary1);
        distributor.withdrawFunds(address(tokenToDistribute), withdrawAmount, beneficiary2);

        uint256 finalBalance1 = tokenToDistribute.balanceOf(beneficiary1);
        uint256 finalBalance2 = tokenToDistribute.balanceOf(beneficiary2);

        assertEq(finalBalance1 - initialBalance1, withdrawAmount);
        assertEq(finalBalance2 - initialBalance2, withdrawAmount);
    }

    function test_withdrawFunds_entire_balance() public {
        address beneficiary = address(0x123);
        uint256 contractBalance = tokenToDistribute.balanceOf(address(distributor));

        uint256 initialBalance = tokenToDistribute.balanceOf(beneficiary);
        distributor.withdrawFunds(address(tokenToDistribute), contractBalance, beneficiary);
        uint256 finalBalance = tokenToDistribute.balanceOf(beneficiary);

        assertEq(finalBalance - initialBalance, contractBalance);
        assertEq(tokenToDistribute.balanceOf(address(distributor)), 0);
    }
}
