// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TenderConstants {
    bytes32 internal constant BID_TYPEHASH = keccak256("Bid(uint256 amount,bytes32 salt,bytes32 metadataHash)");
}
