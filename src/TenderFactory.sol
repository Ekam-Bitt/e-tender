// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Tender.sol";

contract TenderFactory {
    event TenderContractDeployed(address indexed tenderAddress, address indexed authority);

    function createTender(
        string memory _configIpfsHash,
        uint256 _biddingTime,
        uint256 _revealTime,
        uint256 _bidBondAmount
    ) external returns (address) {
        Tender newTender = new Tender(msg.sender, _configIpfsHash, _biddingTime, _revealTime, _bidBondAmount);
        
        emit TenderContractDeployed(address(newTender), msg.sender);
        
        return address(newTender);
    }
}
