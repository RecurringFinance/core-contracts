// ▗▄▄▖ ▗▄▄▄▖ ▗▄▄▖▗▖ ▗▖▗▄▄▖ ▗▄▄▖ ▗▄▄▄▖▗▖  ▗▖ ▗▄▄▖
// ▐▌ ▐▌▐▌   ▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌  █  ▐▛▚▖▐▌▐▌
// ▐▛▀▚▖▐▛▀▀▘▐▌   ▐▌ ▐▌▐▛▀▚▖▐▛▀▚▖  █  ▐▌ ▝▜▌▐▌▝▜▌
// ▐▌ ▐▌▐▙▄▄▖▝▚▄▄▖▝▚▄▞▘▐▌ ▐▌▐▌ ▐▌▗▄█▄▖▐▌  ▐▌▝▚▄▞▘

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Distributor.sol";
import "./interfaces/IDistributorFactory.sol";

/**
 * @title DistributorFactory
 * @notice Manages creation and retrieval of Distributor contracts
 */
contract DistributorFactory is IDistributorFactory {
    // Mapping to store Distributor contracts by owner
    mapping(address => address[]) public ownerToDistributors;
    // Array to store all Distributor contracts
    address[] public allDistributors;

    constructor() {}

    /**
     * @notice Creates a new Distributor contract and assigns ownership to the caller.
     * @param _owner The address to assign ownership to.
     * @return The address of the newly created Distributor contract.
     */
    function newDistributor(address _owner) public returns (address) {
        Distributor distributor = new Distributor(_owner);
        ownerToDistributors[_owner].push(address(distributor));
        allDistributors.push(address(distributor));
        emit NewDistributorEvent(address(distributor), _owner);
        return address(distributor);
    }

    /**
     * @notice Returns the Distributor contracts owned by the caller.
     * @param _owner The address to get the Distributor contracts for.
     * @return An array of Distributor contract addresses owned by the caller.
     */
    function getOwnerDistributors(address _owner) public view returns (address[] memory) {
        return ownerToDistributors[_owner];
    }

    /**
     * @notice Returns all Distributor contracts created by the factory.
     * @return An array of all Distributor contract addresses.
     */
    function getAllDistributors() public view returns (address[] memory) {
        return allDistributors;
    }
}
