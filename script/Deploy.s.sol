// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TenderFactory} from "../contracts/TenderFactory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ZKRangeVerifier} from "../contracts/crypto/ZKRangeVerifier.sol";
import {ZKAuctionStrategy} from "../contracts/strategies/ZKAuctionStrategy.sol";

contract DeployScript is Script {
    function setUp() public {}

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
        
        // 3. Deploy ZK Infrastructure (Mock) - Optional for demo
        ZKRangeVerifier rangeVerifier = new ZKRangeVerifier();
        console.log("ZKRangeVerifier deployed at:", address(rangeVerifier));
        
        ZKAuctionStrategy zkStrategy = new ZKAuctionStrategy(address(rangeVerifier), 1 ether, 100 ether);
        console.log("ZKAuctionStrategy deployed at:", address(zkStrategy));

        vm.stopBroadcast();
        
        // Verification helper logs
        console.log("--- Deployment Complete ---");
        console.log("Factory Proxy:", address(proxy));
        console.log("ZK Strategy:", address(zkStrategy));
    }
}
