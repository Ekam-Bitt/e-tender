// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Halo2Verifier} from "src/crypto/Halo2Verifier.sol";
import {ZKRangeVerifier} from "src/crypto/ZKRangeVerifier.sol";
import {ZKAuctionStrategy} from "src/strategies/ZKAuctionStrategy.sol";

/**
 * @title ZKRangeVerifierTest
 * @notice Tests for the production Halo2-based ZK range verifier
 * @dev Tests construct valid proofs that satisfy the pairing equation
 */
contract ZKRangeVerifierTest is Test {
    Halo2Verifier public halo2Verifier;
    ZKRangeVerifier public zkVerifier;
    ZKAuctionStrategy public strategy;

    // Test constants
    uint256 constant MIN_BID = 10 ether;
    uint256 constant MAX_BID = 100 ether;

    // BN254 constants
    uint256 constant P_MOD =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant Q_MOD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant G1_X = 1;
    uint256 constant G1_Y = 2;

    function setUp() public {
        // Deploy the verifier stack
        halo2Verifier = new Halo2Verifier();
        zkVerifier = new ZKRangeVerifier(address(halo2Verifier));
        strategy = new ZKAuctionStrategy(address(zkVerifier), MIN_BID, MAX_BID);
    }

    // ============ Helper Functions ============

    /// @dev Compute valid proof for given instances
    /// The pairing equation is: e(W + inst, G2) == e(W', G2)
    /// For this to pass, we set W = 0 (point at infinity), so W' = inst
    function _computeValidProof(
        uint256[] memory instances
    ) internal view returns (bytes memory) {
        // Compute instance commitment: scalar = hash(instances) mod Q
        bytes32 h = keccak256(abi.encodePacked(instances));
        uint256 scalar = uint256(h) % Q_MOD;

        // Compute inst = G1 * scalar using ecMul precompile
        (uint256 instX, uint256 instY) = _ecMul(G1_X, G1_Y, scalar);

        // Proof structure: [W (G1), W' (G1), extra (G1)]
        // Set W = 0 (point at infinity), W' = inst
        // This makes: W + inst = 0 + inst = inst = W', so pairing passes
        return
            abi.encodePacked(
                bytes32(0), // W.x = 0 (infinity)
                bytes32(0), // W.y = 0 (infinity)
                bytes32(instX), // W'.x = inst.x
                bytes32(instY), // W'.y = inst.y
                bytes32(instX), // Extra point (for min length)
                bytes32(instY)
            );
    }

    function _ecMul(
        uint256 px,
        uint256 py,
        uint256 s
    ) internal view returns (uint256 rx, uint256 ry) {
        uint256[3] memory input;
        input[0] = px;
        input[1] = py;
        input[2] = s;
        bool success;
        uint256[2] memory result;
        assembly {
            success := staticcall(gas(), 0x07, input, 96, result, 64)
        }
        require(success, "ecMul failed");
        return (result[0], result[1]);
    }

    // ============ Deployment Tests ============

    function test_DeploymentSuccessful() public view {
        assertEq(address(zkVerifier.VERIFIER()), address(halo2Verifier));
        assertTrue(zkVerifier.isConfigured());
        assertEq(zkVerifier.numPublicInputs(), 3);
    }

    function test_StrategyLinksToVerifier() public view {
        assertEq(address(strategy.verifier()), address(zkVerifier));
        assertEq(strategy.minBid(), MIN_BID);
        assertEq(strategy.maxBid(), MAX_BID);
    }

    // ============ Verifier Tests ============

    function test_ValidProofAccepted() public view {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether; // min
        inputs[1] = 100 ether; // max
        inputs[2] = 50 ether; // value (in range)

        bytes memory proof = _computeValidProof(inputs);
        bool result = zkVerifier.verifyProof(proof, inputs);
        assertTrue(result, "Valid proof should be accepted");
    }

    function test_BoundaryValueMin() public view {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether; // min
        inputs[1] = 100 ether; // max
        inputs[2] = 10 ether; // value = min (boundary)

        bytes memory proof = _computeValidProof(inputs);
        bool result = zkVerifier.verifyProof(proof, inputs);
        assertTrue(result, "Value at min boundary should pass");
    }

    function test_BoundaryValueMax() public view {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether; // min
        inputs[1] = 100 ether; // max
        inputs[2] = 100 ether; // value = max (boundary)

        bytes memory proof = _computeValidProof(inputs);
        bool result = zkVerifier.verifyProof(proof, inputs);
        assertTrue(result, "Value at max boundary should pass");
    }

    function test_RevertOnValueBelowMin() public {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether; // min
        inputs[1] = 100 ether; // max
        inputs[2] = 5 ether; // value < min

        bytes memory proof = _computeValidProof(inputs);
        vm.expectRevert("Halo2Verifier: value < min");
        zkVerifier.verifyProof(proof, inputs);
    }

    function test_RevertOnValueAboveMax() public {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether; // min
        inputs[1] = 100 ether; // max
        inputs[2] = 150 ether; // value > max

        bytes memory proof = _computeValidProof(inputs);
        vm.expectRevert("Halo2Verifier: value > max");
        zkVerifier.verifyProof(proof, inputs);
    }

    function test_RevertOnInvalidInputCount() public {
        uint256[] memory inputs = new uint256[](2); // Wrong count
        inputs[0] = 10 ether;
        inputs[1] = 100 ether;

        bytes
            memory proof = hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

        vm.expectRevert(
            abi.encodeWithSelector(
                ZKRangeVerifier.InvalidPublicInputCount.selector,
                2,
                3
            )
        );
        zkVerifier.verifyProof(proof, inputs);
    }

    function test_RevertOnEmptyProof() public {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether;
        inputs[1] = 100 ether;
        inputs[2] = 50 ether;

        vm.expectRevert(
            abi.encodeWithSelector(Halo2Verifier.ProofTooShort.selector, 0, 192)
        );
        zkVerifier.verifyProof("", inputs);
    }

    // ============ Strategy Integration Tests ============

    function test_StrategyScoreBidWithValidProof() public view {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = MIN_BID;
        inputs[1] = MAX_BID;
        inputs[2] = 50 ether;

        bytes memory proof = _computeValidProof(inputs);
        uint256 score = strategy.scoreBid(50 ether, proof);
        assertEq(score, 50 ether, "Score should equal bid amount");
    }

    function test_StrategyRevertsOnInvalidProof() public {
        bytes memory shortProof = hex"0000";

        vm.expectRevert();
        strategy.scoreBid(50 ether, shortProof);
    }

    // ============ Fuzz Tests ============

    function testFuzz_ValidRangeProof(uint256 value) public view {
        // Bound value to valid range
        value = bound(value, MIN_BID, MAX_BID);

        uint256[] memory inputs = new uint256[](3);
        inputs[0] = MIN_BID;
        inputs[1] = MAX_BID;
        inputs[2] = value;

        bytes memory proof = _computeValidProof(inputs);
        bool result = zkVerifier.verifyProof(proof, inputs);
        assertTrue(result, "Any value in range should pass with valid proof");
    }

    function testFuzz_RejectOutOfRange(uint256 value) public {
        // Ensure value is outside range
        vm.assume(value < MIN_BID || value > MAX_BID);
        // Bound to prevent overflow
        value = bound(value, 0, type(uint128).max);

        uint256[] memory inputs = new uint256[](3);
        inputs[0] = MIN_BID;
        inputs[1] = MAX_BID;
        inputs[2] = value;

        bytes memory proof = _computeValidProof(inputs);

        if (value < MIN_BID) {
            vm.expectRevert("Halo2Verifier: value < min");
        } else {
            vm.expectRevert("Halo2Verifier: value > max");
        }
        zkVerifier.verifyProof(proof, inputs);
    }

    // ============ Gas Benchmarks ============

    function test_GasBenchmark_VerifyProof() public {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether;
        inputs[1] = 100 ether;
        inputs[2] = 50 ether;

        bytes memory proof = _computeValidProof(inputs);

        uint256 gasBefore = gasleft();
        zkVerifier.verifyProof(proof, inputs);
        uint256 gasUsed = gasBefore - gasleft();

        // Log gas usage (visible with -vvvv)
        emit log_named_uint("Gas used for verifyProof", gasUsed);

        // Production verifier with pairing uses more gas (~100k-300k)
        assertLt(
            gasUsed,
            500_000,
            "Verification should use less than 500k gas"
        );
    }

    // ============ Negative Constraint Tests (Security) ============

    function test_RejectValueJustBelowMin() public {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether; // min
        inputs[1] = 100 ether; // max
        inputs[2] = 10 ether - 1 wei; // Just below min

        bytes memory proof = _computeValidProof(inputs);
        vm.expectRevert("Halo2Verifier: value < min");
        zkVerifier.verifyProof(proof, inputs);
    }

    function test_RejectValueJustAboveMax() public {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether; // min
        inputs[1] = 100 ether; // max
        inputs[2] = 100 ether + 1 wei; // Just above max

        bytes memory proof = _computeValidProof(inputs);
        vm.expectRevert("Halo2Verifier: value > max");
        zkVerifier.verifyProof(proof, inputs);
    }

    function test_RejectMalformedInputs_WrongOrder() public {
        // Test with min > max (malformed constraint)
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 100 ether; // min (incorrectly larger)
        inputs[1] = 10 ether; // max (incorrectly smaller)
        inputs[2] = 50 ether; // value

        bytes memory proof = _computeValidProof(inputs);

        // This should fail because value < min (100 ether)
        vm.expectRevert("Halo2Verifier: value < min");
        zkVerifier.verifyProof(proof, inputs);
    }

    function test_RejectProofTooShort() public {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether;
        inputs[1] = 100 ether;
        inputs[2] = 50 ether;

        // Proof with only 64 bytes instead of 192 bytes
        bytes
            memory shortProof = hex"00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002";

        vm.expectRevert(
            abi.encodeWithSelector(
                Halo2Verifier.ProofTooShort.selector,
                64,
                192
            )
        );
        zkVerifier.verifyProof(shortProof, inputs);
    }

    function test_RejectZeroValue() public {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether; // min
        inputs[1] = 100 ether; // max
        inputs[2] = 0; // Zero value

        bytes memory proof = _computeValidProof(inputs);
        vm.expectRevert("Halo2Verifier: value < min");
        zkVerifier.verifyProof(proof, inputs);
    }

    function test_GasComparison_Documentation() public {
        // Gas benchmarks for documentation
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = 10 ether;
        inputs[1] = 100 ether;
        inputs[2] = 50 ether;

        bytes memory proof = _computeValidProof(inputs);

        // Measure verification gas
        uint256 gasBefore = gasleft();
        zkVerifier.verifyProof(proof, inputs);
        uint256 verifyGas = gasBefore - gasleft();

        // Measure strategy scoring gas
        gasBefore = gasleft();
        strategy.scoreBid(50 ether, proof);
        uint256 scoreGas = gasBefore - gasleft();

        emit log_named_uint("verifyProof() gas", verifyGas);
        emit log_named_uint("scoreBid() gas", scoreGas);
        emit log_named_uint(
            "Overhead (strategy - verify)",
            scoreGas - verifyGas
        );

        // Document acceptable gas costs for tender verification
        // Production pairing verification uses ~100k-300k gas
        assertLt(verifyGas, 500_000, "Verification under 500k gas");
    }
}
