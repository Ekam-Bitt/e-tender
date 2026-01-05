// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Tender.sol";

contract TenderFactory {
    event TenderContractDeployed(address indexed tenderAddress, address indexed authority);

    function createTender(
        address _verifier,
        address _evaluationStrategy,
        string calldata _configIpfsHash,
        uint256 _biddingTime,
        uint256 _revealTime,
        uint256 _bidBondAmount
    ) external returns (address) {
        Tender tender = new Tender(msg.sender, _verifier, _evaluationStrategy, _configIpfsHash, _biddingTime, _revealTime, _bidBondAmount);
        emit TenderContractDeployed(address(tender), msg.sender);
        return address(tender);
    }
}
