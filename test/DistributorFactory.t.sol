// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/DistributorFactory.sol";
import "../src/Distributor.sol";

contract DistributorFactoryTest is Test {
    // event NewDistributor(address indexed distributor, address indexed owner);

    DistributorFactory public factory;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        factory = new DistributorFactory();
    }

    function test_create_distributor() public {
        vm.prank(user1); // Set the user1 as the sender
        address distributorAddress = factory.newDistributor(user1);

        assertTrue(distributorAddress != address(0), "Distributor address should not be zero");

        vm.prank(user1); // Set the user1 as the sender
        address[] memory distributors = factory.getOwnerDistributors(user1);
        assertEq(distributors.length, 1, "Should have one Distributor");
        assertEq(distributors[0], distributorAddress, "Distributor address mismatch");
    }

    function test_create_multiple_distributors() public {
        vm.startPrank(user1);

        address distributor1 = factory.newDistributor(user1);
        address distributor2 = factory.newDistributor(user1);
        address distributor3 = factory.newDistributor(user1);

        address[] memory distributors = factory.getOwnerDistributors(user1);
        assertEq(distributors.length, 3, "Should have three Distributors");
        assertEq(distributors[0], distributor1, "First Distributor address mismatch");
        assertEq(distributors[1], distributor2, "Second Distributor address mismatch");
        assertEq(distributors[2], distributor3, "Third Distributor address mismatch");

        vm.stopPrank();
    }

    function test_distributor_ownership() public {
        vm.prank(user1);
        address distributorAddress = factory.newDistributor(user1);

        Distributor distributor = Distributor(payable(distributorAddress));

        assertEq(
            distributor.hasRole(distributor.DEFAULT_ADMIN_ROLE(), user1),
            true,
            "User1 should have DEFAULT_ADMIN_ROLE"
        );
    }

    function test_get_distributors_for_different_users() public {
        vm.prank(user1);
        factory.newDistributor(user1);

        vm.prank(user2);
        factory.newDistributor(user2);

        vm.prank(user1);
        address[] memory user1Distributors = factory.getOwnerDistributors(user1);
        assertEq(user1Distributors.length, 1, "User1 should have one Distributor");

        vm.prank(user2);
        address[] memory user2Distributors = factory.getOwnerDistributors(user2);
        assertEq(user2Distributors.length, 1, "User2 should have one Distributor");

        assertTrue(user1Distributors[0] != user2Distributors[0], "Users should have different Distributors");
    }

    function test_get_all_distributors() public {
        vm.prank(user1);
        address distributor1 = factory.newDistributor(user1);

        vm.prank(user2);
        address distributor2 = factory.newDistributor(user2);

        address[] memory allDistributors = factory.getAllDistributors();
        assertEq(allDistributors.length, 2, "Should have two Distributors in total");
        assertTrue(
            allDistributors[0] == distributor1 || allDistributors[1] == distributor1,
            "Distributor1 should be in the list"
        );
        assertTrue(
            allDistributors[0] == distributor2 || allDistributors[1] == distributor2,
            "Distributor2 should be in the list"
        );
    }
}
