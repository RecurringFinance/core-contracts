// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Distributor} from "../../src/Distributor.sol";

contract DistributorAccessControlTest is Test {
    Distributor public distributor;
    address public owner;
    address public admin2;
    address public admin3;
    address public nonAdmin;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        owner = address(this);
        admin2 = makeAddr("admin2");
        admin3 = makeAddr("admin3");
        nonAdmin = makeAddr("nonAdmin");

        distributor = new Distributor(owner);
    }

    function test_accessControl_initial_admin_role() public view {
        assertTrue(distributor.hasRole(DEFAULT_ADMIN_ROLE, owner));
        assertFalse(distributor.hasRole(DEFAULT_ADMIN_ROLE, nonAdmin));
    }

    function test_accessControl_grant_admin_role() public {
        distributor.grantRole(DEFAULT_ADMIN_ROLE, admin2);
        assertTrue(distributor.hasRole(DEFAULT_ADMIN_ROLE, admin2));

        // Admin2 should now be able to grant admin role to admin3
        vm.prank(admin2);
        distributor.grantRole(DEFAULT_ADMIN_ROLE, admin3);
        assertTrue(distributor.hasRole(DEFAULT_ADMIN_ROLE, admin3));
    }

    function test_accessControl_revoke_admin_role() public {
        distributor.grantRole(DEFAULT_ADMIN_ROLE, admin2);
        assertTrue(distributor.hasRole(DEFAULT_ADMIN_ROLE, admin2));

        distributor.revokeRole(DEFAULT_ADMIN_ROLE, admin2);
        assertFalse(distributor.hasRole(DEFAULT_ADMIN_ROLE, admin2));
    }

    function test_accessControl_non_admin_cannot_grant() public {
        vm.expectRevert();
        vm.prank(nonAdmin);
        distributor.grantRole(DEFAULT_ADMIN_ROLE, admin2);
    }

    function test_accessControl_multiple_admins_can_manage_roles() public {
        // Owner grants admin to admin2
        distributor.grantRole(DEFAULT_ADMIN_ROLE, admin2);

        // Admin2 grants admin to admin3
        vm.prank(admin2);
        distributor.grantRole(DEFAULT_ADMIN_ROLE, admin3);

        // Verify all admins have the role
        assertTrue(distributor.hasRole(DEFAULT_ADMIN_ROLE, owner));
        assertTrue(distributor.hasRole(DEFAULT_ADMIN_ROLE, admin2));
        assertTrue(distributor.hasRole(DEFAULT_ADMIN_ROLE, admin3));

        // Admin3 can revoke admin2's role
        vm.prank(admin3);
        distributor.revokeRole(DEFAULT_ADMIN_ROLE, admin2);
        assertFalse(distributor.hasRole(DEFAULT_ADMIN_ROLE, admin2));
    }
}
