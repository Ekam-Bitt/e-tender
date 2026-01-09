// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { CCIPBidReceiver } from "src/crosschain/CrossChainAdapter.sol";

/**
 * @title DeployCCIP
 * @notice Deployment script for cross-chain CCIP infrastructure
 *
 * Deployment Order:
 * 1. Deploy CCIPBidReceiver on destination chain (Sepolia)
 * 2. Deploy CCIPBidSender on source chain (Fuji) - uses same contract
 * 3. Configure permissions
 *
 * Usage:
 *   # Deploy receiver on Sepolia
 *   forge script script/DeployCCIP.s.sol:DeployCCIPReceiver --rpc-url $SEPOLIA_RPC --broadcast
 *
 *   # Deploy sender on Fuji
 *   forge script script/DeployCCIP.s.sol:DeployCCIPSender --rpc-url $FUJI_RPC --broadcast
 */

/// @notice CCIP Router addresses per chain
library CCIPRouters {
    // Sepolia (Ethereum testnet)
    address constant SEPOLIA = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    uint64 constant SEPOLIA_SELECTOR = 16015286601757825753;

    // Fuji (Avalanche testnet)
    address constant FUJI = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    uint64 constant FUJI_SELECTOR = 14767482510784806043;
}

/// @notice Deploy CCIPBidReceiver on Sepolia (destination chain)
contract DeployCCIPReceiver is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ETH");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying CCIPBidReceiver on Sepolia");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy CCIPBidReceiver
        CCIPBidReceiver receiver = new CCIPBidReceiver(CCIPRouters.SEPOLIA);
        console.log("CCIPBidReceiver deployed at:", address(receiver));

        // 2. Allow Fuji as source chain
        receiver.allowSourceChain(CCIPRouters.FUJI_SELECTOR, true);
        console.log("Allowed source chain: Fuji");

        // 3. Set bid bond amount (1 ETH for testing)
        receiver.setBidBondAmount(0.01 ether);
        console.log("Bid bond set to 0.01 ETH");

        vm.stopBroadcast();

        console.log("\n=== Sepolia Deployment Complete ===");
        console.log("CCIPBidReceiver:", address(receiver));
        console.log("\nNext Steps:");
        console.log("1. Deploy sender on Fuji");
        console.log("2. Call receiver.allowSender(FUJI_SELECTOR, senderAddress, true)");
        console.log("3. Call receiver.setTender(tenderAddress)");
        console.log("4. Fund receiver with ETH for bid bonds");
    }
}

/// @notice Deploy CCIPBidSender on Fuji (source chain)
contract DeployCCIPSender is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_AVAX");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying CCIPBidSender on Fuji");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy CCIPBidReceiver (same contract, used as sender)
        CCIPBidReceiver sender = new CCIPBidReceiver(CCIPRouters.FUJI);
        console.log("CCIPBidSender deployed at:", address(sender));

        vm.stopBroadcast();

        console.log("\n=== Fuji Deployment Complete ===");
        console.log("CCIPBidSender:", address(sender));
        console.log("\nNext Steps:");
        console.log("1. On Sepolia receiver, call: allowSender(FUJI_SELECTOR, senderAddress, true)");
        console.log("2. Users can now call sender.sendBid() to submit cross-chain bids");
    }
}

/// @notice Configure existing deployments
contract ConfigureCCIP is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get addresses from environment
        address receiverAddr = vm.envAddress("CCIP_RECEIVER");
        address senderAddr = vm.envAddress("CCIP_SENDER");
        address tenderAddr = vm.envAddress("TENDER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        CCIPBidReceiver receiver = CCIPBidReceiver(payable(receiverAddr));

        // Allow the sender
        receiver.allowSender(CCIPRouters.FUJI_SELECTOR, senderAddr, true);
        console.log("Allowed sender:", senderAddr);

        // Set the tender
        receiver.setTender(tenderAddr);
        console.log("Set tender:", tenderAddr);

        vm.stopBroadcast();

        console.log("\n=== Configuration Complete ===");
    }
}
