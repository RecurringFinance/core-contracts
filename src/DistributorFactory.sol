// ▗▄▄▖ ▗▄▄▄▖ ▗▄▄▖▗▖ ▗▖▗▄▄▖ ▗▄▄▖ ▗▄▄▄▖▗▖  ▗▖ ▗▄▄▖
// ▐▌ ▐▌▐▌   ▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌  █  ▐▛▚▖▐▌▐▌   
// ▐▛▀▚▖▐▛▀▀▘▐▌   ▐▌ ▐▌▐▛▀▚▖▐▛▀▚▖  █  ▐▌ ▝▜▌▐▌▝▜▌
// ▐▌ ▐▌▐▙▄▄▖▝▚▄▄▖▝▚▄▞▘▐▌ ▐▌▐▌ ▐▌▗▄█▄▖▐▌  ▐▌▝▚▄▞▘

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Distributor.sol";
import "./interfaces/IDistributorFactory.sol";

contract DistributorFactory is IDistributorFactory {
    mapping(address => address[]) public ownerToDistributors;
    address[] public allDistributors;

    constructor() {}

    /**
     * @notice Creates a new Distributor contract and assigns ownership to the caller.
     * @return The address of the newly created Distributor contract.
     */
    function newDistributor() public returns (address) {
        Distributor distributor = new Distributor(msg.sender);
        ownerToDistributors[msg.sender].push(address(distributor));
        allDistributors.push(address(distributor));
        emit NewDistributorEvent(address(distributor), msg.sender);
        return address(distributor);
    }

    /**
     * @notice Returns the Distributor contracts owned by the caller.
     * @return An array of Distributor contract addresses owned by the caller.
     */
    function getOwnerDistributors() public view returns (address[] memory) {
        return ownerToDistributors[msg.sender];
    }

    /**
     * @notice Returns all Distributor contracts created by the factory.
     * @return An array of all Distributor contract addresses.
     */
    function getAllDistributors() public view returns (address[] memory) {
        return allDistributors;
    }

}
