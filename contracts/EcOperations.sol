pragma solidity ^0.4.24;

contract EcOperations {

  // number of generator points in the matrix of precomputed generator points
  uint256 private numGenerators = 0;
  // precomputedState[...generator number...]
  uint256[257] private precomputedState;
  // precomputedGenerators[x, y, z][...scalar value...][...generator number...] <- reverse order when reading
  uint256[3][257][16] private precomputedGenerators;

  uint256 public constant GROUP_ORDER = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
  uint256 public constant PP = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
  //uint256 constant a = 0;
  //uint256 constant b = 3;

  function makeAffine(uint256 ax, uint256 ay, uint256 az) public view returns(uint256[3] p) {
    if (az == 1) {
      return;
    }
    if (az == 0) {
      assembly {
        mstore(p, 0)
        mstore(add(p, 0x20), 1)
        mstore(add(p, 0x40), 0)
      }
      return;
    }
    uint256 z_inv = expMod(az, PP-2, PP); // find inverse using Fermat's little theorem, since PP is prime
    // recovers x and y from Jacobian form (X, Y, Z) given that x = X/Z^2 and y = Y/Z^3
    assembly {
      let P := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
      let zz_inv := mulmod(z_inv, z_inv, P)
      let zzz_inv := mulmod(z_inv, zz_inv, P)
      mstore(p, mulmod(ax, zz_inv, P))
      mstore(add(p, 0x20), mulmod(ay, zzz_inv, P))
      mstore(add(p, 0x40), 0x01)
    }
  }

  function isOnCurve(uint256 ax, uint256 ay, uint256 az) public pure returns(bool output) {
    if (az == 0) {
      return true;
    }
    assembly {
      let P := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
      let b := 3
      let z2 := mulmod(az, az, P)
      let z6 := mulmod(z2, mulmod(z2, z2, P), P)
      let x3 := mulmod(ax, mulmod(ax, ax, P), P)
      x3 := addmod(x3, mulmod(b, z6, P), P) // scale b with z6 in order to avoid an inversion
      let y2 := mulmod(ay, ay, P)
      output := eq(y2, x3)
    }
  }

  function ecNeg(uint256 ax, uint256 ay, uint256 az) public pure returns(uint256[3] p) {
    assembly {
      let P := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
      mstore(p, ax)
      mstore(add(p, 0x20), sub(P, ay))
      mstore(add(p, 0x40), az)
    }
  }

  function addPersistentGenerator() public {
    uint256 offset = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256[3] memory p = hashToPoint(offset + numGenerators);
    precomputedGenerators[numGenerators][1] = p;
    precomputedState[numGenerators] = 1;
    numGenerators = numGenerators + 1;
  }

  function addPersistentGeneratorValues(uint256 generatorNumber, uint256 numberOfValues) public {
    uint256 prevNumberCalculated = precomputedState[generatorNumber];
    uint256[3] memory basePoint = precomputedGenerators[generatorNumber][1];
    uint256[3] memory lastPoint = precomputedGenerators[generatorNumber][prevNumberCalculated];
    for (uint256 i = 0; i < numberOfValues; i++) {
      lastPoint = ecAdd(lastPoint[0], lastPoint[1], 1, basePoint[0], basePoint[1], 1);
      lastPoint = makeAffine(lastPoint[0], lastPoint[1], lastPoint[2]);
      prevNumberCalculated = prevNumberCalculated + 1;
      precomputedGenerators[generatorNumber][prevNumberCalculated] = lastPoint;
      precomputedState[generatorNumber] = prevNumberCalculated;
    }
  }

  function getPersistentGeneratorValue(uint256 generatorNumber, uint256 scalarValue) public view returns(uint256[3] p) {
    p = precomputedGenerators[generatorNumber][scalarValue];
  }

  // hash to point, use to generate random EC points without the private keys being known
  // Should ideally be something like this: https://www.di.ens.fr/~fouque/pub/latincrypt12.pdf
  // but using try and increment method for now: https://www.normalesup.org/~tibouchi/papers/bnhash-scis.pdf
  // NOTE: Susceptible to timing attacks (not an issue if input data is publicly known)
  function hashToPoint(uint256 input) public view returns(uint256[3] p) {
    /*
      Static memory map:
      0x0200: exponent base length
      0x0220: exponent length
      0x0240: modulus length
      0x0260: base
      0x0280: exponent
      0x02A0: modulus
      0x02C0: px / tmp for first uint256 of hash input
      0x02E0: py / tmp for second uint256 of hash input
      0x0300: pz
    */
    assembly {

      let P := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
      let b := 3
      mstore(p, input)

      // do try and increment at most 128 times
      for { let i := 0 } lt(i, 128) { } {
        mstore(add(p, 0x20), i)
        let x := mod(keccak256(p, 0x40), P)
        let rhs := addmod(mulmod(x, mulmod(x, x, P), P), b, P)
        mstore(0x0260, rhs)
        sqrtMod()
        let y := mload(0x02E0)
        switch y
        // y == 0 if sqrt(x^3 + b) is either 0 or a quadratic non-residue modulo P
        case 0 {
          i := add(i, 1)
          // if failed to get valid point on curve, return inf
          if eq(i, 128) {
            setInf()
          }
        }
        default {
          i := 128
          mstore(0x02C0, x)
          mstore(0x0300, 1)
        }
      }

      mstore(p, mload(0x02C0))
      mstore(add(p, 0x20), mload(0x02E0))
      mstore(add(p, 0x40), mload(0x0300))

      function setInf() {
        mstore(0x02C0, 0)
        mstore(0x02E0, 1)
        mstore(0x0300, 0)
      }

      /*
        1) Since P is prime, the Legendre symbol (a/P) indicates whether a number is
          a quadratic residue or not (Euler's criterion):
            If (a/P) = a^((P-1)/2) = 1, then a is a quadratic residue modulo P,
            if (a/P) = -1, then a is a quadratic non-residue modulo P,
            if (a/P) = 0, then a = 0 mod P.
        2) Since P mod 4 = 3, if (a/P) = 1, then the square root of a mod P can be found using:
            sqrt(a) = +-a^((P-1)/4)
        3) If a is a quadratic residue modulo P, then this function returns +sqrt(a), otherwise 0.
      */
      function sqrtMod() {
        // Precomputed constants
        let Ps := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        let PMinusOneDivTwo := 0x183227397098D014DC2822DB40C0AC2ECBC0B548B438E5469E10460B6C3E7EA3
        let PPlusOneDivFour := 0xC19139CB84C680A6E14116DA060561765E05AA45A1C72A34F082305B61F3F52
        mstore(0x0200, 0x20)                 // Length of Base
        mstore(0x0220, 0x20)                // Length of Exponent
        mstore(0x0240, 0x20)                // Length of Modulus
        mstore(0x0280, PMinusOneDivTwo)      // Exponent
        mstore(0x02A0, Ps)                   // Modulus
        if iszero(staticcall(sub(gas, 2000), 0x05, 0x0200, 0xc0, 0x02E0, 0x20)) {
          revert(0, 0)
        }
        switch mload(0x02E0)
        case 1 { // a is a quadratic residue
          mstore(0x0280, PPlusOneDivFour)      // Exponent
          if iszero(staticcall(sub(gas, 2000), 0x05, 0x0200, 0xc0, 0x02E0, 0x20)) {
            revert(0, 0)
          }
        }
        default { // a is 0 or a quadratic non-residue
          mstore(0x02E0, 0)
        }
      }
    }
  }

  function ecMultiScalarMult(uint256[] scalars) public view returns(uint256[3] p) {
    assembly {
      /*
        Static memory map:

        ecAdd
        0x0200: ax
        0x0220: ay
        0x0240: az
        0x0260: bx
        0x0280: by
        0x02A0: bz
        0x02C0: px
        0x02E0: py
        0x0300: pz

        ecMultiScalarMult
        0x0400: pointer to numGenerators
        0x0420: pointer to precomputedState
        0x0440: size of precomputedState
        0x0460: pointer to precomputedGenerators
        0x0480: size of point
        0x04A0: size of point set
      */
      mstore(0x0400, 0)
      mstore(0x0420, 1)
      mstore(0x0440, 257)
      mstore(0x0460, add(mload(0x0420), mload(0x0440)))
      mstore(0x0480, 3)
      mstore(0x04A0, mul(mload(0x0480), 257))

      let mask := 0xFF00000000000000000000000000000000000000000000000000000000000000
      let q := exp(2, 248)

      let generatorEnd := add(mload(0x0460), mul(mload(scalars), mload(0x04A0)))
      let scalarEnd := add(scalars, mul(mload(scalars), 0x20))
      // add to point a
      for { } gt(scalarEnd, scalars) { } {
        generatorEnd := sub(generatorEnd, mload(0x04A0))
        // load scalar and extract the 8 MSBs from it
        let idxPx := add(
          generatorEnd,
          mul(div(and(mload(scalarEnd), mask), q), mload(0x0480))
        )
        scalarEnd := sub(scalarEnd, 0x20)
        // load corresponding generator point into b
        mstore(0x0260, sload(idxPx))
        mstore(0x0280, sload(add(idxPx, 1)))
        mstore(0x02A0, gt(mload(0x0260), 0))
        switch mload(0x0240)
        case 0 { // if point a is inf
          setB()
        }
        default {
          if gt(mload(0x02A0), 0) {
            // assume point b is affine, use faster algorithm
            // load result back into a
            // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian/addition/madd-2008-g.op3
            let azs := mload(0x0240)
            let Ps := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            //T1 = Z1^2
            let tmp1s := mulmod(azs, azs, Ps)
            //T2 = T1*Z1
            let tmp2s := mulmod(tmp1s, azs, Ps)
            //T1 = T1*X2
            tmp1s := mulmod(tmp1s, mload(0x0260), Ps)
            //T2 = T2*Y2
            tmp2s := mulmod(tmp2s, mload(0x0280), Ps)
            //T1 = X1-T1
            tmp1s := addmod(mload(0x0200), sub(Ps, tmp1s), Ps)
            //T2 = T2-Y1
            tmp2s := add(tmp2s, sub(Ps, mload(0x0220)))
            switch tmp1s
            case 0 {
              tmp2s := mod(tmp2s, Ps)
              if iszero(tmp2s) { // if points are co-located, do double instead
                // same as dbl, except that result is loaded back into a
                // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
                let Pd := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let axd := mload(0x0200)
                let ayd := mload(0x0220)
                //A = X1^2
                let tmp1d := mulmod(axd, axd, Pd)
                //B = Y1^2
                let tmp2d := mulmod(ayd, ayd, Pd)
                //C = B^2
                let tmp3d := mulmod(tmp2d, tmp2d, Pd)
                //t0 = X1+B
                let tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
                //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
                tmp2d := mulmod(
                  0x02,
                  add(mulmod(tmp4d, tmp4d, Pd), sub(add(Pd, Pd), add(tmp1d, tmp3d))),
                  Pd
                )
                //E = 3*A
                tmp1d := mul(0x03, tmp1d)
                //F = E^2
                tmp4d := mulmod(tmp1d, tmp1d, Pd)
                //X3 = F-2*D, X3 -> p + 0x00
                mstore(
                  0x0200,
                  addmod(
                    tmp4d,
                    sub(add(Pd, Pd), add(tmp2d, tmp2d)),
                    Pd
                  )
                )
                //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
                mstore(
                  0x0220,
                  addmod(
                    mulmod(tmp1d, add(tmp2d, sub(Pd, mload(0x0200))), Pd),
                    sub(Pd, mulmod(0x08, tmp3d, Pd)),
                    Pd
                  )
                )
                //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
                mstore(
                  0x0240,
                  mulmod(
                    0x02,
                    mulmod(ayd, mload(0x0240), Pd),
                    Pd
                  )
                )
              }
              if gt(tmp2s, 0) {//return inf
                setInf()
              }
            }
            default {
              //Z3 = Z1*T1
              mstore(0x0240, mulmod(azs, tmp1s, Ps))
              //T4 = T1^2
              let tmp4s := mulmod(tmp1s, tmp1s, Ps)
              //T1 = T1*T4
              tmp1s := mulmod(tmp1s, tmp4s, Ps)
              //T4 = T4*X1
              tmp4s := mulmod(tmp4s, mload(0x0200), Ps)
              //X3 = T2^2
              let pxs := mulmod(tmp2s, tmp2s, Ps)
              //X3 = X3+T1
              pxs := add(pxs, tmp1s)
              //Y3 = T1*Y1
              mstore(0x0220, mulmod(tmp1s, mload(0x0220), Ps))
              //T1 = 2*T4
              tmp1s := add(tmp4s, tmp4s)
              //X3 = X3-T1
              mstore(0x0200, addmod(pxs, sub(0x60C89CE5C263405370A08B6D0302B0BB2F02D522D0E3951A7841182DB0F9FA8E, tmp1s), Ps)) //constant is 2*P
              //T4 = X3-T4
              tmp4s := add(mload(0x0200), sub(Ps, tmp4s))
              //T4 = T4*T2
              tmp4s := mulmod(tmp4s, tmp2s, Ps)
              //Y3 = T4-Y3
              mstore(0x0220, addmod(tmp4s, sub(Ps, mload(0x0220)), Ps))
            }
          }
        }
      }
      for { let i := 31} gt(i, 0) { i := sub(i, 1) } {
        // shift 8 bits to the right
        mask := div(mask, 256)
        q := div(q, 256)
        // double point a 8 times (x256)
        if gt(mload(0x0240), 0) {
          let Pd := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
          let PdTwo := add(Pd, Pd)
          let axd := mload(0x0200)
          let ayd := mload(0x0220)
          let azd := mload(0x0240)
          // same as dbl, except that result is loaded back into a
          // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
          //A = X1^2
          let tmp1d := mulmod(axd, axd, Pd)
          //B = Y1^2
          let tmp2d := mulmod(ayd, ayd, Pd)
          //C = B^2
          let tmp3d := mulmod(tmp2d, tmp2d, Pd)
          //t0 = X1+B
          let tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
          //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
          tmp2d := mulmod(
            0x02,
            add(mulmod(tmp4d, tmp4d, Pd), sub(PdTwo, add(tmp1d, tmp3d))),
            Pd
          )
          //E = 3*A
          tmp1d := mul(0x03, tmp1d)
          //F = E^2
          //tmp4d := mulmod(tmp1d, tmp1d, Pd)
          //X3 = F-2*D, X3 -> p + 0x00
          axd := addmod(
            mulmod(tmp1d, tmp1d, Pd),
            sub(PdTwo, add(tmp2d, tmp2d)),
            Pd
          )
          //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
          ayd := addmod(
            mulmod(tmp1d, add(tmp2d, sub(Pd, axd)), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)),
            Pd
          )
          //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
          azd := mulmod(
            0x02,
            mulmod(ayd, azd, Pd),
            Pd
          )
          // same as dbl, except that result is loaded back into a
          // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
          //A = X1^2
          tmp1d := mulmod(axd, axd, Pd)
          //B = Y1^2
          tmp2d := mulmod(ayd, ayd, Pd)
          //C = B^2
          tmp3d := mulmod(tmp2d, tmp2d, Pd)
          //t0 = X1+B
          tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
          //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
          tmp2d := mulmod(
            0x02,
            add(mulmod(tmp4d, tmp4d, Pd), sub(PdTwo, add(tmp1d, tmp3d))),
            Pd
          )
          //E = 3*A
          tmp1d := mul(0x03, tmp1d)
          //F = E^2
          //tmp4d := mulmod(tmp1d, tmp1d, Pd)
          //X3 = F-2*D, X3 -> p + 0x00
          axd := addmod(
            mulmod(tmp1d, tmp1d, Pd),
            sub(PdTwo, add(tmp2d, tmp2d)),
            Pd
          )
          //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
          ayd := addmod(
            mulmod(tmp1d, add(tmp2d, sub(Pd, axd)), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)),
            Pd
          )
          //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
          azd := mulmod(
            0x02,
            mulmod(ayd, azd, Pd),
            Pd
          )
          // same as dbl, except that result is loaded back into a
          // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
          //A = X1^2
          tmp1d := mulmod(axd, axd, Pd)
          //B = Y1^2
          tmp2d := mulmod(ayd, ayd, Pd)
          //C = B^2
          tmp3d := mulmod(tmp2d, tmp2d, Pd)
          //t0 = X1+B
          tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
          //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
          tmp2d := mulmod(
            0x02,
            add(mulmod(tmp4d, tmp4d, Pd), sub(PdTwo, add(tmp1d, tmp3d))),
            Pd
          )
          //E = 3*A
          tmp1d := mul(0x03, tmp1d)
          //F = E^2
          //tmp4d := mulmod(tmp1d, tmp1d, Pd)
          //X3 = F-2*D, X3 -> p + 0x00
          axd := addmod(
            mulmod(tmp1d, tmp1d, Pd),
            sub(PdTwo, add(tmp2d, tmp2d)),
            Pd
          )
          //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
          ayd := addmod(
            mulmod(tmp1d, add(tmp2d, sub(Pd, axd)), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)),
            Pd
          )
          //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
          azd := mulmod(
            0x02,
            mulmod(ayd, azd, Pd),
            Pd
          )
          // same as dbl, except that result is loaded back into a
          // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
          //A = X1^2
          tmp1d := mulmod(axd, axd, Pd)
          //B = Y1^2
          tmp2d := mulmod(ayd, ayd, Pd)
          //C = B^2
          tmp3d := mulmod(tmp2d, tmp2d, Pd)
          //t0 = X1+B
          tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
          //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
          tmp2d := mulmod(
            0x02,
            add(mulmod(tmp4d, tmp4d, Pd), sub(PdTwo, add(tmp1d, tmp3d))),
            Pd
          )
          //E = 3*A
          tmp1d := mul(0x03, tmp1d)
          //F = E^2
          //tmp4d := mulmod(tmp1d, tmp1d, Pd)
          //X3 = F-2*D, X3 -> p + 0x00
          axd := addmod(
            mulmod(tmp1d, tmp1d, Pd),
            sub(PdTwo, add(tmp2d, tmp2d)),
            Pd
          )
          //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
          ayd := addmod(
            mulmod(tmp1d, add(tmp2d, sub(Pd, axd)), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)),
            Pd
          )
          //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
          azd := mulmod(
            0x02,
            mulmod(ayd, azd, Pd),
            Pd
          )
          // same as dbl, except that result is loaded back into a
          // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
          //A = X1^2
          tmp1d := mulmod(axd, axd, Pd)
          //B = Y1^2
          tmp2d := mulmod(ayd, ayd, Pd)
          //C = B^2
          tmp3d := mulmod(tmp2d, tmp2d, Pd)
          //t0 = X1+B
          tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
          //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
          tmp2d := mulmod(
            0x02,
            add(mulmod(tmp4d, tmp4d, Pd), sub(PdTwo, add(tmp1d, tmp3d))),
            Pd
          )
          //E = 3*A
          tmp1d := mul(0x03, tmp1d)
          //F = E^2
          //tmp4d := mulmod(tmp1d, tmp1d, Pd)
          //X3 = F-2*D, X3 -> p + 0x00
          axd := addmod(
            mulmod(tmp1d, tmp1d, Pd),
            sub(PdTwo, add(tmp2d, tmp2d)),
            Pd
          )
          //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
          ayd := addmod(
            mulmod(tmp1d, add(tmp2d, sub(Pd, axd)), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)),
            Pd
          )
          //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
          azd := mulmod(
            0x02,
            mulmod(ayd, azd, Pd),
            Pd
          )
          // same as dbl, except that result is loaded back into a
          // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
          //A = X1^2
          tmp1d := mulmod(axd, axd, Pd)
          //B = Y1^2
          tmp2d := mulmod(ayd, ayd, Pd)
          //C = B^2
          tmp3d := mulmod(tmp2d, tmp2d, Pd)
          //t0 = X1+B
          tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
          //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
          tmp2d := mulmod(
            0x02,
            add(mulmod(tmp4d, tmp4d, Pd), sub(PdTwo, add(tmp1d, tmp3d))),
            Pd
          )
          //E = 3*A
          tmp1d := mul(0x03, tmp1d)
          //F = E^2
          //tmp4d := mulmod(tmp1d, tmp1d, Pd)
          //X3 = F-2*D, X3 -> p + 0x00
          axd := addmod(
            mulmod(tmp1d, tmp1d, Pd),
            sub(PdTwo, add(tmp2d, tmp2d)),
            Pd
          )
          //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
          ayd := addmod(
            mulmod(tmp1d, add(tmp2d, sub(Pd, axd)), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)),
            Pd
          )
          //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
          azd := mulmod(
            0x02,
            mulmod(ayd, azd, Pd),
            Pd
          )
          // same as dbl, except that result is loaded back into a
          // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
          //A = X1^2
          tmp1d := mulmod(axd, axd, Pd)
          //B = Y1^2
          tmp2d := mulmod(ayd, ayd, Pd)
          //C = B^2
          tmp3d := mulmod(tmp2d, tmp2d, Pd)
          //t0 = X1+B
          tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
          //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
          tmp2d := mulmod(
            0x02,
            add(mulmod(tmp4d, tmp4d, Pd), sub(PdTwo, add(tmp1d, tmp3d))),
            Pd
          )
          //E = 3*A
          tmp1d := mul(0x03, tmp1d)
          //F = E^2
          //tmp4d := mulmod(tmp1d, tmp1d, Pd)
          //X3 = F-2*D, X3 -> p + 0x00
          axd := addmod(
            mulmod(tmp1d, tmp1d, Pd),
            sub(PdTwo, add(tmp2d, tmp2d)),
            Pd
          )
          //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
          ayd := addmod(
            mulmod(tmp1d, add(tmp2d, sub(Pd, axd)), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)),
            Pd
          )
          //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
          azd := mulmod(
            0x02,
            mulmod(ayd, azd, Pd),
            Pd
          )
          // same as dbl, except that result is loaded back into a
          // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
          //A = X1^2
          tmp1d := mulmod(axd, axd, Pd)
          //B = Y1^2
          tmp2d := mulmod(ayd, ayd, Pd)
          //C = B^2
          tmp3d := mulmod(tmp2d, tmp2d, Pd)
          //t0 = X1+B
          tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
          //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
          tmp2d := mulmod(
            0x02,
            add(mulmod(tmp4d, tmp4d, Pd), sub(PdTwo, add(tmp1d, tmp3d))),
            Pd
          )
          //E = 3*A
          tmp1d := mul(0x03, tmp1d)
          //F = E^2
          //tmp4d := mulmod(tmp1d, tmp1d, Pd)
          //X3 = F-2*D, X3 -> p + 0x00
          axd := addmod(
            mulmod(tmp1d, tmp1d, Pd),
            sub(PdTwo, add(tmp2d, tmp2d)),
            Pd
          )
          //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
          ayd := addmod(
            mulmod(tmp1d, add(tmp2d, sub(Pd, axd)), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)),
            Pd
          )
          //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
          azd := mulmod(
            0x02,
            mulmod(ayd, azd, Pd),
            Pd
          )
          // load final result back into a
          mstore(0x0200, axd)
          mstore(0x0220, ayd)
          mstore(0x0240, azd)
        }

        let Ps := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        let axs := mload(0x0200)
        let ays := mload(0x0220)
        let azs := mload(0x0240)

        generatorEnd := add(mload(0x0460), mul(mload(scalars), mload(0x04A0)))
        scalarEnd := add(scalars, mul(mload(scalars), 0x20))
        // add to point a
        for { } gt(scalarEnd, scalars) { } {
          generatorEnd := sub(generatorEnd, mload(0x04A0))
          // load scalar, extract the 8 MSBs from it, and load corresponding generator point into b
          let idxPx := add(
            generatorEnd,
            mul(div(and(mload(scalarEnd), mask), q), mload(0x0480))
          )
          scalarEnd := sub(scalarEnd, 0x20)
          // load into b
          mstore(0x0260, sload(idxPx))
          mstore(0x0280, sload(add(idxPx, 1)))
          mstore(0x02A0, gt(mload(0x0260), 0))
          switch azs
          case 0 { // if point a is inf
            axs := mload(0x0260)
            ays := mload(0x0280)
            azs := mload(0x02A0)
          }
          default {
            if gt(mload(0x02A0), 0) {
              // assume point b is affine, use faster algorithm
              // load result back into a
              // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian/addition/madd-2008-g.op3
              //T1 = Z1^2
              let tmp1s := mulmod(azs, azs, Ps)
              //T2 = T1*Z1
              //let tmp2s := mulmod(tmp1s, azs, Ps)
              //T2 = T2*Y2
              //let tmp2s := mulmod(mulmod(tmp1s, azs, Ps), mload(0x0280), Ps)
              //T1 = T1*X2
              //tmp1s := mulmod(tmp1s, mload(0x0260), Ps)
              //T2 = T2-Y1
              let tmp2s := add(mulmod(mulmod(tmp1s, azs, Ps), mload(0x0280), Ps), sub(Ps, ays))
              //T1 = X1-T1
              tmp1s := addmod(axs, sub(Ps, mulmod(tmp1s, mload(0x0260), Ps)), Ps)
              switch tmp1s
              case 0 {
                tmp2s := mod(tmp2s, Ps)
                if iszero(tmp2s) { // if points are co-located, do double instead
                  // load result back into a
                  mstore(0x0200, axs)
                  mstore(0x0220, ays)
                  mstore(0x0240, azs)
                  // same as dbl, except that result is loaded back into a
                  // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
                  let Pd := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                  let axd := mload(0x0200)
                  let ayd := mload(0x0220)
                  //A = X1^2
                  let tmp1d := mulmod(axd, axd, Pd)
                  //B = Y1^2
                  let tmp2d := mulmod(ayd, ayd, Pd)
                  //C = B^2
                  let tmp3d := mulmod(tmp2d, tmp2d, Pd)
                  //t0 = X1+B
                  let tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
                  //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
                  tmp2d := mulmod(
                    0x02,
                    add(mulmod(tmp4d, tmp4d, Pd), sub(0x60C89CE5C263405370A08B6D0302B0BB2F02D522D0E3951A7841182DB0F9FA8E, add(tmp1d, tmp3d))), //constant is 2*P
                    Pd
                  )
                  //E = 3*A
                  tmp1d := mul(0x03, tmp1d)
                  //F = E^2
                  tmp4d := mulmod(tmp1d, tmp1d, Pd)
                  //X3 = F-2*D, X3 -> p + 0x00
                  mstore(
                    0x0200,
                    addmod(
                      tmp4d,
                      sub(add(Pd, Pd), add(tmp2d, tmp2d)),
                      Pd
                    )
                  )
                  //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
                  mstore(
                    0x0220,
                    addmod(
                      mulmod(tmp1d, add(tmp2d, sub(Pd, mload(0x0200))), Pd),
                      sub(Pd, mulmod(0x08, tmp3d, Pd)),
                      Pd
                    )
                  )
                  //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
                  mstore(
                    0x0240,
                    mulmod(
                      0x02,
                      mulmod(ayd, mload(0x0240), Pd),
                      Pd
                    )
                  )
                  // load result back into vars
                  axs := mload(0x0200)
                  ays := mload(0x0220)
                  azs := mload(0x0240)
                }
                if gt(tmp2s, 0) {//return inf
                  setInf()
                }
              }
              default {
                //Z3 = Z1*T1
                azs := mulmod(azs, tmp1s, Ps)
                //T4 = T1^2
                let tmp4s := mulmod(tmp1s, tmp1s, Ps)
                //T1 = T1*T4
                tmp1s := mulmod(tmp1s, tmp4s, Ps)
                //T4 = T4*X1
                tmp4s := mulmod(tmp4s, axs, Ps)
                //X3 = T2^2
                //let pxs := mulmod(tmp2s, tmp2s, Ps)
                //X3 = X3+T1
                //let pxs := add(mulmod(tmp2s, tmp2s, Ps), tmp1s)
                //Y3 = T1*Y1
                //ays := mulmod(tmp1s, ays, Ps)
                //T1 = 2*T4
                //tmp1s := add(tmp4s, tmp4s)
                //X3 = X3-T1
                axs := addmod(add(mulmod(tmp2s, tmp2s, Ps), tmp1s), sub(0x60C89CE5C263405370A08B6D0302B0BB2F02D522D0E3951A7841182DB0F9FA8E, add(tmp4s, tmp4s)), Ps) // constant is 2*P
                //T4 = X3-T4
                //tmp4s := add(axs, sub(Ps, tmp4s))
                //T4 = T4*T2
                //tmp4s := mulmod(add(axs, sub(Ps, tmp4s)), tmp2s, Ps)
                //Y3 = T4-Y3
                ays := addmod(mulmod(add(axs, sub(Ps, tmp4s)), tmp2s, Ps), sub(Ps, mulmod(tmp1s, ays, Ps)), Ps)
              }
            }
          }
        }
        // load result back into a
        mstore(0x0200, axs)
        mstore(0x0220, ays)
        mstore(0x0240, azs)
      }
      //load final result into p
      mstore(p, mload(0x0200))
      mstore(add(p, 0x20), mload(0x0220))
      mstore(add(p, 0x40), mload(0x0240))

      function setB() {
        mstore(0x0200, mload(0x0260))
        mstore(0x0220, mload(0x0280))
        mstore(0x0240, mload(0x02A0))
      }

      function setInf() {
        mstore(0x0200, 0)
        mstore(0x0220, 1)
        mstore(0x0240, 0)
      }
    }
    //p = makeAffine(p[0], p[1], p[2]);
  }

  function ecDbl(uint256 ax, uint256 ay, uint256 az) public pure returns(uint256[3] p) {
    /*
      Static memory map:
      0x0200: ax
      0x0220: ay
      0x0240: az
    */
    assembly {
      mstore(0x0200, ax)
      mstore(0x0220, ay)
      mstore(0x0240, az)

      if iszero(az) { // if point a is inf
        setInf()
      }
      if gt(az, 0) {
        dbl()
      }

      mstore(p, mload(0x0200))
      mstore(add(p, 0x20), mload(0x0220))
      mstore(add(p, 0x40), mload(0x0240))

      function setInf() {
        mstore(0x0200, 0)
        mstore(0x0220, 1)
        mstore(0x0240, 0)
      }

      // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
      function dbl() {
        let Pd := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        let axd := mload(0x0200)
        let ayd := mload(0x0220)
        //A = X1^2
        let tmp1d := mulmod(axd, axd, Pd)
        //B = Y1^2
        let tmp2d := mulmod(ayd, ayd, Pd)
        //C = B^2
        let tmp3d := mulmod(tmp2d, tmp2d, Pd)
        //t0 = X1+B
        let tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
        //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
        tmp2d := mulmod(
          0x02,
          add(mulmod(tmp4d, tmp4d, Pd), sub(add(Pd, Pd), add(tmp1d, tmp3d))),
          Pd
        )
        //E = 3*A
        tmp1d := mul(0x03, tmp1d)
        //F = E^2
        tmp4d := mulmod(tmp1d, tmp1d, Pd)
        //X3 = F-2*D, X3 -> p + 0x00
        mstore(
          0x0200,
          addmod(
            tmp4d,
            sub(add(Pd, Pd), add(tmp2d, tmp2d)),
            Pd
          )
        )
        //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
        mstore(
          0x0220,
          addmod(
            mulmod(tmp1d, add(tmp2d, sub(Pd, mload(0x0200))), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)),
            Pd
          )
        )
        //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
        mstore(
          0x0240,
          mulmod(
            0x02,
            mulmod(ayd, mload(0x0240), Pd),
            Pd
          )
        )
      }
    }
    //p = makeAffine(p[0], p[1], p[2]);
  }

  function ecAdd(uint256 ax, uint256 ay, uint256 az, uint256 bx, uint256 by, uint256 bz) public view returns(uint256[3] p) {
    /*
      Static memory map:
      0x0200: ax
      0x0220: ay
      0x0240: az
      0x0260: bx
      0x0280: by
      0x02A0: bz
      0x02C0: px
      0x02E0: py
      0x0300: pz
    */
    assembly {
      mstore(0x0200, ax)
      mstore(0x0220, ay)
      mstore(0x0240, az)
      mstore(0x0260, bx)
      mstore(0x0280, by)
      mstore(0x02A0, bz)

      if iszero(az) { // if point a is inf
        setB()
      }
      if gt(az, 0) {
        switch bz
        case 0 {// if point b is inf
          setA()
        }
        case 1 {// if point b is affine, use faster algorithm
          addSpcl()
        }
        default {
          addNrml()
        }
      }
      mstore(p, mload(0x02C0))
      mstore(add(p, 0x20), mload(0x02E0))
      mstore(add(p, 0x40), mload(0x0300))

      function setA() {
        mstore(0x02C0, mload(0x0200))
        mstore(0x02E0, mload(0x0220))
        mstore(0x0300, mload(0x0240))
      }

      function setB() {
        mstore(0x02C0, mload(0x0260))
        mstore(0x02E0, mload(0x0280))
        mstore(0x0300, mload(0x02A0))
      }

      function setInf() {
        mstore(0x02C0, 0)
        mstore(0x02E0, 1)
        mstore(0x0300, 0)
      }

      // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian/addition/madd-2008-g.op3
      function addSpcl() {
        let azs := mload(0x0240)
        let Ps := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        //T1 = Z1^2
        let tmp1s := mulmod(azs, azs, Ps)
        //T2 = T1*Z1
        let tmp2s := mulmod(tmp1s, azs, Ps)
        //T1 = T1*X2
        tmp1s := mulmod(tmp1s, mload(0x0260), Ps)
        //T2 = T2*Y2
        tmp2s := mulmod(tmp2s, mload(0x0280), Ps)
        //T1 = X1-T1
        tmp1s := addmod(mload(0x0200), sub(Ps, tmp1s), Ps)
        //T2 = T2-Y1
        tmp2s := add(tmp2s, sub(Ps, mload(0x0220)))
        if iszero(tmp1s) {
          tmp2s := mod(tmp2s, Ps)
          if iszero(tmp2s) { // if points are co-located, do double instead
            dbl()
          }
          if gt(tmp2s, 0) {//return inf
            setInf()
          }
        }
        if gt(tmp1s, 0) {
          //Z3 = Z1*T1
          mstore(0x0300, mulmod(azs, tmp1s, Ps))
          //T4 = T1^2
          let tmp4s := mulmod(tmp1s, tmp1s, Ps)
          //T1 = T1*T4
          tmp1s := mulmod(tmp1s, tmp4s, Ps)
          //T4 = T4*X1
          tmp4s := mulmod(tmp4s, mload(0x0200), Ps)
          //X3 = T2^2
          let pxs := mulmod(tmp2s, tmp2s, Ps)
          //X3 = X3+T1
          pxs := add(pxs, tmp1s)
          //Y3 = T1*Y1
          mstore(0x02E0, mulmod(tmp1s, mload(0x0220), Ps))
          //T1 = 2*T4
          tmp1s := add(tmp4s, tmp4s)
          //X3 = X3-T1
          mstore(0x02C0, addmod(pxs, sub(add(Ps, Ps), tmp1s), Ps))
          //T4 = X3-T4
          tmp4s := add(mload(0x02C0), sub(Ps, tmp4s))
          //T4 = T4*T2
          tmp4s := mulmod(tmp4s, tmp2s, Ps)
          //Y3 = T4-Y3
          mstore(0x02E0, addmod(tmp4s, sub(Ps, mload(0x02E0)), Ps))
        }
      }

      // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian/addition/add-1998-cmo-2.op3
      function addNrml() {
        let azn := mload(0x0240)
        let bzn := mload(0x02A0)
        let Pn := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        //Z2Z2 = Z2^2
        let tmp1n := mulmod(bzn, bzn, Pn)
        //U1 = X1*Z2Z2
        let tmp2n := mulmod(mload(0x0200), tmp1n, Pn)
        //S1 = Y1*t0 = Y1*Z2*Z2Z2
        let tmp3n := mulmod(mload(0x0220), mulmod(bzn, tmp1n, Pn), Pn)
        //Z1Z1 = Z1^2
        tmp1n := mulmod(azn, azn, Pn)
        //r = S2-S1 = Y2*t1 - S1 = Y2*Z1*Z1Z1 - S1
        let tmp4n := addmod(
          mulmod(mload(0x0280), mulmod(azn, tmp1n, Pn), Pn),
          sub(Pn, tmp3n),
          Pn
        )
        //H = U2-U1 = X2*Z1Z1 - U1
        let tmp5n := add(
          mulmod(mload(0x0260), tmp1n, Pn),
          sub(Pn, tmp2n)
        )
        if iszero(tmp4n) {
          tmp5n := mod(tmp5n, Pn)
          if iszero(tmp5n) {// if the points are co-located, do double instead
            dbl()
          }
        }
        if gt(tmp4n, 0) {
          //HH = H^2, hh offset = 0x0100
          tmp1n := mulmod(tmp5n, tmp5n, Pn)
          //V = U1*HH, v offset = 0x0160
          tmp2n := mulmod(tmp2n, tmp1n, Pn)
          //HHH = H*HH, hhh offset = 0x0120
          tmp1n := mulmod(tmp5n, tmp1n, Pn)
          //Z3 = Z1*t8 = Z1*Z2*H, Z3 -> p + 0x40
          mstore(
            0x0300,
            mulmod(azn, mulmod(bzn, tmp5n, Pn), Pn)
          )
          //X3 = t4-t3 = r^2 - (hhh + 2*V), X3 -> p + 0x00
          mstore(
            0x02C0,
            addmod(
              mulmod(tmp4n, tmp4n, Pn),
              sub(mul(0x03, Pn), add(tmp1n, add(tmp2n, tmp2n))),
              Pn
            )
          )
          //Y3 = t7-t6 = r*(V-X3) - S1*HHH, Y3 -> p + 0x20
          mstore(
            0x02E0,
            addmod(
              mulmod(tmp4n, add(tmp2n, sub(Pn, mload(0x02C0))), Pn),
              sub(Pn, mulmod(tmp3n, tmp1n, Pn)),
              Pn
            )
          )
        }
      }

      // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
      function dbl() {
        let Pd := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        let axd := mload(0x0200)
        let ayd := mload(0x0220)
        //A = X1^2
        let tmp1d := mulmod(axd, axd, Pd)
        //B = Y1^2
        let tmp2d := mulmod(ayd, ayd, Pd)
        //C = B^2
        let tmp3d := mulmod(tmp2d, tmp2d, Pd)
        //t0 = X1+B
        let tmp4d := add(axd, tmp2d) // Since (2^256 - 1)/P ~ 5, we can afford to skip a few mod ops when adding
        //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
        tmp2d := mulmod(
          0x02,
          add(mulmod(tmp4d, tmp4d, Pd), sub(add(Pd, Pd), add(tmp1d, tmp3d))),
          Pd
        )
        //E = 3*A
        tmp1d := mul(0x03, tmp1d)
        //F = E^2
        tmp4d := mulmod(tmp1d, tmp1d, Pd)
        //X3 = F-2*D, X3 -> p + 0x00
        mstore(
          0x02C0,
          addmod(
            tmp4d,
            sub(add(Pd, Pd), add(tmp2d, tmp2d)),
            Pd
          )
        )
        //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
        mstore(
          0x02E0,
          addmod(
            mulmod(tmp1d, add(tmp2d, sub(Pd, mload(0x02C0))), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)),
            Pd
          )
        )
        //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
        mstore(
          0x0300,
          mulmod(
            0x02,
            mulmod(ayd, mload(0x0240), Pd),
            Pd
          )
        )
      }
    }
    //p = makeAffine(p[0], p[1], p[2]);
  }

  function expMod(uint256 base, uint256 e, uint256 m) public view returns (uint256 o) {
    assembly {
      let p := mload(0x40)
      mstore(p, 0x20)             // Length of Base
      mstore(add(p, 0x20), 0x20)  // Length of Exponent
      mstore(add(p, 0x40), 0x20)  // Length of Modulus
      mstore(add(p, 0x60), base)  // Base
      mstore(add(p, 0x80), e)     // Exponent
      mstore(add(p, 0xa0), m)     // Modulus
      if iszero(staticcall(sub(gas, 2000), 0x05, p, 0xc0, p, 0x20)) {
        revert(0, 0)
      }
      o := mload(p)
    }
  }
}
