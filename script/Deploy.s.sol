// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { TenderFactory } from "src/core/TenderFactory.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Halo2Verifier } from "src/crypto/Halo2Verifier.sol";
import { ZKRangeVerifier } from "src/crypto/ZKRangeVerifier.sol";
import { ZKAuctionStrategy } from "src/strategies/ZKAuctionStrategy.sol";
import { LowestPriceStrategy } from "src/strategies/LowestPriceStrategy.sol";
import { WeightedScoreStrategy } from "src/strategies/WeightedScoreStrategy.sol";

contract DeployScript is Script {
    function setUp() public { }

    function run() public {
        // Retrieve deployment key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with the account:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy TenderFactory Implementation
        TenderFactory implementation = new TenderFactory();
        console.log("TenderFactory Implementation deployed at:", address(implementation));

        // 2. Deploy ERC1967 Proxy pointing to Implementation
        // Encoded initialization call: initializer()
        bytes memory initData = abi.encodeCall(TenderFactory.initialize, ());

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("TenderFactory Proxy deployed at:", address(proxy));

        // 3. Deploy ZK Infrastructure (Production Halo2-based)
        Halo2Verifier halo2Verifier = new Halo2Verifier();
        console.log("Halo2Verifier deployed at:", address(halo2Verifier));

        ZKRangeVerifier rangeVerifier = new ZKRangeVerifier(address(halo2Verifier));
        console.log("ZKRangeVerifier deployed at:", address(rangeVerifier));

        // 4. Deploy Evaluation Strategies
        // ZKAuctionStrategy - ZK-based bid validation with range proofs
        ZKAuctionStrategy zkStrategy = new ZKAuctionStrategy(1 ether, 100 ether, address(rangeVerifier));
        console.log("ZKAuctionStrategy deployed at:", address(zkStrategy));

        // LowestPriceStrategy - Simple lowest price wins
        LowestPriceStrategy lowestPriceStrategy = new LowestPriceStrategy();
        console.log("LowestPriceStrategy deployed at:", address(lowestPriceStrategy));

        // WeightedScoreStrategy - Multi-criteria evaluation
        // Weights: Price=1, DeliveryTime=2, Compliance=5
        WeightedScoreStrategy weightedStrategy = new WeightedScoreStrategy(1, 2, 5);
        console.log("WeightedScoreStrategy deployed at:", address(weightedStrategy));

        vm.stopBroadcast();

        // Verification helper logs
        console.log("--- Deployment Complete ---");
        console.log("Factory Proxy:", address(proxy));
        console.log("--- Available Strategies ---");
        console.log("  ZKAuctionStrategy (ZK + range proofs):", address(zkStrategy));
        console.log("  LowestPriceStrategy (simple):", address(lowestPriceStrategy));
        console.log("  WeightedScoreStrategy (multi-criteria):", address(weightedStrategy));
    }
}
