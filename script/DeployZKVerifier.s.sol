// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { Halo2Verifier } from "src/crypto/Halo2Verifier.sol";
import { ZKRangeVerifier } from "src/crypto/ZKRangeVerifier.sol";
import { ZKAuctionStrategy } from "src/strategies/ZKAuctionStrategy.sol";

/**
 * @title DeployZKVerifier
 * @notice Deployment script for the production ZK Range Verifier system
 *
 * Usage:
 *   forge script script/DeployZKVerifier.s.sol --rpc-url $RPC_URL --broadcast
 */
contract DeployZKVerifierScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Configuration
        uint256 minBid = 1 ether; // Minimum bid: 1 ETH
        uint256 maxBid = 100 ether; // Maximum bid: 100 ETH

        // SECURITY: Prevent accidental mainnet deployment
        // Remove this guard only after full security audit and mainnet preparation
        require(block.chainid != 1, "Mainnet deployment not supported - remove this guard after audit");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the Halo2 verifier (crypto layer)
        Halo2Verifier halo2Verifier = new Halo2Verifier();
        console.log("Halo2Verifier deployed at:", address(halo2Verifier));

        // 2. Deploy the adapter (maintains backward compatibility)
        ZKRangeVerifier zkRangeVerifier = new ZKRangeVerifier(address(halo2Verifier));
        console.log("ZKRangeVerifier deployed at:", address(zkRangeVerifier));

        // 3. Deploy the auction strategy using the verifier
        ZKAuctionStrategy zkStrategy = new ZKAuctionStrategy(1 ether, 100 ether, address(zkRangeVerifier));
        console.log("ZKAuctionStrategy deployed at:", address(zkStrategy));

        vm.stopBroadcast();

        // Output deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Network:", block.chainid);
        console.log("Min Bid:", minBid / 1 ether, "ETH");
        console.log("Max Bid:", maxBid / 1 ether, "ETH");
    }
}
