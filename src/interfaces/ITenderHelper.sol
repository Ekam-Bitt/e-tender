// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITenderHelper {
    function getDomainSeparator() external view returns (bytes32);
}
