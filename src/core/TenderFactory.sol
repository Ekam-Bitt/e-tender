// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Tender } from "./Tender.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TenderFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    event TenderContractDeployed(address indexed matchAddr, address indexed creator);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }

    function createTender(
        Tender.IdentityMode _identityMode,
        address _verifier,
        address _evaluationStrategy,
        string calldata _configIpfsHash,
        uint256 _biddingTime,
        uint256 _revealTime,
        uint256 _challengePeriod,
        uint256 _bidBondAmount
    ) external returns (address) {
        // Tender is NOT upgradeable. The Factory is.
        // We deploy immutable tenders.
        Tender tender = new Tender(
            _identityMode,
            msg.sender,
            _verifier,
            _evaluationStrategy,
            _configIpfsHash,
            _biddingTime,
            _revealTime,
            _challengePeriod,
            _bidBondAmount
        );
        emit TenderContractDeployed(address(tender), msg.sender);
        return address(tender);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
