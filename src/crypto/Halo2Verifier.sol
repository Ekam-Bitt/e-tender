// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract Halo2Verifier {
    fallback(bytes calldata) external returns (bytes memory) {
        assembly ("memory-safe") {
            // Enforce that Solidity memory layout is respected
            let data := mload(0x40)
            if iszero(eq(data, 0x80)) {
                revert(0, 0)
            }

            let success := true
            let f_p := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            let f_q := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
            function validate_ec_point(x, y) -> valid {
                {
                    let x_lt_p := lt(x, 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
                    let y_lt_p := lt(y, 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
                    valid := and(x_lt_p, y_lt_p)
                }
                {
                    let y_square := mulmod(y, y, 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
                    let x_square := mulmod(x, x, 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
                    let x_cube :=
                        mulmod(x_square, x, 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
                    let x_cube_plus_3 :=
                        addmod(x_cube, 3, 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
                    let is_affine := eq(x_cube_plus_3, y_square)
                    valid := and(valid, is_affine)
                }
            }
            mstore(0xa0, mod(calldataload(0x0), f_q))
            mstore(0xc0, mod(calldataload(0x20), f_q))
            mstore(0xe0, mod(calldataload(0x40), f_q))
            mstore(0x80, 12419127026517353980567135258053506030421562250653549370889115541358769389605)

            {
                let x := calldataload(0x60)
                mstore(0x100, x)
                let y := calldataload(0x80)
                mstore(0x120, y)
                success := and(validate_ec_point(x, y), success)
            }

            {
                let x := calldataload(0xa0)
                mstore(0x140, x)
                let y := calldataload(0xc0)
                mstore(0x160, y)
                success := and(validate_ec_point(x, y), success)
            }

            {
                let x := calldataload(0xe0)
                mstore(0x180, x)
                let y := calldataload(0x100)
                mstore(0x1a0, y)
                success := and(validate_ec_point(x, y), success)
            }
            mstore(0x1c0, keccak256(0x80, 320))
            {
                let hash := mload(0x1c0)
                mstore(0x1e0, mod(hash, f_q))
                mstore(0x200, hash)
            }
            mstore8(544, 1)
            mstore(0x220, keccak256(0x200, 33))
            {
                let hash := mload(0x220)
                mstore(0x240, mod(hash, f_q))
                mstore(0x260, hash)
            }
            mstore8(640, 1)
            mstore(0x280, keccak256(0x260, 33))
            {
                let hash := mload(0x280)
                mstore(0x2a0, mod(hash, f_q))
                mstore(0x2c0, hash)
            }

            {
                let x := calldataload(0x120)
                mstore(0x2e0, x)
                let y := calldataload(0x140)
                mstore(0x300, y)
                success := and(validate_ec_point(x, y), success)
            }

            {
                let x := calldataload(0x160)
                mstore(0x320, x)
                let y := calldataload(0x180)
                mstore(0x340, y)
                success := and(validate_ec_point(x, y), success)
            }

            {
                let x := calldataload(0x1a0)
                mstore(0x360, x)
                let y := calldataload(0x1c0)
                mstore(0x380, y)
                success := and(validate_ec_point(x, y), success)
            }

            {
                let x := calldataload(0x1e0)
                mstore(0x3a0, x)
                let y := calldataload(0x200)
                mstore(0x3c0, y)
                success := and(validate_ec_point(x, y), success)
            }

            {
                let x := calldataload(0x220)
                mstore(0x3e0, x)
                let y := calldataload(0x240)
                mstore(0x400, y)
                success := and(validate_ec_point(x, y), success)
            }

            {
                let x := calldataload(0x260)
                mstore(0x420, x)
                let y := calldataload(0x280)
                mstore(0x440, y)
                success := and(validate_ec_point(x, y), success)
            }
            mstore(0x460, keccak256(0x2c0, 416))
            {
                let hash := mload(0x460)
                mstore(0x480, mod(hash, f_q))
                mstore(0x4a0, hash)
            }

            {
                let x := calldataload(0x2a0)
                mstore(0x4c0, x)
                let y := calldataload(0x2c0)
                mstore(0x4e0, y)
                success := and(validate_ec_point(x, y), success)
            }

            {
                let x := calldataload(0x2e0)
                mstore(0x500, x)
                let y := calldataload(0x300)
                mstore(0x520, y)
                success := and(validate_ec_point(x, y), success)
            }
            mstore(0x540, keccak256(0x4a0, 160))
            {
                let hash := mload(0x540)
                mstore(0x560, mod(hash, f_q))
                mstore(0x580, hash)
            }
            mstore(0x5a0, mod(calldataload(0x320), f_q))
            mstore(0x5c0, mod(calldataload(0x340), f_q))
            mstore(0x5e0, mod(calldataload(0x360), f_q))
            mstore(0x600, mod(calldataload(0x380), f_q))
            mstore(0x620, mod(calldataload(0x3a0), f_q))
            mstore(0x640, mod(calldataload(0x3c0), f_q))
            mstore(0x660, mod(calldataload(0x3e0), f_q))
            mstore(0x680, mod(calldataload(0x400), f_q))
            mstore(0x6a0, mod(calldataload(0x420), f_q))
            mstore(0x6c0, mod(calldataload(0x440), f_q))
            mstore(0x6e0, mod(calldataload(0x460), f_q))
            mstore(0x700, mod(calldataload(0x480), f_q))
            mstore(0x720, mod(calldataload(0x4a0), f_q))
            mstore(0x740, mod(calldataload(0x4c0), f_q))
            mstore(0x760, mod(calldataload(0x4e0), f_q))
            mstore(0x780, mod(calldataload(0x500), f_q))
            mstore(0x7a0, mod(calldataload(0x520), f_q))
            mstore(0x7c0, mod(calldataload(0x540), f_q))
            mstore(0x7e0, mod(calldataload(0x560), f_q))
            mstore(0x800, mod(calldataload(0x580), f_q))
            mstore(0x820, mod(calldataload(0x5a0), f_q))
            mstore(0x840, mod(calldataload(0x5c0), f_q))
            mstore(0x860, mod(calldataload(0x5e0), f_q))
            mstore(0x880, mod(calldataload(0x600), f_q))
            mstore(0x8a0, mod(calldataload(0x620), f_q))
            mstore(0x8c0, keccak256(0x580, 832))
            {
                let hash := mload(0x8c0)
                mstore(0x8e0, mod(hash, f_q))
                mstore(0x900, hash)
            }
            mstore8(2336, 1)
            mstore(0x920, keccak256(0x900, 33))
            {
                let hash := mload(0x920)
                mstore(0x940, mod(hash, f_q))
                mstore(0x960, hash)
            }

            {
                let x := calldataload(0x640)
                mstore(0x980, x)
                let y := calldataload(0x660)
                mstore(0x9a0, y)
                success := and(validate_ec_point(x, y), success)
            }
            mstore(0x9c0, keccak256(0x960, 96))
            {
                let hash := mload(0x9c0)
                mstore(0x9e0, mod(hash, f_q))
                mstore(0xa00, hash)
            }

            {
                let x := calldataload(0x680)
                mstore(0xa20, x)
                let y := calldataload(0x6a0)
                mstore(0xa40, y)
                success := and(validate_ec_point(x, y), success)
            }
            mstore(0xa60, mulmod(mload(0x560), mload(0x560), f_q))
            mstore(0xa80, mulmod(mload(0xa60), mload(0xa60), f_q))
            mstore(0xaa0, mulmod(mload(0xa80), mload(0xa80), f_q))
            mstore(0xac0, mulmod(mload(0xaa0), mload(0xaa0), f_q))
            mstore(0xae0, mulmod(mload(0xac0), mload(0xac0), f_q))
            mstore(0xb00, mulmod(mload(0xae0), mload(0xae0), f_q))
            mstore(0xb20, mulmod(mload(0xb00), mload(0xb00), f_q))
            mstore(0xb40, mulmod(mload(0xb20), mload(0xb20), f_q))
            mstore(
                0xb60,
                addmod(mload(0xb40), 21888242871839275222246405745257275088548364400416034343698204186575808495616, f_q)
            )
            mstore(
                0xb80,
                mulmod(mload(0xb60), 21802741923121153053409505722814863857733722351976909209543133076471996743681, f_q)
            )
            mstore(
                0xba0,
                mulmod(mload(0xb80), 10167250710514084151592399827148084713285735496006016499965216114801401041468, f_q)
            )
            mstore(
                0xbc0,
                addmod(mload(0x560), 11720992161325191070654005918109190375262628904410017843732988071774407454149, f_q)
            )
            mstore(
                0xbe0,
                mulmod(mload(0xb80), 15620430616972136973029697708057142747056669543503469918700292712864029815878, f_q)
            )
            mstore(
                0xc00,
                addmod(mload(0x560), 6267812254867138249216708037200132341491694856912564424997911473711778679739, f_q)
            )
            mstore(
                0xc20,
                mulmod(mload(0xb80), 4658854783519236281304787251426829785380272013053939496434657852755686889074, f_q)
            )
            mstore(
                0xc40,
                addmod(mload(0x560), 17229388088320038940941618493830445303168092387362094847263546333820121606543, f_q)
            )
            mstore(
                0xc60,
                mulmod(mload(0xb80), 11423757818648818765461327411617109120243501240676889555478397529313037714234, f_q)
            )
            mstore(
                0xc80,
                addmod(mload(0x560), 10464485053190456456785078333640165968304863159739144788219806657262770781383, f_q)
            )
            mstore(
                0xca0,
                mulmod(mload(0xb80), 13677048343952077794467995888380402608453928821079198134318291065290235358859, f_q)
            )
            mstore(
                0xcc0,
                addmod(mload(0x560), 8211194527887197427778409856876872480094435579336836209379913121285573136758, f_q)
            )
            mstore(
                0xce0,
                mulmod(mload(0xb80), 14158528901797138466244491986759313854666262535363044392173788062030301470987, f_q)
            )
            mstore(
                0xd00,
                addmod(mload(0x560), 7729713970042136756001913758497961233882101865052989951524416124545507024630, f_q)
            )
            mstore(0xd20, mulmod(mload(0xb80), 1, f_q))
            mstore(
                0xd40,
                addmod(mload(0x560), 21888242871839275222246405745257275088548364400416034343698204186575808495616, f_q)
            )
            mstore(
                0xd60,
                mulmod(mload(0xb80), 7393649265675507591155086225434297871937368251641985215568891852805958167681, f_q)
            )
            mstore(
                0xd80,
                addmod(mload(0x560), 14494593606163767631091319519822977216610996148774049128129312333769850327936, f_q)
            )
            mstore(
                0xda0,
                mulmod(mload(0xb80), 18154240498369470423574571952998640420834620155273666494480695920805672807787, f_q)
            )
            mstore(
                0xdc0,
                addmod(mload(0x560), 3734002373469804798671833792258634667713744245142367849217508265770135687830, f_q)
            )
            {
                let prod := mload(0xbc0)

                prod := mulmod(mload(0xc00), prod, f_q)
                mstore(0xde0, prod)

                prod := mulmod(mload(0xc40), prod, f_q)
                mstore(0xe00, prod)

                prod := mulmod(mload(0xc80), prod, f_q)
                mstore(0xe20, prod)

                prod := mulmod(mload(0xcc0), prod, f_q)
                mstore(0xe40, prod)

                prod := mulmod(mload(0xd00), prod, f_q)
                mstore(0xe60, prod)

                prod := mulmod(mload(0xd40), prod, f_q)
                mstore(0xe80, prod)

                prod := mulmod(mload(0xd80), prod, f_q)
                mstore(0xea0, prod)

                prod := mulmod(mload(0xdc0), prod, f_q)
                mstore(0xec0, prod)

                prod := mulmod(mload(0xb60), prod, f_q)
                mstore(0xee0, prod)
            }
            mstore(0xf20, 32)
            mstore(0xf40, 32)
            mstore(0xf60, 32)
            mstore(0xf80, mload(0xee0))
            mstore(0xfa0, 21888242871839275222246405745257275088548364400416034343698204186575808495615)
            mstore(0xfc0, 21888242871839275222246405745257275088548364400416034343698204186575808495617)
            success := and(eq(staticcall(gas(), 0x5, 0xf20, 0xc0, 0xf00, 0x20), 1), success)
            {
                let inv := mload(0xf00)
                let v
                v := mload(0xb60)
                mstore(2912, mulmod(mload(0xec0), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0xdc0)
                mstore(3520, mulmod(mload(0xea0), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0xd80)
                mstore(3456, mulmod(mload(0xe80), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0xd40)
                mstore(3392, mulmod(mload(0xe60), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0xd00)
                mstore(3328, mulmod(mload(0xe40), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0xcc0)
                mstore(3264, mulmod(mload(0xe20), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0xc80)
                mstore(3200, mulmod(mload(0xe00), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0xc40)
                mstore(3136, mulmod(mload(0xde0), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0xc00)
                mstore(3072, mulmod(mload(0xbc0), inv, f_q))
                inv := mulmod(v, inv, f_q)
                mstore(0xbc0, inv)
            }
            mstore(0xfe0, mulmod(mload(0xba0), mload(0xbc0), f_q))
            mstore(0x1000, mulmod(mload(0xbe0), mload(0xc00), f_q))
            mstore(0x1020, mulmod(mload(0xc20), mload(0xc40), f_q))
            mstore(0x1040, mulmod(mload(0xc60), mload(0xc80), f_q))
            mstore(0x1060, mulmod(mload(0xca0), mload(0xcc0), f_q))
            mstore(0x1080, mulmod(mload(0xce0), mload(0xd00), f_q))
            mstore(0x10a0, mulmod(mload(0xd20), mload(0xd40), f_q))
            mstore(0x10c0, mulmod(mload(0xd60), mload(0xd80), f_q))
            mstore(0x10e0, mulmod(mload(0xda0), mload(0xdc0), f_q))
            {
                let result := mulmod(mload(0x10a0), mload(0xa0), f_q)
                result := addmod(mulmod(mload(0x10c0), mload(0xc0), f_q), result, f_q)
                result := addmod(mulmod(mload(0x10e0), mload(0xe0), f_q), result, f_q)
                mstore(4352, result)
            }
            mstore(0x1120, addmod(mload(0x5e0), sub(f_q, mload(0x5a0)), f_q))
            mstore(0x1140, mulmod(mload(0x1120), mload(0x620), f_q))
            mstore(0x1160, addmod(mload(0x5c0), sub(f_q, mload(0x5e0)), f_q))
            mstore(0x1180, mulmod(mload(0x1160), mload(0x1140), f_q))
            mstore(0x11a0, mulmod(mload(0x480), mload(0x1180), f_q))
            mstore(0x11c0, addmod(1, sub(f_q, mload(0x700)), f_q))
            mstore(0x11e0, mulmod(mload(0x11c0), mload(0x10a0), f_q))
            mstore(0x1200, addmod(mload(0x11a0), mload(0x11e0), f_q))
            mstore(0x1220, mulmod(mload(0x480), mload(0x1200), f_q))
            mstore(0x1240, mulmod(mload(0x880), mload(0x880), f_q))
            mstore(0x1260, addmod(mload(0x1240), sub(f_q, mload(0x880)), f_q))
            mstore(0x1280, mulmod(mload(0x1260), mload(0xfe0), f_q))
            mstore(0x12a0, addmod(mload(0x1220), mload(0x1280), f_q))
            mstore(0x12c0, mulmod(mload(0x480), mload(0x12a0), f_q))
            mstore(0x12e0, addmod(mload(0x760), sub(f_q, mload(0x740)), f_q))
            mstore(0x1300, mulmod(mload(0x12e0), mload(0x10a0), f_q))
            mstore(0x1320, addmod(mload(0x12c0), mload(0x1300), f_q))
            mstore(0x1340, mulmod(mload(0x480), mload(0x1320), f_q))
            mstore(0x1360, addmod(mload(0x7c0), sub(f_q, mload(0x7a0)), f_q))
            mstore(0x1380, mulmod(mload(0x1360), mload(0x10a0), f_q))
            mstore(0x13a0, addmod(mload(0x1340), mload(0x1380), f_q))
            mstore(0x13c0, mulmod(mload(0x480), mload(0x13a0), f_q))
            mstore(0x13e0, addmod(mload(0x820), sub(f_q, mload(0x800)), f_q))
            mstore(0x1400, mulmod(mload(0x13e0), mload(0x10a0), f_q))
            mstore(0x1420, addmod(mload(0x13c0), mload(0x1400), f_q))
            mstore(0x1440, mulmod(mload(0x480), mload(0x1420), f_q))
            mstore(0x1460, addmod(mload(0x880), sub(f_q, mload(0x860)), f_q))
            mstore(0x1480, mulmod(mload(0x1460), mload(0x10a0), f_q))
            mstore(0x14a0, addmod(mload(0x1440), mload(0x1480), f_q))
            mstore(0x14c0, mulmod(mload(0x480), mload(0x14a0), f_q))
            mstore(0x14e0, addmod(1, sub(f_q, mload(0xfe0)), f_q))
            mstore(0x1500, addmod(mload(0x1000), mload(0x1020), f_q))
            mstore(0x1520, addmod(mload(0x1500), mload(0x1040), f_q))
            mstore(0x1540, addmod(mload(0x1520), mload(0x1060), f_q))
            mstore(0x1560, addmod(mload(0x1540), mload(0x1080), f_q))
            mstore(0x1580, addmod(mload(0x14e0), sub(f_q, mload(0x1560)), f_q))
            mstore(0x15a0, mulmod(mload(0x660), mload(0x240), f_q))
            mstore(0x15c0, addmod(mload(0x5a0), mload(0x15a0), f_q))
            mstore(0x15e0, addmod(mload(0x15c0), mload(0x2a0), f_q))
            mstore(0x1600, mulmod(mload(0x15e0), mload(0x720), f_q))
            mstore(0x1620, mulmod(1, mload(0x240), f_q))
            mstore(0x1640, mulmod(mload(0x560), mload(0x1620), f_q))
            mstore(0x1660, addmod(mload(0x5a0), mload(0x1640), f_q))
            mstore(0x1680, addmod(mload(0x1660), mload(0x2a0), f_q))
            mstore(0x16a0, mulmod(mload(0x1680), mload(0x700), f_q))
            mstore(0x16c0, addmod(mload(0x1600), sub(f_q, mload(0x16a0)), f_q))
            mstore(0x16e0, mulmod(mload(0x16c0), mload(0x1580), f_q))
            mstore(0x1700, addmod(mload(0x14c0), mload(0x16e0), f_q))
            mstore(0x1720, mulmod(mload(0x480), mload(0x1700), f_q))
            mstore(0x1740, mulmod(mload(0x680), mload(0x240), f_q))
            mstore(0x1760, addmod(mload(0x5c0), mload(0x1740), f_q))
            mstore(0x1780, addmod(mload(0x1760), mload(0x2a0), f_q))
            mstore(0x17a0, mulmod(mload(0x1780), mload(0x780), f_q))
            mstore(
                0x17c0,
                mulmod(4131629893567559867359510883348571134090853742863529169391034518566172092834, mload(0x240), f_q)
            )
            mstore(0x17e0, mulmod(mload(0x560), mload(0x17c0), f_q))
            mstore(0x1800, addmod(mload(0x5c0), mload(0x17e0), f_q))
            mstore(0x1820, addmod(mload(0x1800), mload(0x2a0), f_q))
            mstore(0x1840, mulmod(mload(0x1820), mload(0x760), f_q))
            mstore(0x1860, addmod(mload(0x17a0), sub(f_q, mload(0x1840)), f_q))
            mstore(0x1880, mulmod(mload(0x1860), mload(0x1580), f_q))
            mstore(0x18a0, addmod(mload(0x1720), mload(0x1880), f_q))
            mstore(0x18c0, mulmod(mload(0x480), mload(0x18a0), f_q))
            mstore(0x18e0, mulmod(mload(0x6a0), mload(0x240), f_q))
            mstore(0x1900, addmod(mload(0x5e0), mload(0x18e0), f_q))
            mstore(0x1920, addmod(mload(0x1900), mload(0x2a0), f_q))
            mstore(0x1940, mulmod(mload(0x1920), mload(0x7e0), f_q))
            mstore(
                0x1960,
                mulmod(8910878055287538404433155982483128285667088683464058436815641868457422632747, mload(0x240), f_q)
            )
            mstore(0x1980, mulmod(mload(0x560), mload(0x1960), f_q))
            mstore(0x19a0, addmod(mload(0x5e0), mload(0x1980), f_q))
            mstore(0x19c0, addmod(mload(0x19a0), mload(0x2a0), f_q))
            mstore(0x19e0, mulmod(mload(0x19c0), mload(0x7c0), f_q))
            mstore(0x1a00, addmod(mload(0x1940), sub(f_q, mload(0x19e0)), f_q))
            mstore(0x1a20, mulmod(mload(0x1a00), mload(0x1580), f_q))
            mstore(0x1a40, addmod(mload(0x18c0), mload(0x1a20), f_q))
            mstore(0x1a60, mulmod(mload(0x480), mload(0x1a40), f_q))
            mstore(0x1a80, mulmod(mload(0x6c0), mload(0x240), f_q))
            mstore(0x1aa0, addmod(mload(0x1100), mload(0x1a80), f_q))
            mstore(0x1ac0, addmod(mload(0x1aa0), mload(0x2a0), f_q))
            mstore(0x1ae0, mulmod(mload(0x1ac0), mload(0x840), f_q))
            mstore(
                0x1b00,
                mulmod(11166246659983828508719468090013646171463329086121580628794302409516816350802, mload(0x240), f_q)
            )
            mstore(0x1b20, mulmod(mload(0x560), mload(0x1b00), f_q))
            mstore(0x1b40, addmod(mload(0x1100), mload(0x1b20), f_q))
            mstore(0x1b60, addmod(mload(0x1b40), mload(0x2a0), f_q))
            mstore(0x1b80, mulmod(mload(0x1b60), mload(0x820), f_q))
            mstore(0x1ba0, addmod(mload(0x1ae0), sub(f_q, mload(0x1b80)), f_q))
            mstore(0x1bc0, mulmod(mload(0x1ba0), mload(0x1580), f_q))
            mstore(0x1be0, addmod(mload(0x1a60), mload(0x1bc0), f_q))
            mstore(0x1c00, mulmod(mload(0x480), mload(0x1be0), f_q))
            mstore(0x1c20, mulmod(mload(0x6e0), mload(0x240), f_q))
            mstore(0x1c40, addmod(mload(0x600), mload(0x1c20), f_q))
            mstore(0x1c60, addmod(mload(0x1c40), mload(0x2a0), f_q))
            mstore(0x1c80, mulmod(mload(0x1c60), mload(0x8a0), f_q))
            mstore(
                0x1ca0,
                mulmod(284840088355319032285349970403338060113257071685626700086398481893096618818, mload(0x240), f_q)
            )
            mstore(0x1cc0, mulmod(mload(0x560), mload(0x1ca0), f_q))
            mstore(0x1ce0, addmod(mload(0x600), mload(0x1cc0), f_q))
            mstore(0x1d00, addmod(mload(0x1ce0), mload(0x2a0), f_q))
            mstore(0x1d20, mulmod(mload(0x1d00), mload(0x880), f_q))
            mstore(0x1d40, addmod(mload(0x1c80), sub(f_q, mload(0x1d20)), f_q))
            mstore(0x1d60, mulmod(mload(0x1d40), mload(0x1580), f_q))
            mstore(0x1d80, addmod(mload(0x1c00), mload(0x1d60), f_q))
            mstore(0x1da0, mulmod(mload(0xb40), mload(0xb40), f_q))
            mstore(0x1dc0, mulmod(1, mload(0xb40), f_q))
            mstore(0x1de0, mulmod(mload(0x1d80), mload(0xb60), f_q))
            mstore(0x1e00, mulmod(mload(0xa60), mload(0x560), f_q))
            mstore(
                0x1e20,
                mulmod(mload(0x560), 10167250710514084151592399827148084713285735496006016499965216114801401041468, f_q)
            )
            mstore(0x1e40, addmod(mload(0x9e0), sub(f_q, mload(0x1e20)), f_q))
            mstore(0x1e60, mulmod(mload(0x560), 1, f_q))
            mstore(0x1e80, addmod(mload(0x9e0), sub(f_q, mload(0x1e60)), f_q))
            mstore(
                0x1ea0,
                mulmod(mload(0x560), 7393649265675507591155086225434297871937368251641985215568891852805958167681, f_q)
            )
            mstore(0x1ec0, addmod(mload(0x9e0), sub(f_q, mload(0x1ea0)), f_q))
            {
                let result := mulmod(mload(0x9e0), 1, f_q)
                result := addmod(
                    mulmod(
                        mload(0x560),
                        21888242871839275222246405745257275088548364400416034343698204186575808495616,
                        f_q
                    ),
                    result,
                    f_q
                )
                mstore(7904, result)
            }
            mstore(0x1f00, mulmod(1, mload(0x1e80), f_q))
            mstore(
                0x1f20,
                mulmod(19947773512621820452528617400732035250381930196271502546864388931832479102347, mload(0xa60), f_q)
            )
            mstore(0x1f40, mulmod(mload(0x1f20), 1, f_q))
            {
                let result := mulmod(mload(0x9e0), mload(0x1f20), f_q)
                result := addmod(mulmod(mload(0x560), sub(f_q, mload(0x1f40)), f_q), result, f_q)
                mstore(8032, result)
            }
            mstore(
                0x1f80,
                mulmod(5307411326235910010982187846655284515126317856134227860176727469937085865696, mload(0xa60), f_q)
            )
            mstore(
                0x1fa0,
                mulmod(mload(0x1f80), 7393649265675507591155086225434297871937368251641985215568891852805958167681, f_q)
            )
            {
                let result := mulmod(mload(0x9e0), mload(0x1f80), f_q)
                result := addmod(mulmod(mload(0x560), sub(f_q, mload(0x1fa0)), f_q), result, f_q)
                mstore(8128, result)
            }
            mstore(
                0x1fe0,
                mulmod(2868352760655725740670530120331463788036206322158892420596360852137805089611, mload(0xa60), f_q)
            )
            mstore(
                0x2000,
                mulmod(
                    mload(0x1fe0),
                    10167250710514084151592399827148084713285735496006016499965216114801401041468,
                    f_q
                )
            )
            {
                let result := mulmod(mload(0x9e0), mload(0x1fe0), f_q)
                result := addmod(mulmod(mload(0x560), sub(f_q, mload(0x2000)), f_q), result, f_q)
                mstore(8224, result)
            }
            mstore(0x2040, mulmod(mload(0x1f00), mload(0x1ec0), f_q))
            mstore(0x2060, mulmod(mload(0x2040), mload(0x1e40), f_q))
            mstore(
                0x2080,
                mulmod(14494593606163767631091319519822977216610996148774049128129312333769850327937, mload(0x560), f_q)
            )
            mstore(0x20a0, mulmod(mload(0x2080), 1, f_q))
            {
                let result := mulmod(mload(0x9e0), mload(0x2080), f_q)
                result := addmod(mulmod(mload(0x560), sub(f_q, mload(0x20a0)), f_q), result, f_q)
                mstore(8384, result)
            }
            mstore(
                0x20e0,
                mulmod(7393649265675507591155086225434297871937368251641985215568891852805958167680, mload(0x560), f_q)
            )
            mstore(
                0x2100,
                mulmod(mload(0x20e0), 7393649265675507591155086225434297871937368251641985215568891852805958167681, f_q)
            )
            {
                let result := mulmod(mload(0x9e0), mload(0x20e0), f_q)
                result := addmod(mulmod(mload(0x560), sub(f_q, mload(0x2100)), f_q), result, f_q)
                mstore(8480, result)
            }
            {
                let prod := mload(0x1ee0)

                prod := mulmod(mload(0x1f60), prod, f_q)
                mstore(0x2140, prod)

                prod := mulmod(mload(0x1fc0), prod, f_q)
                mstore(0x2160, prod)

                prod := mulmod(mload(0x2020), prod, f_q)
                mstore(0x2180, prod)

                prod := mulmod(mload(0x2060), prod, f_q)
                mstore(0x21a0, prod)

                prod := mulmod(mload(0x20c0), prod, f_q)
                mstore(0x21c0, prod)

                prod := mulmod(mload(0x2120), prod, f_q)
                mstore(0x21e0, prod)

                prod := mulmod(mload(0x2040), prod, f_q)
                mstore(0x2200, prod)
            }
            mstore(0x2240, 32)
            mstore(0x2260, 32)
            mstore(0x2280, 32)
            mstore(0x22a0, mload(0x2200))
            mstore(0x22c0, 21888242871839275222246405745257275088548364400416034343698204186575808495615)
            mstore(0x22e0, 21888242871839275222246405745257275088548364400416034343698204186575808495617)
            success := and(eq(staticcall(gas(), 0x5, 0x2240, 0xc0, 0x2220, 0x20), 1), success)
            {
                let inv := mload(0x2220)
                let v
                v := mload(0x2040)
                mstore(8256, mulmod(mload(0x21e0), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0x2120)
                mstore(8480, mulmod(mload(0x21c0), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0x20c0)
                mstore(8384, mulmod(mload(0x21a0), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0x2060)
                mstore(8288, mulmod(mload(0x2180), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0x2020)
                mstore(8224, mulmod(mload(0x2160), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0x1fc0)
                mstore(8128, mulmod(mload(0x2140), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0x1f60)
                mstore(8032, mulmod(mload(0x1ee0), inv, f_q))
                inv := mulmod(v, inv, f_q)
                mstore(0x1ee0, inv)
            }
            {
                let result := mload(0x1ee0)
                mstore(8960, result)
            }
            mstore(0x2320, mulmod(mload(0x1f00), mload(0x2060), f_q))
            {
                let result := mload(0x1f60)
                result := addmod(mload(0x1fc0), result, f_q)
                result := addmod(mload(0x2020), result, f_q)
                mstore(9024, result)
            }
            mstore(0x2360, mulmod(mload(0x1f00), mload(0x2040), f_q))
            {
                let result := mload(0x20c0)
                result := addmod(mload(0x2120), result, f_q)
                mstore(9088, result)
            }
            {
                let prod := mload(0x2300)

                prod := mulmod(mload(0x2340), prod, f_q)
                mstore(0x23a0, prod)

                prod := mulmod(mload(0x2380), prod, f_q)
                mstore(0x23c0, prod)
            }
            mstore(0x2400, 32)
            mstore(0x2420, 32)
            mstore(0x2440, 32)
            mstore(0x2460, mload(0x23c0))
            mstore(0x2480, 21888242871839275222246405745257275088548364400416034343698204186575808495615)
            mstore(0x24a0, 21888242871839275222246405745257275088548364400416034343698204186575808495617)
            success := and(eq(staticcall(gas(), 0x5, 0x2400, 0xc0, 0x23e0, 0x20), 1), success)
            {
                let inv := mload(0x23e0)
                let v
                v := mload(0x2380)
                mstore(9088, mulmod(mload(0x23a0), inv, f_q))
                inv := mulmod(v, inv, f_q)

                v := mload(0x2340)
                mstore(9024, mulmod(mload(0x2300), inv, f_q))
                inv := mulmod(v, inv, f_q)
                mstore(0x2300, inv)
            }
            mstore(0x24c0, mulmod(mload(0x2320), mload(0x2340), f_q))
            mstore(0x24e0, mulmod(mload(0x2360), mload(0x2380), f_q))
            mstore(0x2500, mulmod(mload(0x8e0), mload(0x8e0), f_q))
            mstore(0x2520, mulmod(mload(0x2500), mload(0x8e0), f_q))
            mstore(0x2540, mulmod(mload(0x2520), mload(0x8e0), f_q))
            mstore(0x2560, mulmod(mload(0x2540), mload(0x8e0), f_q))
            mstore(0x2580, mulmod(mload(0x2560), mload(0x8e0), f_q))
            mstore(0x25a0, mulmod(mload(0x2580), mload(0x8e0), f_q))
            mstore(0x25c0, mulmod(mload(0x25a0), mload(0x8e0), f_q))
            mstore(0x25e0, mulmod(mload(0x25c0), mload(0x8e0), f_q))
            mstore(0x2600, mulmod(mload(0x25e0), mload(0x8e0), f_q))
            mstore(0x2620, mulmod(mload(0x2600), mload(0x8e0), f_q))
            mstore(0x2640, mulmod(mload(0x2620), mload(0x8e0), f_q))
            mstore(0x2660, mulmod(mload(0x940), mload(0x940), f_q))
            mstore(0x2680, mulmod(mload(0x2660), mload(0x940), f_q))
            {
                let result := mulmod(mload(0x5a0), mload(0x1ee0), f_q)
                mstore(9888, result)
            }
            mstore(0x26c0, mulmod(mload(0x26a0), mload(0x2300), f_q))
            mstore(0x26e0, mulmod(sub(f_q, mload(0x26c0)), 1, f_q))
            {
                let result := mulmod(mload(0x5c0), mload(0x1ee0), f_q)
                mstore(9984, result)
            }
            mstore(0x2720, mulmod(mload(0x2700), mload(0x2300), f_q))
            mstore(0x2740, mulmod(sub(f_q, mload(0x2720)), mload(0x8e0), f_q))
            mstore(0x2760, mulmod(1, mload(0x8e0), f_q))
            mstore(0x2780, addmod(mload(0x26e0), mload(0x2740), f_q))
            {
                let result := mulmod(mload(0x5e0), mload(0x1ee0), f_q)
                mstore(10144, result)
            }
            mstore(0x27c0, mulmod(mload(0x27a0), mload(0x2300), f_q))
            mstore(0x27e0, mulmod(sub(f_q, mload(0x27c0)), mload(0x2500), f_q))
            mstore(0x2800, mulmod(1, mload(0x2500), f_q))
            mstore(0x2820, addmod(mload(0x2780), mload(0x27e0), f_q))
            {
                let result := mulmod(mload(0x600), mload(0x1ee0), f_q)
                mstore(10304, result)
            }
            mstore(0x2860, mulmod(mload(0x2840), mload(0x2300), f_q))
            mstore(0x2880, mulmod(sub(f_q, mload(0x2860)), mload(0x2520), f_q))
            mstore(0x28a0, mulmod(1, mload(0x2520), f_q))
            mstore(0x28c0, addmod(mload(0x2820), mload(0x2880), f_q))
            {
                let result := mulmod(mload(0x620), mload(0x1ee0), f_q)
                mstore(10464, result)
            }
            mstore(0x2900, mulmod(mload(0x28e0), mload(0x2300), f_q))
            mstore(0x2920, mulmod(sub(f_q, mload(0x2900)), mload(0x2540), f_q))
            mstore(0x2940, mulmod(1, mload(0x2540), f_q))
            mstore(0x2960, addmod(mload(0x28c0), mload(0x2920), f_q))
            {
                let result := mulmod(mload(0x660), mload(0x1ee0), f_q)
                mstore(10624, result)
            }
            mstore(0x29a0, mulmod(mload(0x2980), mload(0x2300), f_q))
            mstore(0x29c0, mulmod(sub(f_q, mload(0x29a0)), mload(0x2560), f_q))
            mstore(0x29e0, mulmod(1, mload(0x2560), f_q))
            mstore(0x2a00, addmod(mload(0x2960), mload(0x29c0), f_q))
            {
                let result := mulmod(mload(0x680), mload(0x1ee0), f_q)
                mstore(10784, result)
            }
            mstore(0x2a40, mulmod(mload(0x2a20), mload(0x2300), f_q))
            mstore(0x2a60, mulmod(sub(f_q, mload(0x2a40)), mload(0x2580), f_q))
            mstore(0x2a80, mulmod(1, mload(0x2580), f_q))
            mstore(0x2aa0, addmod(mload(0x2a00), mload(0x2a60), f_q))
            {
                let result := mulmod(mload(0x6a0), mload(0x1ee0), f_q)
                mstore(10944, result)
            }
            mstore(0x2ae0, mulmod(mload(0x2ac0), mload(0x2300), f_q))
            mstore(0x2b00, mulmod(sub(f_q, mload(0x2ae0)), mload(0x25a0), f_q))
            mstore(0x2b20, mulmod(1, mload(0x25a0), f_q))
            mstore(0x2b40, addmod(mload(0x2aa0), mload(0x2b00), f_q))
            {
                let result := mulmod(mload(0x6c0), mload(0x1ee0), f_q)
                mstore(11104, result)
            }
            mstore(0x2b80, mulmod(mload(0x2b60), mload(0x2300), f_q))
            mstore(0x2ba0, mulmod(sub(f_q, mload(0x2b80)), mload(0x25c0), f_q))
            mstore(0x2bc0, mulmod(1, mload(0x25c0), f_q))
            mstore(0x2be0, addmod(mload(0x2b40), mload(0x2ba0), f_q))
            {
                let result := mulmod(mload(0x6e0), mload(0x1ee0), f_q)
                mstore(11264, result)
            }
            mstore(0x2c20, mulmod(mload(0x2c00), mload(0x2300), f_q))
            mstore(0x2c40, mulmod(sub(f_q, mload(0x2c20)), mload(0x25e0), f_q))
            mstore(0x2c60, mulmod(1, mload(0x25e0), f_q))
            mstore(0x2c80, addmod(mload(0x2be0), mload(0x2c40), f_q))
            {
                let result := mulmod(mload(0x1de0), mload(0x1ee0), f_q)
                mstore(11424, result)
            }
            mstore(0x2cc0, mulmod(mload(0x2ca0), mload(0x2300), f_q))
            mstore(0x2ce0, mulmod(sub(f_q, mload(0x2cc0)), mload(0x2600), f_q))
            mstore(0x2d00, mulmod(1, mload(0x2600), f_q))
            mstore(0x2d20, mulmod(mload(0x1dc0), mload(0x2600), f_q))
            mstore(0x2d40, addmod(mload(0x2c80), mload(0x2ce0), f_q))
            {
                let result := mulmod(mload(0x640), mload(0x1ee0), f_q)
                mstore(11616, result)
            }
            mstore(0x2d80, mulmod(mload(0x2d60), mload(0x2300), f_q))
            mstore(0x2da0, mulmod(sub(f_q, mload(0x2d80)), mload(0x2620), f_q))
            mstore(0x2dc0, mulmod(1, mload(0x2620), f_q))
            mstore(0x2de0, addmod(mload(0x2d40), mload(0x2da0), f_q))
            mstore(0x2e00, mulmod(mload(0x2de0), 1, f_q))
            mstore(0x2e20, mulmod(mload(0x2760), 1, f_q))
            mstore(0x2e40, mulmod(mload(0x2800), 1, f_q))
            mstore(0x2e60, mulmod(mload(0x28a0), 1, f_q))
            mstore(0x2e80, mulmod(mload(0x2940), 1, f_q))
            mstore(0x2ea0, mulmod(mload(0x29e0), 1, f_q))
            mstore(0x2ec0, mulmod(mload(0x2a80), 1, f_q))
            mstore(0x2ee0, mulmod(mload(0x2b20), 1, f_q))
            mstore(0x2f00, mulmod(mload(0x2bc0), 1, f_q))
            mstore(0x2f20, mulmod(mload(0x2c60), 1, f_q))
            mstore(0x2f40, mulmod(mload(0x2d00), 1, f_q))
            mstore(0x2f60, mulmod(mload(0x2d20), 1, f_q))
            mstore(0x2f80, mulmod(mload(0x2dc0), 1, f_q))
            mstore(0x2fa0, mulmod(1, mload(0x2320), f_q))
            {
                let result := mulmod(mload(0x700), mload(0x1f60), f_q)
                result := addmod(mulmod(mload(0x720), mload(0x1fc0), f_q), result, f_q)
                result := addmod(mulmod(mload(0x740), mload(0x2020), f_q), result, f_q)
                mstore(12224, result)
            }
            mstore(0x2fe0, mulmod(mload(0x2fc0), mload(0x24c0), f_q))
            mstore(0x3000, mulmod(sub(f_q, mload(0x2fe0)), 1, f_q))
            mstore(0x3020, mulmod(mload(0x2fa0), 1, f_q))
            {
                let result := mulmod(mload(0x760), mload(0x1f60), f_q)
                result := addmod(mulmod(mload(0x780), mload(0x1fc0), f_q), result, f_q)
                result := addmod(mulmod(mload(0x7a0), mload(0x2020), f_q), result, f_q)
                mstore(12352, result)
            }
            mstore(0x3060, mulmod(mload(0x3040), mload(0x24c0), f_q))
            mstore(0x3080, mulmod(sub(f_q, mload(0x3060)), mload(0x8e0), f_q))
            mstore(0x30a0, mulmod(mload(0x2fa0), mload(0x8e0), f_q))
            mstore(0x30c0, addmod(mload(0x3000), mload(0x3080), f_q))
            {
                let result := mulmod(mload(0x7c0), mload(0x1f60), f_q)
                result := addmod(mulmod(mload(0x7e0), mload(0x1fc0), f_q), result, f_q)
                result := addmod(mulmod(mload(0x800), mload(0x2020), f_q), result, f_q)
                mstore(12512, result)
            }
            mstore(0x3100, mulmod(mload(0x30e0), mload(0x24c0), f_q))
            mstore(0x3120, mulmod(sub(f_q, mload(0x3100)), mload(0x2500), f_q))
            mstore(0x3140, mulmod(mload(0x2fa0), mload(0x2500), f_q))
            mstore(0x3160, addmod(mload(0x30c0), mload(0x3120), f_q))
            {
                let result := mulmod(mload(0x820), mload(0x1f60), f_q)
                result := addmod(mulmod(mload(0x840), mload(0x1fc0), f_q), result, f_q)
                result := addmod(mulmod(mload(0x860), mload(0x2020), f_q), result, f_q)
                mstore(12672, result)
            }
            mstore(0x31a0, mulmod(mload(0x3180), mload(0x24c0), f_q))
            mstore(0x31c0, mulmod(sub(f_q, mload(0x31a0)), mload(0x2520), f_q))
            mstore(0x31e0, mulmod(mload(0x2fa0), mload(0x2520), f_q))
            mstore(0x3200, addmod(mload(0x3160), mload(0x31c0), f_q))
            mstore(0x3220, mulmod(mload(0x3200), mload(0x940), f_q))
            mstore(0x3240, mulmod(mload(0x3020), mload(0x940), f_q))
            mstore(0x3260, mulmod(mload(0x30a0), mload(0x940), f_q))
            mstore(0x3280, mulmod(mload(0x3140), mload(0x940), f_q))
            mstore(0x32a0, mulmod(mload(0x31e0), mload(0x940), f_q))
            mstore(0x32c0, addmod(mload(0x2e00), mload(0x3220), f_q))
            mstore(0x32e0, mulmod(1, mload(0x2360), f_q))
            {
                let result := mulmod(mload(0x880), mload(0x20c0), f_q)
                result := addmod(mulmod(mload(0x8a0), mload(0x2120), f_q), result, f_q)
                mstore(13056, result)
            }
            mstore(0x3320, mulmod(mload(0x3300), mload(0x24e0), f_q))
            mstore(0x3340, mulmod(sub(f_q, mload(0x3320)), 1, f_q))
            mstore(0x3360, mulmod(mload(0x32e0), 1, f_q))
            mstore(0x3380, mulmod(mload(0x3340), mload(0x2660), f_q))
            mstore(0x33a0, mulmod(mload(0x3360), mload(0x2660), f_q))
            mstore(0x33c0, addmod(mload(0x32c0), mload(0x3380), f_q))
            mstore(0x33e0, mulmod(1, mload(0x1f00), f_q))
            mstore(0x3400, mulmod(1, mload(0x9e0), f_q))
            mstore(0x3420, 0x0000000000000000000000000000000000000000000000000000000000000001)
            mstore(0x3440, 0x0000000000000000000000000000000000000000000000000000000000000002)
            mstore(0x3460, mload(0x33c0))
            success := and(eq(staticcall(gas(), 0x7, 0x3420, 0x60, 0x3420, 0x40), 1), success)
            mstore(0x3480, mload(0x3420))
            mstore(0x34a0, mload(0x3440))
            mstore(0x34c0, mload(0x100))
            mstore(0x34e0, mload(0x120))
            success := and(eq(staticcall(gas(), 0x6, 0x3480, 0x80, 0x3480, 0x40), 1), success)
            mstore(0x3500, mload(0x140))
            mstore(0x3520, mload(0x160))
            mstore(0x3540, mload(0x2e20))
            success := and(eq(staticcall(gas(), 0x7, 0x3500, 0x60, 0x3500, 0x40), 1), success)
            mstore(0x3560, mload(0x3480))
            mstore(0x3580, mload(0x34a0))
            mstore(0x35a0, mload(0x3500))
            mstore(0x35c0, mload(0x3520))
            success := and(eq(staticcall(gas(), 0x6, 0x3560, 0x80, 0x3560, 0x40), 1), success)
            mstore(0x35e0, mload(0x180))
            mstore(0x3600, mload(0x1a0))
            mstore(0x3620, mload(0x2e40))
            success := and(eq(staticcall(gas(), 0x7, 0x35e0, 0x60, 0x35e0, 0x40), 1), success)
            mstore(0x3640, mload(0x3560))
            mstore(0x3660, mload(0x3580))
            mstore(0x3680, mload(0x35e0))
            mstore(0x36a0, mload(0x3600))
            success := and(eq(staticcall(gas(), 0x6, 0x3640, 0x80, 0x3640, 0x40), 1), success)
            mstore(0x36c0, 0x0000000000000000000000000000000000000000000000000000000000000000)
            mstore(0x36e0, 0x0000000000000000000000000000000000000000000000000000000000000000)
            mstore(0x3700, mload(0x2e60))
            success := and(eq(staticcall(gas(), 0x7, 0x36c0, 0x60, 0x36c0, 0x40), 1), success)
            mstore(0x3720, mload(0x3640))
            mstore(0x3740, mload(0x3660))
            mstore(0x3760, mload(0x36c0))
            mstore(0x3780, mload(0x36e0))
            success := and(eq(staticcall(gas(), 0x6, 0x3720, 0x80, 0x3720, 0x40), 1), success)
            mstore(0x37a0, 0x0332fc563560cd76b31441b527385f72e72486b25c98b1a07c81814d4ccc0622)
            mstore(0x37c0, 0x16491916d099bc9d280d31770c80be49335eff1c440b557a4970f96178a028ec)
            mstore(0x37e0, mload(0x2e80))
            success := and(eq(staticcall(gas(), 0x7, 0x37a0, 0x60, 0x37a0, 0x40), 1), success)
            mstore(0x3800, mload(0x3720))
            mstore(0x3820, mload(0x3740))
            mstore(0x3840, mload(0x37a0))
            mstore(0x3860, mload(0x37c0))
            success := and(eq(staticcall(gas(), 0x6, 0x3800, 0x80, 0x3800, 0x40), 1), success)
            mstore(0x3880, 0x133d150fedf6fd7c182eb24ad8ffd4bcca2c3f766e4e0221dea4963da8e9b0c5)
            mstore(0x38a0, 0x0ae4dddeb3d4ee1a96eb3c8d27038c098706e962c5175d4a9ab527225a17ecd3)
            mstore(0x38c0, mload(0x2ea0))
            success := and(eq(staticcall(gas(), 0x7, 0x3880, 0x60, 0x3880, 0x40), 1), success)
            mstore(0x38e0, mload(0x3800))
            mstore(0x3900, mload(0x3820))
            mstore(0x3920, mload(0x3880))
            mstore(0x3940, mload(0x38a0))
            success := and(eq(staticcall(gas(), 0x6, 0x38e0, 0x80, 0x38e0, 0x40), 1), success)
            mstore(0x3960, 0x17759b7662a186a83f350012ee6da2917f1314fa016d20a9ba0e3e99aab79618)
            mstore(0x3980, 0x243bc143144c4d4ee362cc7a5bf21c9cc546dfeee15c327f89a59ba5fce1753e)
            mstore(0x39a0, mload(0x2ec0))
            success := and(eq(staticcall(gas(), 0x7, 0x3960, 0x60, 0x3960, 0x40), 1), success)
            mstore(0x39c0, mload(0x38e0))
            mstore(0x39e0, mload(0x3900))
            mstore(0x3a00, mload(0x3960))
            mstore(0x3a20, mload(0x3980))
            success := and(eq(staticcall(gas(), 0x6, 0x39c0, 0x80, 0x39c0, 0x40), 1), success)
            mstore(0x3a40, 0x2d2e77474b96bf81eb609a4f752505e722dcea870b91114768bac7d4b42de8d0)
            mstore(0x3a60, 0x05d338bcc8bbb3631cfd8aae734a36e09642cf819469278a2ab26cc6ad9d2097)
            mstore(0x3a80, mload(0x2ee0))
            success := and(eq(staticcall(gas(), 0x7, 0x3a40, 0x60, 0x3a40, 0x40), 1), success)
            mstore(0x3aa0, mload(0x39c0))
            mstore(0x3ac0, mload(0x39e0))
            mstore(0x3ae0, mload(0x3a40))
            mstore(0x3b00, mload(0x3a60))
            success := and(eq(staticcall(gas(), 0x6, 0x3aa0, 0x80, 0x3aa0, 0x40), 1), success)
            mstore(0x3b20, 0x19c3e55f55dae2be9d7cf2388d177bf4353a40ecd77ead9eec6420c1373d80c2)
            mstore(0x3b40, 0x230a779783bfdef5965f1588585a804c791485e381ba6399c54ef846c728838b)
            mstore(0x3b60, mload(0x2f00))
            success := and(eq(staticcall(gas(), 0x7, 0x3b20, 0x60, 0x3b20, 0x40), 1), success)
            mstore(0x3b80, mload(0x3aa0))
            mstore(0x3ba0, mload(0x3ac0))
            mstore(0x3bc0, mload(0x3b20))
            mstore(0x3be0, mload(0x3b40))
            success := and(eq(staticcall(gas(), 0x6, 0x3b80, 0x80, 0x3b80, 0x40), 1), success)
            mstore(0x3c00, 0x2074a21f2013b8e9c7221e7c689c0d1098bc35de0d966660bd7e805780ca0058)
            mstore(0x3c20, 0x16f66ada7b9cbbad6a0917d46fc59646ceb70354d96838b69d4ebf8c1d447566)
            mstore(0x3c40, mload(0x2f20))
            success := and(eq(staticcall(gas(), 0x7, 0x3c00, 0x60, 0x3c00, 0x40), 1), success)
            mstore(0x3c60, mload(0x3b80))
            mstore(0x3c80, mload(0x3ba0))
            mstore(0x3ca0, mload(0x3c00))
            mstore(0x3cc0, mload(0x3c20))
            success := and(eq(staticcall(gas(), 0x6, 0x3c60, 0x80, 0x3c60, 0x40), 1), success)
            mstore(0x3ce0, mload(0x4c0))
            mstore(0x3d00, mload(0x4e0))
            mstore(0x3d20, mload(0x2f40))
            success := and(eq(staticcall(gas(), 0x7, 0x3ce0, 0x60, 0x3ce0, 0x40), 1), success)
            mstore(0x3d40, mload(0x3c60))
            mstore(0x3d60, mload(0x3c80))
            mstore(0x3d80, mload(0x3ce0))
            mstore(0x3da0, mload(0x3d00))
            success := and(eq(staticcall(gas(), 0x6, 0x3d40, 0x80, 0x3d40, 0x40), 1), success)
            mstore(0x3dc0, mload(0x500))
            mstore(0x3de0, mload(0x520))
            mstore(0x3e00, mload(0x2f60))
            success := and(eq(staticcall(gas(), 0x7, 0x3dc0, 0x60, 0x3dc0, 0x40), 1), success)
            mstore(0x3e20, mload(0x3d40))
            mstore(0x3e40, mload(0x3d60))
            mstore(0x3e60, mload(0x3dc0))
            mstore(0x3e80, mload(0x3de0))
            success := and(eq(staticcall(gas(), 0x6, 0x3e20, 0x80, 0x3e20, 0x40), 1), success)
            mstore(0x3ea0, mload(0x420))
            mstore(0x3ec0, mload(0x440))
            mstore(0x3ee0, mload(0x2f80))
            success := and(eq(staticcall(gas(), 0x7, 0x3ea0, 0x60, 0x3ea0, 0x40), 1), success)
            mstore(0x3f00, mload(0x3e20))
            mstore(0x3f20, mload(0x3e40))
            mstore(0x3f40, mload(0x3ea0))
            mstore(0x3f60, mload(0x3ec0))
            success := and(eq(staticcall(gas(), 0x6, 0x3f00, 0x80, 0x3f00, 0x40), 1), success)
            mstore(0x3f80, mload(0x2e0))
            mstore(0x3fa0, mload(0x300))
            mstore(0x3fc0, mload(0x3240))
            success := and(eq(staticcall(gas(), 0x7, 0x3f80, 0x60, 0x3f80, 0x40), 1), success)
            mstore(0x3fe0, mload(0x3f00))
            mstore(0x4000, mload(0x3f20))
            mstore(0x4020, mload(0x3f80))
            mstore(0x4040, mload(0x3fa0))
            success := and(eq(staticcall(gas(), 0x6, 0x3fe0, 0x80, 0x3fe0, 0x40), 1), success)
            mstore(0x4060, mload(0x320))
            mstore(0x4080, mload(0x340))
            mstore(0x40a0, mload(0x3260))
            success := and(eq(staticcall(gas(), 0x7, 0x4060, 0x60, 0x4060, 0x40), 1), success)
            mstore(0x40c0, mload(0x3fe0))
            mstore(0x40e0, mload(0x4000))
            mstore(0x4100, mload(0x4060))
            mstore(0x4120, mload(0x4080))
            success := and(eq(staticcall(gas(), 0x6, 0x40c0, 0x80, 0x40c0, 0x40), 1), success)
            mstore(0x4140, mload(0x360))
            mstore(0x4160, mload(0x380))
            mstore(0x4180, mload(0x3280))
            success := and(eq(staticcall(gas(), 0x7, 0x4140, 0x60, 0x4140, 0x40), 1), success)
            mstore(0x41a0, mload(0x40c0))
            mstore(0x41c0, mload(0x40e0))
            mstore(0x41e0, mload(0x4140))
            mstore(0x4200, mload(0x4160))
            success := and(eq(staticcall(gas(), 0x6, 0x41a0, 0x80, 0x41a0, 0x40), 1), success)
            mstore(0x4220, mload(0x3a0))
            mstore(0x4240, mload(0x3c0))
            mstore(0x4260, mload(0x32a0))
            success := and(eq(staticcall(gas(), 0x7, 0x4220, 0x60, 0x4220, 0x40), 1), success)
            mstore(0x4280, mload(0x41a0))
            mstore(0x42a0, mload(0x41c0))
            mstore(0x42c0, mload(0x4220))
            mstore(0x42e0, mload(0x4240))
            success := and(eq(staticcall(gas(), 0x6, 0x4280, 0x80, 0x4280, 0x40), 1), success)
            mstore(0x4300, mload(0x3e0))
            mstore(0x4320, mload(0x400))
            mstore(0x4340, mload(0x33a0))
            success := and(eq(staticcall(gas(), 0x7, 0x4300, 0x60, 0x4300, 0x40), 1), success)
            mstore(0x4360, mload(0x4280))
            mstore(0x4380, mload(0x42a0))
            mstore(0x43a0, mload(0x4300))
            mstore(0x43c0, mload(0x4320))
            success := and(eq(staticcall(gas(), 0x6, 0x4360, 0x80, 0x4360, 0x40), 1), success)
            mstore(0x43e0, mload(0x980))
            mstore(0x4400, mload(0x9a0))
            mstore(0x4420, sub(f_q, mload(0x33e0)))
            success := and(eq(staticcall(gas(), 0x7, 0x43e0, 0x60, 0x43e0, 0x40), 1), success)
            mstore(0x4440, mload(0x4360))
            mstore(0x4460, mload(0x4380))
            mstore(0x4480, mload(0x43e0))
            mstore(0x44a0, mload(0x4400))
            success := and(eq(staticcall(gas(), 0x6, 0x4440, 0x80, 0x4440, 0x40), 1), success)
            mstore(0x44c0, mload(0xa20))
            mstore(0x44e0, mload(0xa40))
            mstore(0x4500, mload(0x3400))
            success := and(eq(staticcall(gas(), 0x7, 0x44c0, 0x60, 0x44c0, 0x40), 1), success)
            mstore(0x4520, mload(0x4440))
            mstore(0x4540, mload(0x4460))
            mstore(0x4560, mload(0x44c0))
            mstore(0x4580, mload(0x44e0))
            success := and(eq(staticcall(gas(), 0x6, 0x4520, 0x80, 0x4520, 0x40), 1), success)
            mstore(0x45a0, mload(0x4520))
            mstore(0x45c0, mload(0x4540))
            mstore(0x45e0, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)
            mstore(0x4600, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)
            mstore(0x4620, 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b)
            mstore(0x4640, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)
            mstore(0x4660, mload(0xa20))
            mstore(0x4680, mload(0xa40))
            mstore(0x46a0, 0x0181624e80f3d6ae28df7e01eaeab1c0e919877a3b8a6b7fbc69a6817d596ea2)
            mstore(0x46c0, 0x1783d30dcb12d259bb89098addf6280fa4b653be7a152542a28f7b926e27e648)
            mstore(0x46e0, 0x00ae44489d41a0d179e2dfdc03bddd883b7109f8b6ae316a59e815c1a6b35304)
            mstore(0x4700, 0x0b2147ab62a386bd63e6de1522109b8c9588ab466f5aadfde8c41ca3749423ee)
            success := and(eq(staticcall(gas(), 0x8, 0x45a0, 0x180, 0x45a0, 0x20), 1), success)
            success := and(eq(mload(0x45a0), 1), success)

            // Revert if anything fails
            if iszero(success) {
                revert(0, 0)
            }

            // Return empty bytes on success
            return(0, 0)
        }
    }

    /// @notice Verify a proof with given public inputs
    /// @param proof The proof bytes
    /// @param instances The public inputs (uint256 array)
    /// @return True if proof is valid
    function verify(bytes calldata proof, uint256[] calldata instances) external view returns (bool) {
        // Encode proof + instances and call fallback
        bytes memory input = abi.encodePacked(proof);
        for (uint256 i = 0; i < instances.length; i++) {
            input = abi.encodePacked(input, instances[i]);
        }

        (bool success,) = address(this).staticcall(input);
        return success;
    }
}
