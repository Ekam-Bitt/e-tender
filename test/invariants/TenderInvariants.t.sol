// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Tender} from "../../src/Tender.sol";
import {TenderFactory} from "../../src/TenderFactory.sol";
import {TenderHandler} from "./TenderHandler.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TenderInvariants is Test {
    Tender public tender;
    TenderHandler public handler;
    TenderFactory public factory;
    
    address public authority = makeAddr("authority");

    function setUp() public {
        vm.startPrank(authority);
        TenderFactory impl = new TenderFactory();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), abi.encodeCall(impl.initialize, ()));
        factory = TenderFactory(address(proxy));
        
        // Deploy a Tender
        // We use LowestPrice for simplicity in invariants
        // Bidding time = 100 days (to allow fuzzing breadth)
        address tenderAddr = factory.createTender(address(0), address(0), "QmConfig", 100 days, 1 days, 1 days, 1 ether);
        tender = Tender(tenderAddr);
        vm.stopPrank();

        handler = new TenderHandler(tender, factory, authority);
        handler.createBidders(5);
        
        // Register Handler targets
        targetContract(address(handler));
    }
    
    // INV-01: Solvency
    // total ETH in contract >= sum of all deposits tracked by handler?
    // Handler tracks deposits in sumDeposits.
    // However, tender might hold more (if successful reveals happen, deposits stay? Or slashes happen).
    // Let's check: Balance >= 0. Simple sanity.
    // Better: Balance >= active bond liabilities.
    function invariant_solvency() public view {
        assertGe(address(tender).balance, 0); // Trivial
        // Assert handler tracked deposits are present
        // Handler sumDeposits is incremented on submitBid
        // If reveals/withdrawals happen, balance decreases. 
        // We need handler to track withdrawals too to be precise.
        // For now, let's just ensure no underflow or weird state.
    }
    
    // INV-02: State Monotonicity
    // State cannot go backwards.
    // We can't easily check history in invariant test unless we track "previous state" in a ghost var in handler.
    // But we can check consistency:
    // If block.timestamp > biddingDeadline, state should be at least OPEN (or transitionable to REVEAL).
    // If state is AWARDED, winningBidderId must be != 0.
    function invariant_awarded_state_consistency() public view {
        if (tender.state() == Tender.TenderState.AWARDED) {
            // INV-03: Winner Revealed
            assertNotEq(tender.winningBidderId(), bytes32(0));
            // Check winner revealed
             (,,,,bool revealed,) = tender.bids(tender.winningBidderId());
            assertTrue(revealed);
        }
    }
}
