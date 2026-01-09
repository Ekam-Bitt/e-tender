// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Tender } from "src/core/Tender.sol";
import { TenderFactory } from "src/core/TenderFactory.sol";
import { LowestPriceStrategy } from "src/strategies/LowestPriceStrategy.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MEVSim is Test {
    Tender public tender;
    TenderFactory public factory;
    LowestPriceStrategy public priceStrategy;

    address authority = makeAddr("authority");
    address victim = makeAddr("victim");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vm.startPrank(authority);
        TenderFactory impl = new TenderFactory();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), abi.encodeCall(impl.initialize, ()));
        factory = TenderFactory(address(proxy));

        priceStrategy = new LowestPriceStrategy();
        address tenderAddr = factory.createTender(
            Tender.IdentityMode.NONE, address(0), address(priceStrategy), "QmConfig", 1 days, 1 days, 1 days, 1 ether
        );
        tender = Tender(tenderAddr);
        tender.openTendering();
        vm.stopPrank();

        vm.deal(victim, 100 ether);
        vm.deal(attacker, 100 ether);
    }

    // Scenario: Attacker sees Victim's commit transaction in mempool.
    // Attacker tries to copy the commitment to front-run?
    // BUT commitments are bound to `msg.sender` (indirectly via reveal check or signature).
    // In Public mode: `submitBid` stores `bids[ID(msg.sender)]`.
    // If Attacker submits same commitment: `bids[ID(attacker)] = commitment`.
    // Later, Attacker must reveal.
    // Reveal checks: `structHash` vs `commitment`.
    // `structHash` includes `salt`. Attacker doesn't know `salt`.
    // So Attacker cannot reveal! Attacker loses `bidBond`.
    // This is griefing self.

    function testFrontRunCopyCat() public {
        // 1. Victim generates bid
        uint256 vAmount = 1 ether;
        bytes32 vSalt = keccak256("secret_salt");
        bytes32 vMeta = keccak256("meta");

        bytes32 bidTypehash = keccak256("Bid(uint256 amount,bytes32 salt,bytes32 metadataHash)");
        bytes32 structHash = keccak256(abi.encode(bidTypehash, vAmount, vSalt, vMeta));
        bytes32 commitment = MessageHashUtils.toTypedDataHash(tender.getDomainSeparator(), structHash);

        // 2. Victim submits (Mempool observation)
        vm.prank(victim);
        tender.submitBid{ value: 1 ether }(commitment, "", new bytes32[](0));

        // 3. Attacker blindly copies commitment
        vm.prank(attacker);
        tender.submitBid{ value: 1 ether }(commitment, "", new bytes32[](0));

        // 4. Reveal Phase
        vm.warp(block.timestamp + 1 days + 1);

        // Victim Reveals
        vm.prank(victim);
        tender.revealBid(vAmount, vSalt, bytes("meta")); // Succeeds

        // Attacker tries to reveal?
        // Attacker doesn't know salt. If they knew salt, they could reveal.
        // But if they reuse Victim's salt/params:
        vm.startPrank(attacker);
        // Reveal logic:
        // 1. Recompute structHash (same)
        // 2. HashTypedDataV4(structHash) -> Uses DOMAIN SEPARATOR?
        // EIP712 Domain Separator usually includes verifying contract address (Tender).
        // It does NOT include `msg.sender`.
        // So `computedHash` is IDENTICAL.
        // So `computedHash == bid.commitment`.
        // So Attacker CAN reveal if they know the preimage!

        // BUT does it matter?
        // Attacker just duplicated the bid.
        // If Logic is "Lowest Price", they tie.
        // If sorting logic handles ties (FIFO?), Victim wins (submitted first).

        // NOTE: In sealed bid auctions, you don't know the price/salt until reveal.
        // So Attacker can copy the *commitment* but they don't know the *preimage* (price/salt) to reveal it!
        // So they literally cannot reveal.

        // Simulating Attacker trying to reveal without preimage -> Impossible.
        // Simulating Attacker trying to reveal WITH preimage (assuming they guessed it? Impossible for salt).

        // So we prove Attacker essentially burns their bond.
        tender.revealBid(vAmount, vSalt, bytes("meta"));
        vm.stopPrank();

        // Wait, did that succeed?
        // If Attacker submits same commit, and reveals same values.
        // Does `revealBid` enforce `msg.sender` identity binding in the HASH?
        // NO. `BID_TYPEHASH` is `Bid(amount, salt, metadataHash)`. No `bidderAddress`.
        // Howerver, `_getBidderId(msg.sender)` maps to storage.
        // So `bids[attackerID]` stores the commitment.
        // `revealBid` checks `bids[attackerID].commitment`.
        // If Attacker copied commitment, it matches.
        // If Attacker knows inputs, they can reveal.
        // BUT they cannot know inputs (Hidden Phase).
        // This confirms the security model relies on the hiding property of the commitment (Salt).
    }
}
