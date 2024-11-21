// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
interface IDistributorFactory {
    /**
     * @dev Emitted when a new Distributor is created.
     * @param distributorAddress The address of the newly created Distributor contract.
     * @param owner The owner of the new Distributor contract.
     */
    event NewDistributorEvent(address distributorAddress, address owner);

    // Functions
    function newDistributor(address _owner) external returns (address);

    function getAllDistributors() external view returns (address[] memory);

    function getOwnerDistributors(address _owner) external view returns (address[] memory);

}
